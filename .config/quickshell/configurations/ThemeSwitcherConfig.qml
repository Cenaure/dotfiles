pragma Singleton

import Quickshell
import QtQuick

import qs.services as Services

Singleton {
  // The menu is the workspaces pill grown up, so anchorWidth/anchorHeight must
  // match that pill: the rectangle starts at exactly its geometry.
  readonly property int panelWidth: 520
  readonly property int anchorWidth: 184
  readonly property int panelRadius: 28
  readonly property int panelPadding: 18

  // Carousel
  readonly property int thumbWidth: 152
  readonly property int thumbHeight: 86
  readonly property int thumbSpacing: 14
  readonly property int thumbRadius: 10
  readonly property real thumbInactiveScale: 0.84
  readonly property real thumbInactiveOpacity: 0.5
  readonly property int captionSize: 11
  readonly property int captionSpacing: 7

  // Palette swatches
  readonly property int swatchSize: 18
  readonly property int swatchSpacing: 8
  readonly property int swatchRadius: 6

  readonly property int animationDuration: 280

  readonly property color bubbleColor: Services.Theme.surface
  readonly property color titleColor: Services.Theme.foregroundSurface
  readonly property color subtitleColor: Services.Theme.disabled
  readonly property color focusRingColor: Services.Theme.active

  readonly property string fontFamily: "AnnotationM Nerd Font"
}
