import QtQuick

import qs.configurations

// One control in the transport row. The primary one --- play/pause --- is a
// filled capsule; the rest are bare glyphs that pick up the accent on hover.
//
// A control the player does not offer (no next track, nothing to seek to) is
// left in place but dimmed and inert, so the row never changes shape as tracks
// come and go.
Item {
  id: root

  property string icon: ""
  property bool primary: false

  signal activated

  implicitWidth: root.primary ? MediaConfig.primaryButtonSize : MediaConfig.buttonSize
  implicitHeight: root.implicitWidth

  opacity: root.enabled ? 1 : MediaConfig.buttonDisabledOpacity

  Behavior on opacity {
    NumberAnimation {
      duration: MediaConfig.buttonAnimationDuration
      easing.type: Easing.OutCubic
    }
  }

  Rectangle {
    id: capsule

    anchors.fill: parent
    radius: width / 2

    color: root.primary ? MediaConfig.primaryButtonBg : "transparent"
  }

  Text {
    id: glyph

    anchors.centerIn: parent

    text: root.icon
    font.family: MediaConfig.iconFontFamily
    font.pixelSize: root.primary ? MediaConfig.primaryButtonIconSize : MediaConfig.buttonIconSize

    color: {
      if (root.primary)
        return MediaConfig.primaryButtonColor;

      return hover.containsMouse && root.enabled ? MediaConfig.buttonHoverColor : MediaConfig.buttonColor;
    }

    Behavior on color {
      ColorAnimation {
        duration: MediaConfig.buttonAnimationDuration
      }
    }
  }

  // Nudges down on press, which is the only feedback a flat glyph can give.
  scale: hover.pressed && root.enabled ? 0.88 : 1

  Behavior on scale {
    NumberAnimation {
      duration: MediaConfig.buttonAnimationDuration
      easing.type: Easing.OutCubic
    }
  }

  MouseArea {
    id: hover

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onClicked: root.activated()
  }
}
