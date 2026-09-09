pragma Singleton

import Quickshell
import QtQuick

import qs.services as Services

Singleton {
  // Bar widget
  readonly property bool showLabel: false
  readonly property int iconSize: 16
  readonly property int labelSize: 12
  readonly property int labelMaxWidth: 110
  readonly property int spacing: 5
  readonly property int padding: 4

  readonly property color color: Services.Theme.foregroundSurface
  readonly property color offlineColor: Services.Theme.disabled
  readonly property color connectingColor: Services.Theme.active

  // Popup
  readonly property int popupWidth: 260
  readonly property int listMaxHeight: 240
  readonly property int headerHeight: 30
  readonly property int headerSize: 12
  readonly property int rowHeight: 34
  readonly property int rowRadius: 10
  readonly property int rowPadding: 10
  readonly property int rowSpacing: 8
  readonly property int rowTextSize: 12
  readonly property int rowDetailSize: 10
  readonly property int rowIconSize: 14

  readonly property int emptyHeight: 64
  readonly property string emptyText: "No networks found"
  readonly property string disabledText: "Wi-Fi is turned off"

  // The enable/disable switch in the header.
  readonly property int switchWidth: 34
  readonly property int switchHeight: 18
  readonly property int switchKnob: 14
  readonly property color switchOnColor: Services.Theme.active
  readonly property color switchOffColor: Services.Theme.disabled
  readonly property color switchKnobColor: Services.Theme.surface

  // Password prompt for a network that is not already set up.
  readonly property int passwordHeight: 30
  readonly property int passwordRadius: 10
  readonly property int passwordSize: 12
  readonly property color passwordBg: Services.Theme.background
  readonly property string passwordPlaceholder: "Password"

  // Strength buckets, weakest first. The one the level lands in is drawn.
  readonly property list<string> wifiIcons: [
    "",  // wifi_1_bar
    "",  // wifi_2_bar
    ""   // wifi
  ]

  readonly property string wifiOffIcon: ""   // wifi_off
  readonly property string wiredIcon: ""     // lan
  readonly property string lockIcon: ""      // lock
  readonly property string checkIcon: ""     // check
  readonly property string offlineIcon: ""   // signal_wifi_bad

  readonly property string fontFamily: "AnnotationM Nerd Font"
  readonly property string iconFontFamily: "Material Symbols Outlined"
}
