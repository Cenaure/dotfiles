import QtQuick
import QtQuick.Layouts

import qs.services as Services

Rectangle {
  id: root

  property string icon: ""
  property string label: ""
  property color iconColor: Services.Theme.foreground
  property int maxLabelWidth: 400
  property int verticalPadding: 5

  implicitWidth: row.implicitWidth + 22
  implicitHeight: row.implicitHeight + root.verticalPadding * 2
  radius: height / 2
  color: Services.Theme.surface

  RowLayout {
    id: row
    anchors.centerIn: parent
    spacing: root.icon ? 7 : 0

    Text {
      text: root.icon
      color: root.iconColor
      font.family: "Material Symbols Outlined"
      font.pixelSize: 16
      visible: root.icon != ""
    }

    Text {
      text: root.label
      color: Services.Theme.foreground
      font.family: "AnnotationM Nerd Font"
      font.weight: 700
      font.pixelSize: 14
      elide: Text.ElideRight
      Layout.maximumWidth: root.maxLabelWidth
      visible: root.label != ""
    }
  }
}
