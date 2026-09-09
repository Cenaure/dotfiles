pragma Singleton

import Quickshell
import QtQuick

import qs.services as Services

Singleton {
  // Panel. Same width as the media panel, since the two stack.
  readonly property int panelWidth: 320
  readonly property int anchorWidth: 184
  readonly property int panelRadius: 28
  readonly property int panelPadding: 18

  readonly property int animationDuration: 280

  readonly property color panelColor: Services.Theme.surface

  // Gauges
  readonly property int gaugeSpacing: 18
  readonly property int gaugeTextSpacing: 4

  readonly property int labelSize: 10
  readonly property int labelIconSize: 13
  readonly property int labelSpacing: 5
  readonly property int valueSize: 22
  readonly property int detailSize: 10

  // Trailing reading beside the big number --- deliberately smaller, so the
  // percentage stays the thing the eye lands on first.
  readonly property int valueSuffixSize: 12
  readonly property int valueSuffixSpacing: 6

  readonly property color labelColor: Services.Theme.disabled
  readonly property color valueColor: Services.Theme.foregroundSurface
  readonly property color detailColor: Services.Theme.disabled
  readonly property color valueSuffixColor: Services.Theme.disabled

  // CPU temperature, shown beside the load percentage. Past the threshold it
  // turns, on the same reasoning as the bar below it: a machine running hot
  // should say so without the number having to be read.
  readonly property real temperatureWarning: 80
  readonly property color temperatureWarningColor: "#e0707e"

  readonly property int barHeight: 4
  readonly property int barRadius: 2
  readonly property color barTrackColor: Services.Theme.disabled
  readonly property real barTrackOpacity: 0.35
  readonly property color barFillColor: Services.Theme.active
  // Past this the fill turns, so a machine under real load says so without
  // needing the number to be read.
  readonly property real barWarningThreshold: 0.85
  readonly property color barWarningColor: "#e0707e"

  // Per-core strip along the bottom. One column per core, each its own load.
  readonly property bool showCores: true
  readonly property int coreStripHeight: 18
  readonly property int coreStripTopMargin: 14
  readonly property int coreSpacing: 3
  readonly property int coreRadius: 2
  // A core doing nothing still shows a stub, so the strip reads as a row of
  // bars rather than as gaps.
  readonly property int coreMinHeight: 3
  readonly property color coreColor: Services.Theme.active
  readonly property real coreIdleOpacity: 0.28

  // Material Symbols codepoints.
  readonly property string cpuIcon: ""     // memory
  readonly property string memoryIcon: ""  // database

  readonly property string fontFamily: "AnnotationM Nerd Font"
  readonly property string iconFontFamily: "Material Symbols Outlined"
}
