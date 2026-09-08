import QtQuick

import Quickshell
import Quickshell.Wayland

import qs.configurations
import qs.services as Services

// Shows the keyboard layout next to the pointer: the whole cycle with the
// active one lit just after you switch, or a single pill for the current layout
// while you hold Alt.
//
// All of the when and the what lives in Services.KeyboardLayout; this is the
// where and the how.
Scope {
  id: root

  readonly property var layout: Services.KeyboardLayout

  // Outlives osdVisible so the pill can fade out rather than vanish.
  property bool windowVisible: false

  Connections {
    target: root.layout

    function onOsdVisibleChanged() {
      if (root.layout.osdVisible) {
        hideDelay.stop();
        root.windowVisible = true;
      } else {
        hideDelay.restart();
      }
    }
  }

  Timer {
    id: hideDelay
    interval: KeyboardLayoutConfig.fadeDuration + 60
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

    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:keyboardLayout"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // Empty input region: the surface covers the screen, so without this it
    // would swallow every click and pointer event on the desktop.
    mask: Region {}

    Rectangle {
      id: pill

      // Clamped so the pill stays fully on screen no matter which corner the
      // pointer is in.
      x: Math.max(KeyboardLayoutConfig.screenMargin, Math.min(overlay.width - width - KeyboardLayoutConfig.screenMargin, Services.Cursor.x + KeyboardLayoutConfig.cursorOffsetX))
      y: Math.max(KeyboardLayoutConfig.screenMargin, Math.min(overlay.height - height - KeyboardLayoutConfig.screenMargin, Services.Cursor.y + KeyboardLayoutConfig.cursorOffsetY))

      implicitWidth: codes.implicitWidth + KeyboardLayoutConfig.padding * 2
      implicitHeight: codes.implicitHeight + KeyboardLayoutConfig.padding * 2
      radius: height / 2

      // An Alt+Shift switch turns a one-pill peek into the full cycle while the
      // indicator is already on screen, so the width change is animated rather
      // than jumping.
      width: implicitWidth

      Behavior on width {
        NumberAnimation {
          duration: KeyboardLayoutConfig.fadeDuration
          easing.type: Easing.OutCubic
        }
      }

      color: KeyboardLayoutConfig.pillColor
      opacity: root.layout.osdVisible ? 1 : 0

      Behavior on opacity {
        NumberAnimation {
          duration: KeyboardLayoutConfig.fadeDuration
          easing.type: Easing.OutCubic
        }
      }

      Row {
        id: codes

        anchors.centerIn: parent
        spacing: KeyboardLayoutConfig.itemSpacing

        Repeater {
          model: root.layout.osdEntries

          delegate: Rectangle {
            id: entry

            required property var modelData

            readonly property bool active: entry.modelData.active

            implicitWidth: label.implicitWidth + KeyboardLayoutConfig.itemPaddingX * 2
            implicitHeight: label.implicitHeight + KeyboardLayoutConfig.itemPaddingY * 2
            radius: height / 2

            color: entry.active ? KeyboardLayoutConfig.activeColor : "transparent"

            Behavior on color {
              ColorAnimation {
                duration: KeyboardLayoutConfig.fadeDuration
              }
            }

            Text {
              id: label

              anchors.centerIn: parent

              text: entry.modelData.code
              color: entry.active ? KeyboardLayoutConfig.activeTextColor : KeyboardLayoutConfig.inactiveTextColor
              font.family: KeyboardLayoutConfig.fontFamily
              font.pixelSize: KeyboardLayoutConfig.fontSize
              font.weight: 700
            }
          }
        }
      }
    }
  }
}
