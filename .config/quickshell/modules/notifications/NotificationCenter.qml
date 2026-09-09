import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

import qs.components
import qs.configurations
import qs.services as Services

// Everything that has been kept, in one panel: the history the popups leave
// behind, plus the two controls that act on all of it at once --- do not
// disturb, and clear.
//
// Opened over IPC from a Hyprland keybind:
//     qs ipc call notificationCenter toggle
//
// Same shape as the app launcher: it slides up out of the bottom edge, so the
// two surfaces you summon deliberately behave the same way.
Scope {
  id: root

  readonly property var notifications: Services.Notifications

  IpcHandler {
    target: "notificationCenter"

    function toggle(): string {
      panel.toggle();
      return panel.expanded ? "opened" : "closed";
    }

    function open(): string {
      panel.open();
      return "opened";
    }

    function close(): string {
      panel.close();
      return "closed";
    }

    function clear(): string {
      root.notifications.clearAll();
      return "cleared";
    }

    // So a keybind can silence popups without opening anything.
    function dnd(): string {
      root.notifications.toggleDoNotDisturb();
      return root.notifications.doNotDisturb ? "on" : "off";
    }
  }

  FloatingPanel {
    id: panel

    growUp: true
    slideIn: true
    anchorMargin: NotificationsConfig.bottomMargin
    anchorWidth: NotificationsConfig.anchorWidth
    anchorHeight: NotificationsConfig.anchorHeight
    panelBottomRadius: NotificationsConfig.panelBottomRadius
    anchorBottomRadius: NotificationsConfig.panelBottomRadius

    panelWidth: NotificationsConfig.panelWidth
    panelRadius: NotificationsConfig.panelRadius
    padding: NotificationsConfig.panelPadding
    panelColor: NotificationsConfig.panelColor
    duration: NotificationsConfig.animationDuration
    panelNamespace: "quickshell:notificationCenter"

    Column {
      id: column

      width: parent.width
      spacing: NotificationsConfig.headerSpacing

      // ----------------------------------------------------------- header --

      RowLayout {
        width: parent.width
        spacing: NotificationsConfig.headerSpacing

        Text {
          Layout.alignment: Qt.AlignVCenter

          text: root.notifications.doNotDisturb ? NotificationsConfig.bellOffIcon : NotificationsConfig.bellIcon
          font.family: NotificationsConfig.iconFontFamily
          font.pixelSize: NotificationsConfig.headerIconSize
          color: NotificationsConfig.headerTitleColor
        }

        Text {
          Layout.alignment: Qt.AlignVCenter

          text: "Notifications"
          color: NotificationsConfig.headerTitleColor
          font.family: NotificationsConfig.fontFamily
          font.pixelSize: NotificationsConfig.headerTitleSize
          font.weight: 700
        }

        Text {
          Layout.alignment: Qt.AlignVCenter
          Layout.fillWidth: true

          visible: root.notifications.count > 0
          text: root.notifications.count
          color: NotificationsConfig.headerCountColor
          font.family: NotificationsConfig.fontFamily
          font.pixelSize: NotificationsConfig.headerCountSize
          font.weight: 700
        }

        // Lit while do not disturb is on, since that is a state you need to be
        // able to see rather than remember.
        IconButton {
          Layout.alignment: Qt.AlignVCenter

          implicitWidth: NotificationsConfig.headerButtonSize
          implicitHeight: NotificationsConfig.headerButtonSize

          icon: NotificationsConfig.bellOffIcon
          iconSize: NotificationsConfig.headerIconSize
          fontFamily: NotificationsConfig.iconFontFamily
          iconColor: root.notifications.doNotDisturb ? NotificationsConfig.accentNormal : NotificationsConfig.closeColor
          hoverIconColor: NotificationsConfig.closeHoverColor
          animationDuration: NotificationsConfig.hoverAnimationDuration

          onActivated: root.notifications.toggleDoNotDisturb()
        }

        IconButton {
          Layout.alignment: Qt.AlignVCenter

          implicitWidth: NotificationsConfig.headerButtonSize
          implicitHeight: NotificationsConfig.headerButtonSize

          enabled: root.notifications.count > 0
          icon: NotificationsConfig.clearAllIcon
          iconSize: NotificationsConfig.headerIconSize
          fontFamily: NotificationsConfig.iconFontFamily
          iconColor: NotificationsConfig.closeColor
          hoverIconColor: NotificationsConfig.closeHoverColor
          animationDuration: NotificationsConfig.hoverAnimationDuration

          onActivated: root.notifications.clearAll()
        }
      }

      // ------------------------------------------------------------ list --

      ListView {
        id: list

        width: parent.width
        // Grows with its contents until it would make the panel too tall, and
        // scrolls from there.
        height: Math.min(list.contentHeight, NotificationsConfig.listMaxHeight)

        visible: list.count > 0
        clip: true
        spacing: NotificationsConfig.listSpacing
        boundsBehavior: Flickable.StopAtBounds

        model: root.notifications.history

        delegate: NotificationCard {
          required property var modelData

          width: list.width
          notification: modelData
          // These are not new, so when they arrived is the useful part.
          showAge: true
        }

        // Rows close up over one that was cleared instead of jumping.
        displaced: Transition {
          NumberAnimation {
            properties: "y"
            duration: NotificationsConfig.popupAnimationDuration
            easing.type: Easing.OutQuint
          }
        }
      }

      // ----------------------------------------------------------- empty --

      Item {
        width: parent.width
        height: NotificationsConfig.emptyHeight

        visible: list.count === 0

        Column {
          anchors.centerIn: parent
          spacing: NotificationsConfig.emptySpacing

          Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: NotificationsConfig.emptyIcon
            font.family: NotificationsConfig.iconFontFamily
            font.pixelSize: NotificationsConfig.emptyIconSize
            color: NotificationsConfig.emptyColor
          }

          Text {
            anchors.horizontalCenter: parent.horizontalCenter

            text: NotificationsConfig.emptyText
            color: NotificationsConfig.emptyColor
            font.family: NotificationsConfig.fontFamily
            font.pixelSize: NotificationsConfig.emptyTextSize
          }
        }
      }
    }
  }
}
