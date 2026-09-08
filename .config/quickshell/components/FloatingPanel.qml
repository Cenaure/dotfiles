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
  property real anchorY: BarConfig.margin[0]
    + (BarConfig.height - root.anchorHeight) / 2

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
  property string panelNamespace: "quickshell:floatingPanel"

  // Hyprland runs its own binds before the key ever reaches a client, so an
  // exclusive keyboard grab does not stop SUPER+1 pulling the workspace out
  // from under an open panel. Switching Hyprland into a submap does: every
  // bind in keybinds.lua is submap_universal except the workspace ones, so
  // those are the only thing this suppresses. Set it to "" to opt out.
  property string submap: "panel"

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

  readonly property real panelHeight: Math.max(root.anchorHeight,
    contentItem.implicitHeight + root.padding * 2)

  property bool windowVisible: false

  onExpandedChanged: {
    if (root.expanded) {
      hideDelay.stop();
      root.windowVisible = true;
    } else {
      hideDelay.restart();
    }

    root.enterSubmap(root.expanded ? root.submap : "reset");
  }

  function enterSubmap(name) {
    if (!root.submap)
      return;

    // A Lua config evaluates the dispatch string as Lua, where the classic
    // "submap panel" form is a syntax error --- the same split the bar's
    // workspace switching has to make.
    Hyprland.dispatch(BarConfig.hyprlandLuaConfig
      ? `hl.dsp.submap(${JSON.stringify(name)})`
      : `submap ${name}`);
  }

  Timer {
    id: hideDelay
    interval: root.duration + 120
    onTriggered: root.windowVisible = false
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
    WlrLayershell.keyboardFocus: root.expanded
      ? WlrKeyboardFocus.Exclusive
      : WlrKeyboardFocus.None

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
        enabled: root.closeOnClickOutside
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
        // subtracting the animating height from a fixed baseline. When sliding,
        // the closed position is instead entirely past that edge, so opening is
        // one straight translation into place.
        y: {
          if (!root.growUp)
            return root.anchorY;

          if (root.slideIn && !root.expanded)
            return parent.height;

          return parent.height - root.anchorMargin - height;
        }

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

        Behavior on y {
          enabled: root.slideIn
          NumberAnimation {
            duration: root.duration
            // Decisive on the way in, unhurried on the way out.
            easing.type: root.expanded ? Easing.OutQuint : Easing.InCubic
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
