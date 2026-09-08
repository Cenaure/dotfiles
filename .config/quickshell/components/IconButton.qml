import QtQuick

// A round icon button: a glyph that lights up under the pointer, optionally on
// a filled disc. Used for the notification close and header controls.
Item {
  id: root

  property string icon: ""
  property real iconSize: 14
  property string fontFamily: "Material Symbols Outlined"

  property color iconColor: "#ffffff"
  property color hoverIconColor: root.iconColor
  property color backgroundColor: "transparent"
  property color hoverBackgroundColor: root.backgroundColor

  property int animationDuration: 140
  // Set to keep the button reserved but inert, without it moving anything.
  property real disabledOpacity: 0.3

  signal activated

  implicitWidth: 20
  implicitHeight: root.implicitWidth

  opacity: root.enabled ? 1 : root.disabledOpacity

  Rectangle {
    anchors.fill: parent
    radius: width / 2

    color: hover.containsMouse && root.enabled ? root.hoverBackgroundColor : root.backgroundColor

    Behavior on color {
      ColorAnimation {
        duration: root.animationDuration
      }
    }
  }

  Text {
    anchors.centerIn: parent

    text: root.icon
    font.family: root.fontFamily
    font.pixelSize: root.iconSize

    color: hover.containsMouse && root.enabled ? root.hoverIconColor : root.iconColor

    Behavior on color {
      ColorAnimation {
        duration: root.animationDuration
      }
    }
  }

  scale: hover.pressed && root.enabled ? 0.88 : 1

  Behavior on scale {
    NumberAnimation {
      duration: root.animationDuration
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
