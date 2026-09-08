import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import Quickshell.Widgets

import qs.components
import qs.configurations
import qs.services as Services

// One notification, drawn the same way whether it is a popup on the right of
// the screen or a row in the centre. The only difference between the two is
// `showAge`: a popup has just arrived, so saying when would be noise.
//
// Clicking the card runs the sender's default action where there is one, which
// is the "click the notification to open the thing it is about" gesture.
Rectangle {
  id: root

  property var notification: null
  property bool showAge: false

  // Buttons the sender offered, minus the invisible default one, which belongs
  // to the card itself rather than in the row of buttons.
  readonly property var visibleActions: {
    const actions = root.notification?.actions ?? [];

    return actions.filter(action => action.identifier !== "default");
  }

  readonly property var defaultAction: {
    const actions = root.notification?.actions ?? [];

    return actions.find(action => action.identifier === "default") ?? null;
  }

  // A key for the app behind the notification, in the same shape as the window
  // classes BarConfig.appIcons is keyed by.
  readonly property string sourceKey: {
    const notification = root.notification;

    if (!notification)
      return "";

    return (notification.desktopEntry || notification.appName || "").toLowerCase();
  }

  readonly property color accentColor: {
    switch (root.notification?.urgency) {
    case NotificationUrgency.Critical:
      return NotificationsConfig.accentCritical;
    case NotificationUrgency.Low:
      return NotificationsConfig.accentLow;
    default:
      return NotificationsConfig.accentNormal;
    }
  }

  implicitHeight: layout.implicitHeight + NotificationsConfig.cardPadding * 2
  radius: NotificationsConfig.cardRadius
  color: NotificationsConfig.cardColor

  // Urgency down the leading edge. Inset top and bottom so it reads as a mark
  // on the card rather than as a border of it.
  Rectangle {
    id: accent

    anchors.left: parent.left
    anchors.leftMargin: NotificationsConfig.cardPadding
    anchors.verticalCenter: parent.verticalCenter

    width: NotificationsConfig.accentWidth
    height: Math.max(0, parent.height - NotificationsConfig.accentInset * 2)
    radius: width / 2
    color: root.accentColor
  }

  // Behind the contents, so the buttons and the close control get the clicks
  // aimed at them and everything else falls through to the default action.
  MouseArea {
    anchors.fill: parent
    enabled: root.defaultAction !== null
    cursorShape: Qt.PointingHandCursor

    onClicked: Services.Notifications.invoke(root.notification, root.defaultAction)
  }

  RowLayout {
    id: layout

    anchors.left: accent.right
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.leftMargin: NotificationsConfig.cardSpacing
    anchors.rightMargin: NotificationsConfig.cardPadding
    anchors.topMargin: NotificationsConfig.cardPadding

    spacing: NotificationsConfig.cardSpacing

    // ------------------------------------------------------------- icon --

    Rectangle {
      Layout.preferredWidth: NotificationsConfig.iconSize
      Layout.preferredHeight: NotificationsConfig.iconSize
      Layout.alignment: Qt.AlignTop

      radius: NotificationsConfig.iconRadius
      color: NotificationsConfig.iconPlaceholderColor

      // The sender's own image where it sent one --- an album cover, an avatar
      // --- and its desktop icon otherwise.
      IconImage {
        id: icon

        anchors.fill: parent
        anchors.margins: root.notification?.image ? 0 : 6

        source: {
          const notification = root.notification;

          if (!notification)
            return "";

          if (notification.image)
            return notification.image;

          return notification.appIcon ? Quickshell.iconPath(notification.appIcon, true) : "";
        }

        visible: icon.source !== ""
      }

      // Senders that provide neither, which is common for scripts, and for
      // anything whose icon name the theme cannot resolve --- icon lookup
      // depends on XDG_DATA_DIRS, which is not reliably set in this session.
      // The bar's own glyph map answers instead, so a notification from an app
      // gets the same icon its window has.
      AppIcon {
        anchors.centerIn: parent

        visible: !icon.visible
        windowClass: root.sourceKey
        font.pixelSize: NotificationsConfig.iconGlyphSize
        color: NotificationsConfig.appNameColor
      }
    }

    // ------------------------------------------------------------- text --

    ColumnLayout {
      Layout.fillWidth: true

      spacing: NotificationsConfig.textSpacing

      RowLayout {
        Layout.fillWidth: true

        spacing: NotificationsConfig.actionSpacing

        Text {
          Layout.fillWidth: true

          text: root.notification?.appName || "Notification"
          color: NotificationsConfig.appNameColor
          font.family: NotificationsConfig.fontFamily
          font.pixelSize: NotificationsConfig.appNameSize
          font.weight: 700
          elide: Text.ElideRight
        }

        Text {
          visible: root.showAge && text !== ""
          text: Services.Notifications.ageOf(root.notification)
          color: NotificationsConfig.ageColor
          font.family: NotificationsConfig.fontFamily
          font.pixelSize: NotificationsConfig.appNameSize
        }

        IconButton {
          implicitWidth: NotificationsConfig.closeButtonSize
          implicitHeight: NotificationsConfig.closeButtonSize

          icon: NotificationsConfig.closeIcon
          iconSize: NotificationsConfig.closeIconSize
          fontFamily: NotificationsConfig.iconFontFamily
          iconColor: NotificationsConfig.closeColor
          hoverIconColor: NotificationsConfig.closeHoverColor
          animationDuration: NotificationsConfig.hoverAnimationDuration

          onActivated: Services.Notifications.dismiss(root.notification)
        }
      }

      Text {
        Layout.fillWidth: true

        visible: text !== ""
        text: root.notification?.summary ?? ""
        color: NotificationsConfig.summaryColor
        font.family: NotificationsConfig.fontFamily
        font.pixelSize: NotificationsConfig.summarySize
        font.weight: 700
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
      }

      Text {
        Layout.fillWidth: true

        visible: text !== ""
        text: root.notification?.body ?? ""
        color: NotificationsConfig.bodyColor
        font.family: NotificationsConfig.fontFamily
        font.pixelSize: NotificationsConfig.bodySize
        // The server advertises body markup, so senders may use the small set
        // of tags the spec allows; StyledText is what renders those, and it
        // leaves plain bodies alone.
        textFormat: Text.StyledText
        wrapMode: Text.WordWrap
        maximumLineCount: NotificationsConfig.bodyMaxLines
        elide: Text.ElideRight
      }
    }
  }
}
