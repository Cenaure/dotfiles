pragma Singleton

import Quickshell
import QtQuick

import qs.services as Services

Singleton {
  // Panel geometry. The launcher is not a bar widget, so it grows out of a
  // pill sitting on the bottom edge rather than out of something in the bar.
  readonly property int panelWidth: 560
  readonly property int panelRadius: 26
  readonly property int panelPadding: 14
  // Flush with the bottom screen edge: no gap, and square corners down there,
  // so the panel grows out of the edge instead of floating above it.
  readonly property int bottomMargin: 0
  readonly property int panelBottomRadius: 0

  // Collapsed state the panel morphs out of, centred on the bottom edge.
  readonly property int anchorWidth: 220
  readonly property int anchorHeight: 46

  readonly property int animationDuration: 320

  // Search field
  readonly property int searchHeight: 34
  readonly property int searchIconSize: 20
  readonly property int searchFontSize: 16
  readonly property int searchSpacing: 12
  readonly property string searchPlaceholder: "Search applications"
  readonly property string clipboardPlaceholder: "Search clipboard history"

  // Result rows
  readonly property int rowHeight: 46
  readonly property int rowSpacing: 2
  readonly property int rowRadius: 12
  readonly property int rowPadding: 10
  readonly property int iconSize: 28
  readonly property int iconSpacing: 12
  readonly property int nameFontSize: 14
  readonly property int captionFontSize: 11
  // Rows visible at once. The result area is exactly this tall whatever the
  // query matches, so the panel never resizes while you type and the list
  // scrolls instead. Derived from the row metrics rather than hardcoded, so
  // retuning rowHeight keeps the arithmetic honest.
  readonly property int visibleRows: 7
  readonly property int listHeight: visibleRows * rowHeight + (visibleRows - 1) * rowSpacing
  readonly property int highlightDuration: 150

  // Colors. The panel is an opaque surface over an arbitrary wallpaper, so
  // everything inside contrasts against the surface rather than the desktop.
  readonly property color panelColor: Services.Theme.surface
  readonly property color textColor: Services.Theme.foregroundSurface
  readonly property color captionColor: Services.Theme.disabled
  readonly property color accentColor: Services.Theme.active
  readonly property color separatorColor: Services.Theme.disabled
  readonly property real separatorOpacity: 0.28

  // Selection capsule: the accent at low alpha reads as a highlight without
  // fighting the row text for attention.
  readonly property color selectionColor: Qt.rgba(Services.Theme.active.r, Services.Theme.active.g, Services.Theme.active.b, 0.18)

  // Rows that are not applications (the calculator answer, clipboard entries,
  // the Clipboard History entry itself) draw a glyph where an app icon goes.
  readonly property color glyphColor: Services.Theme.active
  readonly property int glyphSize: 22

  readonly property string fontFamily: "AnnotationM Nerd Font"
  readonly property string iconFontFamily: "Material Symbols Outlined"
}
