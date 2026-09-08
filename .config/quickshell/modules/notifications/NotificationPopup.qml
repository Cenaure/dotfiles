import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.configurations
import qs.services as Services

// The stack of notifications currently on screen, hanging under the right end
// of the bar. Newest on top.
//
// Which notifications are in it, and how long each one stays, is
// Services.Notifications' decision; this is only the window and the stacking.
Scope {
  id: root

  readonly property var notifications: Services.Notifications

  PanelWindow {
    id: window

    // No cards, no surface: an empty stack would otherwise sit there as a
    // zero-height window taking up a layer.
    visible: root.notifications.popups.length > 0
    color: "transparent"

    anchors {
      top: true
      right: true
    }

    margins {
      top: BarConfig.margin[0] + BarConfig.height + NotificationsConfig.popupTopGap
      right: BarConfig.margin[1]
    }

    implicitWidth: NotificationsConfig.popupWidth
    implicitHeight: Math.max(1, stack.implicitHeight)

    // The bar already reserves its own strip; this hangs below it and should
    // not push anything else around.
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Only the cards take input. The gaps between them, and the strip beside a
    // short card, belong to whatever is underneath.
    mask: Region {
      item: stack
    }

    // Holding the pointer over the stack holds every countdown in it, so a
    // notification cannot expire out from under a click aimed at its buttons.
    HoverHandler {
      id: hover

      onHoveredChanged: root.notifications.popupsPaused = hover.hovered
    }

    Column {
      id: stack

      width: parent.width
      spacing: NotificationsConfig.popupSpacing

      // Arrives from off the right edge, fading in as it comes.
      add: Transition {
        NumberAnimation {
          property: "opacity"
          from: 0
          to: 1
          duration: NotificationsConfig.popupAnimationDuration
          easing.type: Easing.OutCubic
        }
        NumberAnimation {
          property: "x"
          from: NotificationsConfig.popupSlideDistance
          to: 0
          duration: NotificationsConfig.popupAnimationDuration
          easing.type: Easing.OutQuint
        }
      }

      // Cards below close up rather than jumping when one above them goes.
      move: Transition {
        NumberAnimation {
          properties: "y"
          duration: NotificationsConfig.popupAnimationDuration
          easing.type: Easing.OutQuint
        }
      }

      Repeater {
        model: root.notifications.popups

        delegate: NotificationCard {
          required property var modelData

          width: stack.width
          notification: modelData
        }
      }
    }
  }
}
