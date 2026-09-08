pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.components
import qs.configurations
import qs.services as Services

// One device in the mixer: what it is, how loud it is, and --- when there is
// more than one to choose from --- which one it should be.
//
// The device list is folded away behind the name, since picking a different
// output is a much rarer thing to want than moving the slider.
Column {
  id: root

  property string label: ""
  property string icon: ""
  property var node: null
  property var devices: []

  signal selected(var device)
  signal muteToggled
  signal levelChanged(real level)

  readonly property bool muted: root.node?.audio?.muted ?? false
  readonly property bool expandable: root.devices.length > 1

  property bool expanded: false

  spacing: AudioConfig.rowSpacing

  Text {
    text: root.label
    color: AudioConfig.sectionLabelColor
    font.family: AudioConfig.fontFamily
    font.pixelSize: AudioConfig.sectionLabelSize
    font.weight: 700
  }

  // -------------------------------------------------------------- current --

  Item {
    width: parent.width
    height: name.implicitHeight

    IconButton {
      id: mute

      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter

      implicitWidth: AudioConfig.muteButtonSize
      implicitHeight: AudioConfig.muteButtonSize

      icon: root.icon
      iconSize: AudioConfig.muteIconSize
      fontFamily: AudioConfig.iconFontFamily
      iconColor: root.muted ? AudioConfig.detailColor : AudioConfig.nameColor
      hoverIconColor: AudioConfig.sliderFillColor

      onActivated: root.muteToggled()
    }

    Text {
      id: name

      anchors.left: mute.right
      anchors.leftMargin: AudioConfig.rowSpacing
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter

      text: Services.Audio.labelOf(root.node)
      color: AudioConfig.nameColor
      font.family: AudioConfig.fontFamily
      font.pixelSize: AudioConfig.nameSize
      elide: Text.ElideRight
    }

    MouseArea {
      anchors.left: name.left
      anchors.right: parent.right
      anchors.top: parent.top
      anchors.bottom: parent.bottom

      enabled: root.expandable
      cursorShape: Qt.PointingHandCursor

      onClicked: root.expanded = !root.expanded
    }
  }

  LevelSlider {
    width: parent.width

    value: root.node?.audio?.volume ?? 0
    enabled: !root.muted

    onMoved: level => root.levelChanged(level)
  }

  // --------------------------------------------------------------- picker --

  Column {
    width: parent.width
    spacing: 0

    visible: root.expanded && root.expandable

    Repeater {
      model: root.devices

      delegate: Rectangle {
        id: device

        required property var modelData

        readonly property bool current: device.modelData === root.node

        width: root.width
        height: AudioConfig.rowHeight
        radius: AudioConfig.rowRadius

        color: devicePointer.containsMouse
          ? BarConfig.popupRowHoverColor
          : "transparent"

        Behavior on color {
          ColorAnimation {
            duration: BarConfig.popupAnimationDuration / 2
          }
        }

        Text {
          anchors.left: parent.left
          anchors.leftMargin: AudioConfig.rowPadding
          anchors.right: parent.right
          anchors.rightMargin: AudioConfig.rowPadding
          anchors.verticalCenter: parent.verticalCenter

          text: Services.Audio.labelOf(device.modelData)
          color: device.current
            ? AudioConfig.sliderFillColor
            : AudioConfig.detailColor
          font.family: AudioConfig.fontFamily
          font.pixelSize: AudioConfig.detailSize
          font.weight: device.current ? 700 : 400
          elide: Text.ElideRight
        }

        MouseArea {
          id: devicePointer

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onClicked: {
            root.selected(device.modelData);
            root.expanded = false;
          }
        }
      }
    }
  }
}
