import QtQuick

import qs.configurations

// One tile in the power menu: a glyph over a label inside a rounded cell that
// lights up when it is the current choice.
//
// Selection is not decided here. The menu owns which tile is current --- so
// that the keyboard and the pointer move the same cursor rather than each
// keeping its own idea of it --- and hands it back down as `selected`. Hovering
// only reports upward.
Item {
  id: root

  property string icon: ""
  property string label: ""
  property bool selected: false

  signal activated
  signal hovered

  implicitWidth: PowerMenuConfig.tileWidth
  implicitHeight: PowerMenuConfig.tileHeight

  Rectangle {
    id: cell

    anchors.fill: parent
    radius: height / 2

    color: PowerMenuConfig.buttonColor

    border.width: root.selected ? PowerMenuConfig.tileBorderWidth : 0
    border.color: PowerMenuConfig.selectedBorderColor
    
    Rectangle {
      anchors.fill: parent
      radius: height / 2
      color: root.selected ? PowerMenuConfig.selectedColor : "transparent"
    }

    Behavior on color {
      ColorAnimation {
        duration: PowerMenuConfig.hoverDuration
      }
    }

    Behavior on border.color {
      ColorAnimation {
        duration: PowerMenuConfig.hoverDuration
      }
    }

    Behavior on opacity {
      NumberAnimation {
        duration: PowerMenuConfig.hoverDuration
      }
    }
  }

  // Outside the cell rather than inside it, so the cell's idle border can be
  // faded down without taking the glyph and label with it.
  Column {
    anchors.centerIn: parent
    spacing: PowerMenuConfig.labelSpacing

    Text {
      anchors.horizontalCenter: parent.horizontalCenter

      text: root.icon
      font.family: PowerMenuConfig.iconFontFamily
      font.pixelSize: PowerMenuConfig.glyphSize
      color: root.selected ? PowerMenuConfig.selectedGlyphColor : PowerMenuConfig.glyphColor

      Behavior on color {
        ColorAnimation {
          duration: PowerMenuConfig.hoverDuration
        }
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter

      text: root.label
      font.family: PowerMenuConfig.fontFamily
      font.pixelSize: PowerMenuConfig.labelSize
      font.weight: 600
      color: root.selected ? PowerMenuConfig.selectedLabelColor : PowerMenuConfig.labelColor

      Behavior on color {
        ColorAnimation {
          duration: PowerMenuConfig.hoverDuration
        }
      }
    }
  }

  scale: pointer.pressed ? 0.94 : 1

  Behavior on scale {
    NumberAnimation {
      duration: PowerMenuConfig.hoverDuration
      easing.type: Easing.OutCubic
    }
  }

  MouseArea {
    id: pointer

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: root.hovered()
    onClicked: root.activated()
  }
}
