pragma Singleton

import Quickshell
import QtQuick

import qs.services as Services

Singleton {
  // ------------------------------------------------------------------ popups --

  // The stack hangs under the right end of the bar, matching its margin so the
  // cards line up with whatever the bar's right-most widget is.
  readonly property int popupWidth: 380
  readonly property int popupSpacing: 10
  readonly property int popupTopGap: 10

  readonly property int popupAnimationDuration: 260
  // How far a card travels in from the right as it appears.
  readonly property int popupSlideDistance: 40

  // ------------------------------------------------------------------- cards --

  readonly property int cardRadius: 20
  readonly property int cardPadding: 14
  readonly property int cardSpacing: 12
  readonly property color cardColor: Services.Theme.surface

  // A vertical accent down the leading edge, coloured by urgency. Quieter than
  // tinting the whole card, and still readable at a glance.
  readonly property int accentWidth: 3
  readonly property int accentInset: 10
  readonly property color accentLow: Services.Theme.disabled
  readonly property color accentNormal: Services.Theme.active
  readonly property color accentCritical: "#e0707e"

  readonly property int iconSize: 36
  readonly property int iconRadius: 12
  readonly property int iconGlyphSize: 20
  readonly property color iconPlaceholderColor: Services.Theme.background

  readonly property int appNameSize: 10
  readonly property int summarySize: 13
  readonly property int bodySize: 12
  readonly property int textSpacing: 3
  // Bodies can be long; past this the card scrolls no further and elides.
  readonly property int bodyMaxLines: 4

  readonly property color appNameColor: Services.Theme.disabled
  readonly property color summaryColor: Services.Theme.foregroundSurface
  readonly property color bodyColor: Services.Theme.disabled
  readonly property color ageColor: Services.Theme.disabled

  // ----------------------------------------------------------------- actions --

  readonly property int actionHeight: 28
  readonly property int actionRadius: 14
  readonly property int actionPaddingX: 14
  readonly property int actionSpacing: 6
  readonly property int actionFontSize: 11
  readonly property color actionColor: Services.Theme.background
  readonly property color actionHoverColor: Services.Theme.active
  readonly property color actionTextColor: Services.Theme.foregroundSurface
  readonly property color actionHoverTextColor: Services.Theme.surface

  readonly property int closeButtonSize: 20
  readonly property int closeIconSize: 14
  readonly property color closeColor: Services.Theme.disabled
  readonly property color closeHoverColor: Services.Theme.foregroundSurface

  readonly property int hoverAnimationDuration: 140

  // ------------------------------------------------------------------ centre --

  readonly property int panelWidth: 440
  readonly property int panelRadius: 28
  readonly property int panelPadding: 18
  readonly property int panelBottomRadius: 0
  readonly property int anchorWidth: 240
  readonly property int anchorHeight: 44
  // Flush to the bottom screen edge, like the launcher: the square bottom
  // corners above only read as "rising out of the edge" if it is actually
  // touching it.
  readonly property int bottomMargin: 0
  readonly property int animationDuration: 360

  // The list is what gives, so the panel stops growing once it is this tall.
  readonly property int listMaxHeight: 460
  readonly property int listSpacing: 8

  readonly property int headerSpacing: 10
  readonly property int headerTitleSize: 15
  readonly property int headerCountSize: 11
  readonly property int headerButtonSize: 30
  readonly property int headerIconSize: 17
  readonly property color headerTitleColor: Services.Theme.foregroundSurface
  readonly property color headerCountColor: Services.Theme.disabled

  readonly property int emptyIconSize: 34
  readonly property int emptyTextSize: 12
  readonly property int emptySpacing: 10
  readonly property int emptyHeight: 150
  readonly property color emptyColor: Services.Theme.disabled
  readonly property string emptyText: "Nothing to catch up on"

  // Material Symbols codepoints.
  readonly property string closeIcon: ""
  readonly property string bellIcon: ""
  readonly property string bellOffIcon: ""
  readonly property string clearAllIcon: ""
  readonly property string emptyIcon: ""

  readonly property color panelColor: Services.Theme.surface

  readonly property string fontFamily: "AnnotationM Nerd Font"
  readonly property string iconFontFamily: "Material Symbols Outlined"
}
