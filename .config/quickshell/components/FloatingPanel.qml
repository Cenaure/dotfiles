import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.services as Services
import qs.configurations

// A widget that expands into a menu. There is only ever one rounded
// rectangle: it begins exactly on top of the widget it belongs to --- same
// position, size and corner radius --- and grows into the panel, so the widget
// appears to become the menu rather than spawn one.
//
// Generic on purpose; any bar widget can own one:
//
//     FloatingPanel {
//         id: panel
//         anchorWidth: 184        // geometry of the widget it grows from
//         anchorHeight: 32
//         onKeyPressed: event => { ... }
//
//         Column { ... }
//     }
//
// With growUp it is anchored to the bottom of the screen instead of the bar and
// unfolds upward out of a pill, for surfaces that do not belong to a bar widget
// (the app launcher):
//
//     FloatingPanel {
//         growUp: true
//         anchorMargin: 90        // gap above the bottom screen edge
//     }
//
// slideIn swaps the morph for a plain translation: the panel keeps its full
// size throughout and travels in from past the edge it is anchored to. Use it
// where there is no widget to grow out of, so there is nothing for a morph to
// hand off from.
//
Scope {
  id: root

  // ------------------------------------------------------------- interface --

  property bool expanded: false

  // Collapsed state: the widget in the bar this panel grows out of.
  property real anchorWidth: 184
  property real anchorHeight: 32
  property real anchorRadius: root.anchorHeight / 2
  // Top edge of that widget. The rectangle keeps this edge fixed and grows
  // downward, which is what anchors the expansion to the bar.
  property real anchorY: BarConfig.margin[0] + (BarConfig.height - root.anchorHeight) / 2

  // Flip the whole thing: pin the rectangle's bottom edge anchorMargin above
  // the bottom of the screen and let it grow upward instead. anchorY is unused
  // in this mode.
  property bool growUp: false
  property real anchorMargin: 0

  // Translate instead of morph. The anchor geometry is unused in this mode: the
  // panel is always its full size, parked past the edge while closed.
  property bool slideIn: false

  // Expanded state.
  property real panelWidth: 520
  property real panelRadius: 28
  property real padding: 18

  // The bottom corners can be rounded differently from the top ones, which is
  // what lets a growUp panel sit flush on the screen edge: square below, round
  // above, so it reads as rising out of the edge rather than floating over it.
  property real panelBottomRadius: root.panelRadius
  property real anchorBottomRadius: root.anchorRadius

  property color panelColor: Services.Theme.surface
  property real panelOpacity: 1

  property int duration: 360
  property bool closeOnClickOutside: true

  // An interactive panel owns the screen while it is up: it takes the keyboard
  // and swallows every click, so clicking away dismisses it. That is right for
  // something you opened deliberately, like the launcher.
  //
  // A passive one is just something on screen. It never takes the keyboard, and
  // only the panel itself takes clicks --- everything around it behaves as if
  // the surface were not there. Use it for anything that appears on its own
  // rather than because you asked for it.
  property bool interactive: true
  property string panelNamespace: "quickshell:floatingPanel"

  // Hyprland restores focus to whatever held it when an exclusive keyboard
  // grab began. Change workspace while a panel is open and that restore drags
  // you back to where you opened it, undoing the switch. With this on, the
  // panel remembers where you actually were and puts it back.
  property bool keepWorkspace: true

  signal keyPressed(var event)

  default property alias content: contentItem.data

  function open() {
    root.expanded = true;
  }

  function close() {
    root.expanded = false;
  }

  function toggle() {
    root.expanded = !root.expanded;
  }

  // -------------------------------------------------------------- internals --

  readonly property real panelHeight: Math.max(root.anchorHeight, contentItem.implicitHeight + root.padding * 2)

  property bool windowVisible: false

  onExpandedChanged: {
    if (root.expanded) {
      hideDelay.stop();
      root.windowVisible = true;
    } else {
      hideDelay.restart();
    }

    if (!root.expanded) {
      root.closedOnWorkspace = Hyprland.focusedWorkspace?.id ?? -1;

      if (root.interactive && root.keepWorkspace && root.closedOnWorkspace >= 0)
        workspaceGuard.restart();
    }
  }

  // Where we were when the panel collapsed, which is where we should still be
  // once it is gone.
  property int closedOnWorkspace: -1

  // How long after closing we keep watching for Hyprland's focus restore. It
  // arrives a compositor round trip after the keyboard grab is dropped, so this
  // only has to outlast that --- long enough to catch it, short enough that a
  // workspace switch you make yourself right after closing is your own.
  property int workspaceGuardWindow: 350

  // Armed for that window, and disarmed the moment the restore is corrected.
  readonly property bool guardingWorkspace: workspaceGuard.running

  function keepWorkspacePut() {
    // A passive panel never grabs the keyboard, so there is no focus for
    // Hyprland to restore and nothing to correct.
    if (!root.interactive || !root.keepWorkspace || root.closedOnWorkspace < 0)
      return;

    const current = Hyprland.focusedWorkspace?.id ?? -1;

    if (current < 0 || current === root.closedOnWorkspace)
      return;

    workspaceGuard.stop();

    // A Lua config evaluates the dispatch string as Lua, where the classic
    // "workspace N" form is a syntax error --- the same split the bar's
    // workspace switching has to make.
    Hyprland.dispatch(BarConfig.hyprlandLuaConfig ? `hl.dsp.focus({ workspace = ${root.closedOnWorkspace} })` : `workspace ${root.closedOnWorkspace}`);
  }

  Timer {
    id: hideDelay
    interval: root.duration + 120
    onTriggered: root.windowVisible = false
  }

  // The restore we are undoing is triggered by the keyboard grab being dropped,
  // which happens as soon as the panel collapses --- not when the surface is
  // finally hidden at the end of the close animation. Waiting for the latter is
  // what made the wrong workspace sit on screen for half a second before
  // snapping back. So: arm a short window at collapse and react to the focus
  // change itself, which puts the correction a frame after the mistake instead
  // of after the animation.
  Timer {
    id: workspaceGuard
    interval: root.workspaceGuardWindow
    // A backstop for a restore that arrives later than the window, which is the
    // case the old fixed delay was really covering.
    onTriggered: root.keepWorkspacePut()
  }

  Connections {
    target: Hyprland
    enabled: root.guardingWorkspace

    function onFocusedWorkspaceChanged() {
      root.keepWorkspacePut();
    }
  }

  PanelWindow {
    id: overlay

    visible: root.windowVisible
    color: "transparent"

    anchors {
      top: true
      left: true
      right: true
      bottom: true
    }

    // Without this the bar's exclusive zone shrinks this surface so it starts
    // below the bar, and the rectangle could not sit on top of the widget.
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: root.panelNamespace
    WlrLayershell.keyboardFocus: root.interactive && root.expanded ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Everything outside the panel is cut out of the input region, so the
    // compositor routes those clicks to whatever is underneath. An interactive
    // panel keeps the default region --- the whole surface --- because
    // swallowing outside clicks is how click-to-dismiss works.
    mask: root.interactive ? null : passiveRegion

    Region {
      id: passiveRegion
      item: shell
    }

    FocusScope {
      anchors.fill: parent
      focus: true

      Keys.onPressed: event => {
        root.keyPressed(event);

        if (!event.accepted && event.key === Qt.Key_Escape) {
          root.close();
          event.accepted = true;
        }
      }

      MouseArea {
        anchors.fill: parent
        enabled: root.interactive && root.closeOnClickOutside
        onClicked: root.close()
      }

      Rectangle {
        id: shell

        readonly property bool atFullSize: root.slideIn || root.expanded

        width: shell.atFullSize ? root.panelWidth : root.anchorWidth
        height: shell.atFullSize ? root.panelHeight : root.anchorHeight
        radius: shell.atFullSize ? root.panelRadius : root.anchorRadius
        // Set explicitly, so they override `radius` per corner. With the
        // defaults these equal it and nothing changes.
        bottomLeftRadius: shell.atFullSize ? root.panelBottomRadius : root.anchorBottomRadius
        bottomRightRadius: shell.bottomLeftRadius
        x: (parent.width - width) / 2
        // Growing upward means keeping the bottom edge put, which falls out of
        // subtracting the animating height from a fixed baseline.
        //
        // Deliberately not animated, and deliberately not where a sliding panel
        // parks while closed. This depends on parent.height, which is zero
        // until the compositor has given the surface a size --- so on the first
        // open it changes from a nonsense value to the real one. An animation
        // here would play that correction out on screen as the panel dropping
        // in from the top. The slide lives in the transform below instead,
        // which depends on nothing the compositor has to supply.
        y: root.growUp ? parent.height - root.anchorMargin - height : root.anchorY

        color: root.panelColor
        // Starts fully transparent so the real widget shows through underneath
        // at the moment of opening, then fades in as the rectangle grows over
        // it. That crossfade is what hides the hand-off between the two. A
        // sliding panel has no widget to hand off from and arrives from off
        // screen, so it stays opaque and the movement does all the work.
        opacity: root.slideIn ? root.panelOpacity : (root.expanded ? root.panelOpacity : 0)

        // Keeps the menu contents from spilling out while the rectangle is
        // still smaller than they are.
        clip: true

        Behavior on width {
          enabled: !root.slideIn
          NumberAnimation {
            duration: root.duration
            easing.type: root.expanded ? Easing.OutQuint : Easing.InOutQuad
          }
        }

        Behavior on height {
          enabled: !root.slideIn
          // Height settles a little after width, so it reads as unfolding
          // rather than as a uniform scale.
          NumberAnimation {
            duration: root.duration * 1.1
            easing.type: root.expanded ? Easing.OutQuint : Easing.InOutQuad
          }
        }

        Behavior on radius {
          enabled: !root.slideIn
          NumberAnimation {
            duration: root.duration * 0.8
            easing.type: Easing.OutCubic
          }
        }

        Behavior on bottomLeftRadius {
          enabled: !root.slideIn
          NumberAnimation {
            duration: root.duration * 0.8
            easing.type: Easing.OutCubic
          }
        }

        // The slide itself: an offset off the resting position rather than a
        // second position to animate towards, so the only thing that can move
        // the panel is opening and closing it. Parked, it sits exactly its own
        // height plus its margin below where it will come to rest, which puts
        // it fully past the bottom edge.
        transform: Translate {
          y: root.slideIn && !root.expanded ? shell.height + root.anchorMargin : 0

          Behavior on y {
            enabled: root.slideIn
            NumberAnimation {
              duration: root.duration
              // Decisive on the way in, unhurried on the way out.
              easing.type: root.expanded ? Easing.OutQuint : Easing.InCubic
            }
          }
        }

        Behavior on opacity {
          NumberAnimation {
            duration: root.duration * 0.45
            easing.type: Easing.OutCubic
          }
        }

        MouseArea {
          anchors.fill: parent
        }

        Item {
          id: contentItem

          // Pinned to whichever edge stays still, so the contents do not drift
          // while the rectangle is still resizing.
          anchors {
            left: parent.left
            right: parent.right
            top: root.growUp ? undefined : parent.top
            bottom: root.growUp ? parent.bottom : undefined
            margins: root.padding
          }
          implicitHeight: childrenRect.height

          // Held back until the rectangle has most of its size, otherwise the
          // contents appear crushed inside a shape still growing around them.
          // Nothing to hold back when sliding: the shape never changes size.
          opacity: root.slideIn || root.expanded ? 1 : 0

          Behavior on opacity {
            SequentialAnimation {
              PauseAnimation {
                duration: root.expanded && !root.slideIn ? root.duration * 0.45 : 0
              }
              NumberAnimation {
                duration: root.duration * 0.5
                easing.type: Easing.OutCubic
              }
            }
          }
        }
      }
    }
  }
}
