import QtQuick

import Quickshell
import Quickshell.Widgets

import qs.components
import qs.configurations

// One row of the launcher's result list. Takes a search record from
// Services.AppLauncher and reports interaction back up; it owns no state of its
// own.
//
// Records are not all applications: an app row resolves a real icon from the
// desktop entry, while the calculator answer, the clipboard entries and the
// Clipboard History row itself carry a Material Symbols glyph instead.
Item {
  id: root

  required property var modelData
  required property int index

  readonly property var entry: root.modelData ? root.modelData.entry : null
  readonly property bool isApp: root.modelData ? root.modelData.kind === "app" : false
  readonly property string glyph: root.modelData && root.modelData.glyph
    ? root.modelData.glyph
    : ""

  // Empty when the icon theme has nothing for this entry, which is the cue to
  // fall back to a glyph. Checked up front rather than reacting to a failed
  // load, so the row never flashes a broken image.
  readonly property string iconSource: root.isApp && root.entry && root.entry.icon
    ? Quickshell.iconPath(root.entry.icon, true)
    : ""

  readonly property string caption: {
    if (!root.modelData)
      return "";

    return root.modelData.generic || root.modelData.comment || "";
  }

  signal activated(int index)
  signal hovered(int index)

  implicitHeight: AppLauncherConfig.rowHeight
  height: AppLauncherConfig.rowHeight

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    // Hovering moves the same cursor the keyboard drives, so the highlight
    // capsule never splits into a hover state and a selection state.
    onEntered: root.hovered(root.index)
    onClicked: root.activated(root.index)
  }

  Item {
    id: iconSlot

    anchors.left: parent.left
    anchors.leftMargin: AppLauncherConfig.rowPadding
    anchors.verticalCenter: parent.verticalCenter

    width: AppLauncherConfig.iconSize
    height: AppLauncherConfig.iconSize

    IconImage {
      anchors.fill: parent
      visible: root.iconSource !== ""
      source: root.iconSource
      asynchronous: true
    }

    AppIcon {
      anchors.fill: parent
      visible: root.isApp && root.iconSource === ""
      // AppIcon matches its map case-insensitively with a substring pass, so a
      // desktop entry id like "org.mozilla.firefox" still resolves.
      windowClass: root.modelData ? root.modelData.id : ""
      color: AppLauncherConfig.captionColor
      font.pixelSize: AppLauncherConfig.iconSize - 6
    }

    Text {
      anchors.fill: parent
      visible: !root.isApp

      text: root.glyph
      color: AppLauncherConfig.glyphColor
      font.family: AppLauncherConfig.iconFontFamily
      font.pixelSize: AppLauncherConfig.glyphSize
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
    }
  }

  Column {
    anchors {
      left: iconSlot.right
      leftMargin: AppLauncherConfig.iconSpacing
      right: parent.right
      rightMargin: AppLauncherConfig.rowPadding
      verticalCenter: parent.verticalCenter
    }

    spacing: 1

    Text {
      width: parent.width

      text: root.modelData ? root.modelData.name : ""
      color: AppLauncherConfig.textColor
      font.family: AppLauncherConfig.fontFamily
      font.pixelSize: AppLauncherConfig.nameFontSize
      font.weight: 700
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      visible: root.caption !== ""

      text: root.caption
      color: AppLauncherConfig.captionColor
      font.family: AppLauncherConfig.fontFamily
      font.pixelSize: AppLauncherConfig.captionFontSize
      elide: Text.ElideRight
    }
  }
}
