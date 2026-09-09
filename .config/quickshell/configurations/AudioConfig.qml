pragma Singleton

import Quickshell
import QtQuick

import qs.services as Services

Singleton {
  id: root

  // Bar widget
  readonly property bool showPercent: false
  readonly property int iconSize: 16
  readonly property int labelSize: 12
  readonly property int spacing: 4
  readonly property int padding: 4

  readonly property color color: Services.Theme.foregroundSurface
  readonly property color mutedColor: Services.Theme.disabled

  // Mixer popup
  readonly property int popupWidth: 300
  readonly property int sectionSpacing: 12
  readonly property int rowSpacing: 8
  readonly property int listMaxHeight: 190

  readonly property int sectionLabelSize: 12
  readonly property int nameSize: 12
  readonly property int detailSize: 10
  readonly property int rowIconSize: 15
  // The same inset the tray menu and the network list use, taken from there
  // rather than repeated, so the three popups cannot drift apart.
  readonly property int rowPadding: BarConfig.popupRowPadding

  // Round icon buttons are wider than the glyph inside them, so insetting one
  // by rowPadding would push its glyph past everything else. Backing off by
  // half the difference lines the glyph up with the text instead of lining the
  // button's edge up with it.
  readonly property real controlInset: root.rowPadding
    - (root.muteButtonSize - root.muteIconSize) / 2
  readonly property int rowHeight: 30
  readonly property int rowRadius: 10

  readonly property color sectionLabelColor: Services.Theme.disabled
  readonly property color nameColor: Services.Theme.foregroundSurface
  readonly property color detailColor: Services.Theme.disabled

  // Sliders
  readonly property int sliderHeight: 4
  readonly property int sliderHitHeight: 18
  readonly property int sliderHandleSize: 10
  readonly property int sliderAnimationDuration: 140
  readonly property real sliderDisabledOpacity: 0.4
  readonly property color sliderTrackColor: Services.Theme.disabled
  readonly property real sliderTrackOpacity: 0.35
  readonly property color sliderFillColor: Services.Theme.active

  readonly property int muteButtonSize: 24
  readonly property int muteIconSize: 15

  readonly property int emptyHeight: 40
  readonly property string emptyText: "Nothing playing"

  // Volume steps, weakest first; the level picks one.
  readonly property list<string> volumeIcons: [
    "\ue04e",  // volume_mute
    "\ue04d",  // volume_down
    "\ue050"   // volume_up
  ]

  readonly property string mutedIcon: "\ue04f"      // volume_off
  readonly property string micIcon: "\ue029"        // mic
  readonly property string micMutedIcon: "\ue02b"   // mic_off
  readonly property string outputIcon: "\ue32d"     // speaker
  readonly property string mixerIcon: "\ue895"      // open_in_new

  readonly property string outputLabel: "Output"
  readonly property string inputLabel: "Input"
  readonly property string appsLabel: "Applications"
  readonly property string mixerLabel: "Open pavucontrol"

  readonly property string fontFamily: "AnnotationM Nerd Font"
  readonly property string iconFontFamily: "Material Symbols Outlined"
}
