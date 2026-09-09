import QtQuick

import qs.configurations

// One reading: what it is, how much of it is in use, and the detail underneath.
// The bar turns as it fills past the warning threshold, so a loaded machine
// says so without the number having to be read.
Item {
  id: root

  property string icon: ""
  property string label: ""
  // 0..1, which drives the bar.
  property real value: 0
  // Shown large above the bar. Passed in rather than derived from `value`, so
  // the caller decides how its own reading should read.
  property string valueText: ""
  // Optional second reading, set small beside the big one and sharing its
  // baseline --- a temperature next to a load percentage, say.
  property string valueSuffix: ""
  property color valueSuffixColor: SystemStatsConfig.valueSuffixColor
  property string detail: ""

  implicitHeight: column.implicitHeight

  Column {
    id: column

    width: parent.width
    spacing: SystemStatsConfig.gaugeTextSpacing

    Row {
      spacing: SystemStatsConfig.labelSpacing

      Text {
        anchors.verticalCenter: parent.verticalCenter

        text: root.icon
        font.family: SystemStatsConfig.iconFontFamily
        font.pixelSize: SystemStatsConfig.labelIconSize
        color: SystemStatsConfig.labelColor
      }

      Text {
        anchors.verticalCenter: parent.verticalCenter

        text: root.label
        color: SystemStatsConfig.labelColor
        font.family: SystemStatsConfig.fontFamily
        font.pixelSize: SystemStatsConfig.labelSize
        font.weight: 700
      }
    }

    Item {
      width: parent.width
      height: value.height

      Text {
        id: value

        anchors.left: parent.left

        text: root.valueText
        color: SystemStatsConfig.valueColor
        font.family: SystemStatsConfig.fontFamily
        font.pixelSize: SystemStatsConfig.valueSize
        font.weight: 700
      }

      Text {
        anchors.left: value.right
        anchors.leftMargin: SystemStatsConfig.valueSuffixSpacing
        anchors.right: parent.right
        // Sat on the percentage's baseline rather than centred on it, so the
        // two read as one line instead of as a number with something floating
        // next to it.
        anchors.baseline: value.baseline

        visible: root.valueSuffix !== ""
        text: root.valueSuffix
        color: root.valueSuffixColor
        font.family: SystemStatsConfig.fontFamily
        font.pixelSize: SystemStatsConfig.valueSuffixSize
        font.weight: 700
        elide: Text.ElideRight

        Behavior on color {
          ColorAnimation {
            duration: SystemStatsConfig.animationDuration
          }
        }
      }
    }

    Item {
      width: parent.width
      height: SystemStatsConfig.barHeight

      Rectangle {
        id: groove

        anchors.fill: parent

        radius: SystemStatsConfig.barRadius
        color: SystemStatsConfig.barTrackColor
        opacity: SystemStatsConfig.barTrackOpacity
      }

      Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        width: groove.width * Math.min(1, Math.max(0, root.value))
        radius: SystemStatsConfig.barRadius

        color: root.value >= SystemStatsConfig.barWarningThreshold
          ? SystemStatsConfig.barWarningColor
          : SystemStatsConfig.barFillColor

        Behavior on width {
          NumberAnimation {
            duration: SystemStatsConfig.animationDuration
            easing.type: Easing.OutCubic
          }
        }

        Behavior on color {
          ColorAnimation {
            duration: SystemStatsConfig.animationDuration
          }
        }
      }
    }

    Text {
      width: parent.width

      visible: root.detail !== ""
      text: root.detail
      color: SystemStatsConfig.detailColor
      font.family: SystemStatsConfig.fontFamily
      font.pixelSize: SystemStatsConfig.detailSize
      elide: Text.ElideRight
    }
  }
}
