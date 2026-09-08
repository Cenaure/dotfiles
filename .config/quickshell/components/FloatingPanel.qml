import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.services as Services
import qs.configurations

// A bar widget that expands into a menu. There is only ever one rounded
// rectangle: it begins exactly on top of the widget it belongs to --- same
// position, size and corner radius --- and grows downward into the panel, so
// the widget appears to become the menu rather than spawn one.
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

  // Expanded state.
  property real panelWidth: 520
  property real panelRadius: 28
  property real padding: 18

  property color panelColor: Services.Theme.surface
  property real panelOpacity: 1

  property int duration: 360
  property bool closeOnClickOutside: true
  property string panelNamespace: "quickshell:floatingPanel"

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

        width: root.expanded ? root.panelWidth : root.anchorWidth
        height: root.expanded ? root.panelHeight : root.anchorHeight
        radius: root.expanded ? root.panelRadius : root.anchorRadius
        x: (parent.width - width) / 2
        y: root.anchorY

        color: root.panelColor
        // Starts fully transparent so the real widget shows through underneath
        // at the moment of opening, then fades in as the rectangle grows over
        // it. That crossfade is what hides the hand-off between the two.
        opacity: root.expanded ? root.panelOpacity : 0

        // Keeps the menu contents from spilling out while the rectangle is
        // still smaller than they are.
        clip: true

        Behavior on width {
          NumberAnimation {
            duration: root.duration
            easing.type: root.expanded ? Easing.OutQuint : Easing.InOutQuad
          }
        }

        Behavior on height {
          // Height settles a little after width, so it reads as unfolding
          // rather than as a uniform scale.
          NumberAnimation {
            duration: root.duration * 1.1
            easing.type: root.expanded ? Easing.OutQuint : Easing.InOutQuad
          }
        }

        Behavior on radius {
          NumberAnimation {
            duration: root.duration * 0.8
            easing.type: Easing.OutCubic
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

          anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: root.padding
          }
          implicitHeight: childrenRect.height

          // Held back until the rectangle has most of its size, otherwise the
          // contents appear crushed inside a shape still growing around them.
          opacity: root.expanded ? 1 : 0

          Behavior on opacity {
            SequentialAnimation {
              PauseAnimation {
                duration: root.expanded ? root.duration * 0.45 : 0
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
