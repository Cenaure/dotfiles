import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

import qs.components
import qs.configurations

// The status-notifier tray, on the same track as the workspace widget so the
// two read as parts of one bar rather than as separate things.
//
// The items are other applications' menus, so the interactions are theirs:
// left click activates, middle click is the secondary action, right click opens
// the item's own D-Bus menu, and the wheel is forwarded as a scroll --- which is
// what volume applets and the like expect.
Item {
  id: root

  // Passive items are ones the application says are not worth showing right
  // now. Hiding them is what keeps the tray from filling with idle icons.
  readonly property var items: {
    const all = SystemTray.items?.values ?? [];

    if (BarConfig.trayShowPassive)
      return all;

    return all.filter(item => item.status !== Status.Passive);
  }

  // An empty tray takes no room at all, rather than leaving an empty track
  // floating in the bar.
  visible: root.items.length > 0

  implicitWidth: root.visible
    ? row.implicitWidth + BarConfig.workspacesTrackPadding * 2
    : 0
  implicitHeight: BarConfig.workspaceHeight + BarConfig.workspacesTrackPadding * 2

  Rectangle {
    anchors.fill: parent

    radius: height / 2
    color: BarConfig.workspacesTrackColor
    opacity: BarConfig.workspacesTrackOpacity
  }

  // ------------------------------------------------------------------ menu --

  // One popup for the whole tray, pointed at whichever slot was clicked. The
  // menu contents belong to the application, so all that is kept here is which
  // item's menu is showing and what to hang it under.
  property var menuItem: null
  property Item menuAnchor: null

  function openMenuFor(item, anchor) {
    if (!item?.hasMenu)
      return;

    // Clicking the same icon again puts the menu away, the way pressing a
    // button that opened something is expected to close it.
    if (root.menuItem === item && menu.expanded) {
      menu.close();
      return;
    }

    root.menuItem = item;
    root.menuAnchor = anchor;
    menu.open();
  }

  BarPopup {
    id: menu

    anchorItem: root.menuAnchor
    popupNamespace: "quickshell:trayMenu"

    MenuList {
      handle: root.menuItem?.menu ?? null

      onTriggered: menu.close()
    }
  }

  Row {
    id: row

    anchors.centerIn: parent
    spacing: BarConfig.trayIconSpacing

    Repeater {
      model: root.items

      delegate: Item {
        id: entry

        required property var modelData

        width: BarConfig.trayIconSize + BarConfig.trayIconPadding * 2
        height: width

        // The whole slot lifts under the pointer, not just the icon, so the
        // hit target and the thing that reacts to it are the same shape.
        Rectangle {
          anchors.fill: parent

          radius: height / 2
          color: BarConfig.workspaceActiveColor
          opacity: pointer.containsMouse ? BarConfig.trayHoverOpacity : 0

          Behavior on opacity {
            NumberAnimation {
              duration: BarConfig.workspacesAnimationDuration
            }
          }
        }

        IconImage {
          anchors.centerIn: parent

          implicitSize: BarConfig.trayIconSize
          source: entry.modelData.icon
          // Something asking for attention should be hard to ignore, so it
          // keeps full strength while everything else sits back a little.
          opacity: entry.modelData.status === Status.NeedsAttention
            || pointer.containsMouse
            ? 1
            : BarConfig.trayIconOpacity

          Behavior on opacity {
            NumberAnimation {
              duration: BarConfig.workspacesAnimationDuration
            }
          }
        }

        MouseArea {
          id: pointer

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

          onClicked: mouse => {
            const item = entry.modelData;

            if (mouse.button === Qt.MiddleButton) {
              item.secondaryActivate();
              return;
            }

            // Some items have no activate action at all and are only ever a
            // menu; for those a left click has to open it, or the icon does
            // nothing whatsoever.
            if (mouse.button === Qt.RightButton || item.onlyMenu) {
              entry.openMenu();
              return;
            }

            item.activate();
          }

          onWheel: wheel => {
            const item = entry.modelData;

            if (wheel.angleDelta.y !== 0)
              item.scroll(wheel.angleDelta.y, false);

            if (wheel.angleDelta.x !== 0)
              item.scroll(wheel.angleDelta.x, true);
          }
        }

        function openMenu() {
          root.openMenuFor(entry.modelData, entry);
        }
      }
    }
  }
}
