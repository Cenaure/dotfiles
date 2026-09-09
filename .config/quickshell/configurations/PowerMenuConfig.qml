pragma Singleton

import Quickshell
import QtQuick

import qs.services as Services

Singleton {
  id: root

  // Tiles. Three of them in a row, sized like wlogout's cells: wider than they
  // are tall, glyph over label.
  readonly property int tileWidth: 116
  readonly property int tileHeight: 116
  readonly property int tileSpacing: 18
  readonly property int tileBorderWidth: 1

  readonly property int glyphSize: 40
  readonly property int labelSize: 13
  readonly property int labelSpacing: 12

  // Panel geometry. Derived from the tiles rather than hardcoded, so retuning a
  // tile keeps the card the right size around it.
  readonly property int panelPadding: 14
  readonly property int panelWidth: tileWidth * 3 + tileSpacing * 2 + panelPadding * 2
  readonly property int panelRadius: 26
  // Flush with the bottom screen edge, square down there: the same treatment
  // the app launcher gets, so both bottom surfaces read as one family.
  readonly property int bottomMargin: 10
  readonly property int panelBottomRadius: 0

  // Collapsed state the panel is parked at while closed. Unused for shape --
  // the panel slides rather than morphs -- but FloatingPanel still measures the
  // park distance from it.
  readonly property int anchorWidth: 220
  readonly property int anchorHeight: 46

  readonly property int animationDuration: 320
  readonly property int hoverDuration: 150

  // Colors. An opaque card over an arbitrary wallpaper, so everything inside
  // contrasts against the surface rather than the desktop.
  readonly property color buttonColor: Services.Theme.surface
  readonly property color panelColor: "transparent"
  readonly property color glyphColor: Services.Theme.foregroundSurface
  readonly property color labelColor: Services.Theme.disabled
  readonly property color borderColor: Services.Theme.disabled

  readonly property color selectedGlyphColor: Services.Theme.active
  readonly property color selectedLabelColor: Services.Theme.foregroundSurface
  readonly property color selectedBorderColor: Services.Theme.active
  // The accent at low alpha reads as a highlight without fighting the glyph for
  // attention, the same way the launcher's selection capsule does.
  readonly property color selectedColor: Qt.rgba(Services.Theme.active.r, Services.Theme.active.g, Services.Theme.active.b, 0.18)

  readonly property real idleBorderOpacity: 1

  readonly property string fontFamily: "AnnotationM Nerd Font"
  readonly property string iconFontFamily: "Material Symbols Outlined"

  // ------------------------------------------------------------- actions --

  // Keybinds match wlogout's layout file, so the letters you already press
  // still work.
  readonly property var actions: [
    {
      id: "lock",
      label: "Lock",
      // lock
      icon: "\ue88d",
      key: Qt.Key_L,

      command: ["loginctl", "lock-session"]
    },
    {
      id: "shutdown",
      label: "Shutdown",
      // power_settings_new
      icon: "\ue8ac",
      key: Qt.Key_S,
      command: ["systemctl", "poweroff"]
    },
    {
      id: "restart",
      label: "Restart",
      // restart_alt
      icon: "\uf053",
      key: Qt.Key_R,
      command: ["systemctl", "reboot"]
    }
  ]
}
