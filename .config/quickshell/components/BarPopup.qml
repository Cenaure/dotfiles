import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.configurations

// A panel that drops out of a bar widget: a tray item's menu, the network list.
//
// Built as a full-screen overlay with the card positioned under its anchor,
// rather than as a real popup surface, because that is what makes clicking away
// dismiss it --- the surface has to be there to catch the click.
//
// Keyboard focus is off by default. A menu does not need it, and taking it
// exclusively is what makes Hyprland restore focus (and the workspace) when the
// grab ends. Anything that does need typing --- the wifi password field --- sets
// takesFocus, which asks for focus on demand rather than grabbing it.
Scope {
  id: root

  // The bar widget this hangs from. Its position on screen is where the card
  // is placed, so it must be an item in a mapped window.
  property Item anchorItem: null
  property int gap: BarConfig.popupGap
  property bool takesFocus: false
  property string popupNamespace: "quickshell:barPopup"

  property bool expanded: false

  default property alias content: container.data

  signal dismissed

  function open() {
    root.expanded = true;
  }

  function close() {
    root.expanded = false;
  }

  function toggle() {
    root.expanded = !root.expanded;
  }

  // ------------------------------------------------------------ internals --

  // Held open past the collapse so the card can fade out rather than vanish.
  property bool windowVisible: false

  // Bumped on every open. The anchor's position on screen is fetched with a
  // function call rather than read from a notifying property, so nothing would
  // otherwise tell the binding to look again --- and the bar's widgets do move
  // as tray items and the battery come and go.
  property int repositionTick: 0

  onExpandedChanged: {
    if (root.expanded) {
      root.repositionTick++;
      hideDelay.stop();
      root.windowVisible = true;
    } else {
      hideDelay.restart();
      root.dismissed();
    }
  }

  Timer {
    id: hideDelay

    interval: BarConfig.popupAnimationDuration + 60
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

    // The surface has to cover the bar too, or a click on the bar would not
    // reach the dismiss handler below.
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: root.popupNamespace
    WlrLayershell.keyboardFocus: root.takesFocus && root.expanded
      ? WlrKeyboardFocus.OnDemand
      : WlrKeyboardFocus.None

    MouseArea {
      anchors.fill: parent

      onClicked: root.close()
    }

    Rectangle {
      id: card

      // Where the anchor sits on screen. The overlay is a full-screen layer
      // surface pinned at the origin, so global coordinates are its own.
      readonly property point anchorOrigin: {
        root.repositionTick;

        return root.anchorItem
          ? root.anchorItem.mapToGlobal(0, 0)
          : Qt.point(0, 0);
      }

      // Centred under the widget, then pulled back inside the screen if that
      // would hang it off an edge --- which it would for anything near the
      // right end of the bar.
      x: {
        if (!root.anchorItem)
          return 0;

        const centred = card.anchorOrigin.x
          + (root.anchorItem.width - card.width) / 2;

        return Math.max(BarConfig.popupScreenMargin,
          Math.min(overlay.width - card.width - BarConfig.popupScreenMargin,
            centred));
      }

      y: root.anchorItem
        ? card.anchorOrigin.y + root.anchorItem.height + root.gap
        : 0

      implicitWidth: container.implicitWidth + BarConfig.popupPadding * 2
      implicitHeight: container.implicitHeight + BarConfig.popupPadding * 2
      width: implicitWidth
      height: implicitHeight

      radius: BarConfig.popupRadius
      color: BarConfig.popupColor

      // Rises the last few pixels into place as it fades in, which reads as
      // dropping out of the widget rather than appearing on top of it.
      opacity: root.expanded ? 1 : 0
      transform: Translate {
        y: root.expanded ? 0 : -BarConfig.popupRiseDistance

        Behavior on y {
          NumberAnimation {
            duration: BarConfig.popupAnimationDuration
            easing.type: Easing.OutQuint
          }
        }
      }

      Behavior on opacity {
        NumberAnimation {
          duration: BarConfig.popupAnimationDuration
          easing.type: Easing.OutCubic
        }
      }

      // Clicks on the card itself are not clicks away from it.
      MouseArea {
        anchors.fill: parent
      }

      // Sized by its contents rather than by the card, because the card is
      // sized by it --- anchoring this to the card as well would close the
      // loop. Content sets its own width.
      Item {
        id: container

        x: BarConfig.popupPadding
        y: BarConfig.popupPadding

        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        width: container.implicitWidth
        height: container.implicitHeight
      }
    }
  }
}
