import QtQuick

import qs.services as Services
import qs.configurations

// Title and colour swatches for whichever theme the carousel is focused on.
Column {
  id: root

  property int themeIndex: 0

  readonly property var entry: Services.Theme.themeAt(root.themeIndex)
  readonly property var colors: root.entry ? root.entry.colors : null
  readonly property bool isApplied: root.entry && root.entry.themeId === Services.Theme.currentThemeId

  spacing: 12

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: 8

    Text {
      text: root.entry ? root.entry.name : ""
      color: ThemeSwitcherConfig.titleColor
      font.family: ThemeSwitcherConfig.fontFamily
      font.pixelSize: 17
      font.weight: Font.DemiBold
      anchors.verticalCenter: parent.verticalCenter
    }

    // A dot rather than a glyph, so the "currently applied" marker cannot turn
    // into tofu if the icon font changes.
    Rectangle {
      width: 7
      height: 7
      radius: 3.5
      color: ThemeSwitcherConfig.focusRingColor
      visible: root.isApplied
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: ThemeSwitcherConfig.swatchSpacing

    Repeater {
      // "background" is deliberately omitted: it is "transparent" in every
      // theme, which would render as an empty hole in the swatch row.
      model: root.colors ? [root.colors.surface, root.colors.foreground, root.colors.active, root.colors.secondary, root.colors.disabled] : []

      delegate: Rectangle {
        required property string modelData

        width: ThemeSwitcherConfig.swatchSize
        height: ThemeSwitcherConfig.swatchSize
        radius: ThemeSwitcherConfig.swatchRadius
        color: modelData
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)
      }
    }
  }
}
