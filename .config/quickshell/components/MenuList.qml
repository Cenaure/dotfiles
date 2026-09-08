pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets

import qs.configurations

// Renders a D-Bus menu --- a tray item's own menu --- in the shell's styling
// rather than as a native one.
//
// QsMenuOpener turns a handle into a list of entries, and keeps the menu open
// on the far side for as long as it exists, which is what makes an application
// populate a submenu. Submenus are handled by recursion: an entry with children
// expands another MenuList underneath itself, indented, so the whole tree lives
// in one popup instead of a chain of windows.
Column {
  id: root

  // A QsMenuHandle. The tray item's `menu`, or an entry that has children.
  property var handle: null
  property int depth: 0

  // Raised by the row that was clicked, all the way up to whatever owns the
  // popup, so it can close.
  signal triggered

  width: BarConfig.popupMenuWidth - root.depth * BarConfig.popupMenuIndent

  QsMenuOpener {
    id: opener

    menu: root.handle
  }

  Repeater {
    model: opener.children

    delegate: Item {
      id: row

      required property var modelData

      readonly property bool separator: row.modelData.isSeparator
      readonly property bool expandable: row.modelData.hasChildren
      readonly property bool actionable: !row.separator && row.modelData.enabled

      property bool expanded: false

      width: root.width
      height: row.separator
        ? BarConfig.popupSeparatorHeight
        : BarConfig.popupRowHeight + (row.expanded ? submenu.height : 0)

      // ------------------------------------------------------- separator --

      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: row.separator ? parent.verticalCenter : undefined

        visible: row.separator
        height: 1
        color: BarConfig.popupSeparatorColor
        opacity: 0.4
      }

      // ------------------------------------------------------------- row --

      Rectangle {
        id: rowBackground

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top

        visible: !row.separator
        height: BarConfig.popupRowHeight
        radius: BarConfig.popupRowRadius

        color: pointer.containsMouse && row.actionable
          ? BarConfig.popupRowHoverColor
          : "transparent"

        Behavior on color {
          ColorAnimation {
            duration: BarConfig.popupAnimationDuration / 2
          }
        }

        // A checkbox or radio entry keeps its indicator where the icon would
        // be, so a menu of mixed entries still lines up down one edge.
        Text {
          id: indicator

          anchors.left: parent.left
          anchors.leftMargin: BarConfig.popupRowPadding
          anchors.verticalCenter: parent.verticalCenter

          visible: row.modelData.buttonType !== QsMenuButtonType.None
          text: {
            const checked = row.modelData.checkState !== Qt.Unchecked;

            if (row.modelData.buttonType === QsMenuButtonType.RadioButton)
              return checked
                ? BarConfig.popupRadioOnIcon
                : BarConfig.popupRadioOffIcon;

            return checked
              ? BarConfig.popupCheckOnIcon
              : BarConfig.popupCheckOffIcon;
          }
          font.family: BarConfig.batteryIconFontFamily
          font.pixelSize: BarConfig.popupIconSize
          color: BarConfig.popupTextColor
        }

        IconImage {
          id: entryIcon

          anchors.left: parent.left
          anchors.leftMargin: BarConfig.popupRowPadding
          anchors.verticalCenter: parent.verticalCenter

          visible: !indicator.visible && row.modelData.icon !== ""
          implicitSize: BarConfig.popupIconSize
          source: row.modelData.icon
        }

        Text {
          anchors.left: parent.left
          anchors.leftMargin: indicator.visible || entryIcon.visible
            ? BarConfig.popupRowPadding * 2 + BarConfig.popupIconSize
            : BarConfig.popupRowPadding
          anchors.right: chevron.visible ? chevron.left : parent.right
          anchors.rightMargin: BarConfig.popupRowPadding
          anchors.verticalCenter: parent.verticalCenter

          text: row.modelData.text
          color: BarConfig.popupTextColor
          opacity: row.modelData.enabled ? 1 : BarConfig.popupDisabledOpacity
          font.family: BarConfig.fontFamily
          font.pixelSize: BarConfig.popupTextSize
          elide: Text.ElideRight
        }

        Text {
          id: chevron

          anchors.right: parent.right
          anchors.rightMargin: BarConfig.popupRowPadding
          anchors.verticalCenter: parent.verticalCenter

          visible: row.expandable
          text: BarConfig.popupSubmenuIcon
          rotation: row.expanded ? 90 : 0
          font.family: BarConfig.batteryIconFontFamily
          font.pixelSize: BarConfig.popupIconSize
          color: BarConfig.popupTextColor
          opacity: 0.7

          Behavior on rotation {
            NumberAnimation {
              duration: BarConfig.popupAnimationDuration / 2
              easing.type: Easing.OutCubic
            }
          }
        }

        MouseArea {
          id: pointer

          anchors.fill: parent
          enabled: row.actionable
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onClicked: {
            if (row.expandable) {
              row.expanded = !row.expanded;
              return;
            }

            // Emitting this is how an entry is activated: the backend is
            // listening for it and sends the click on over D-Bus.
            row.modelData.triggered();
            root.triggered();
          }
        }
      }

      // --------------------------------------------------------- submenu --

      // Only built once opened, so an application is not asked to populate
      // every submenu the moment the menu appears.
      //
      // Loaded by file name rather than as an inline MenuList: QML refuses a
      // component that instantiates itself by name, and going through a URL is
      // what defers that to runtime. The properties are therefore set on load
      // instead of bound --- neither of them changes while a submenu is open.
      Loader {
        id: submenu

        anchors.left: parent.left
        anchors.leftMargin: BarConfig.popupMenuIndent
        anchors.top: rowBackground.bottom

        // A Loader takes its size from what it loaded, so the row's own height
        // below follows the submenu without having to reach into it.
        source: row.expanded ? "MenuList.qml" : ""
        visible: row.expanded

        onLoaded: {
          submenu.item.handle = row.modelData;
          submenu.item.depth = root.depth + 1;
        }
      }

      // A trigger anywhere down the tree has to reach whatever owns the popup,
      // so each level passes its child's signal up its own.
      Connections {
        target: submenu.item
        ignoreUnknownSignals: true

        function onTriggered() {
          root.triggered();
        }
      }
    }
  }
}
