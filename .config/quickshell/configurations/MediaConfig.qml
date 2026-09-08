pragma Singleton

import Quickshell
import QtQuick

import qs.services as Services

Singleton {
  // Panel
  readonly property int panelWidth: 380
  readonly property int anchorWidth: 184
  readonly property int panelRadius: 28
  readonly property int panelPadding: 18

  readonly property int animationDuration: 280

  readonly property color mediaBg: Services.Theme.surface

  // Rows inside the panel: art + text, then the timeline, then the transport.
  readonly property int sectionSpacing: 14

  // Album art
  readonly property int artSize: 74
  readonly property int artRadius: 14
  // Shown when the player reports no art, or the art fails to load.
  readonly property string artFallbackIcon: ""  // music_note
  readonly property int artFallbackSize: 26
  readonly property color artPlaceholderColor: Services.Theme.background

  // Track text
  readonly property int textSpacing: 3
  readonly property int titleSize: 14
  readonly property int subtitleSize: 12
  readonly property color titleColor: Services.Theme.foregroundSurface
  readonly property color subtitleColor: Services.Theme.disabled

  // Timeline
  readonly property int progressHeight: 4
  readonly property int progressRadius: 2
  // The bar is thin, so the row it lives in is padded out to something a
  // pointer can actually hit and drag.
  readonly property int progressHitHeight: 16
  readonly property int progressHandleSize: 10
  readonly property color progressTrackColor: Services.Theme.disabled
  readonly property real progressTrackOpacity: 0.35
  readonly property color progressFillColor: Services.Theme.active
  readonly property int timeSize: 10
  readonly property color timeColor: Services.Theme.disabled
  readonly property int timeSpacing: 6

  // The transport only appears while the pointer is on the card. The card
  // growing is what reveals it; this is just the fade over the top of that.
  readonly property int controlsFadeDuration: 160

  // Transport
  readonly property int buttonSize: 28
  readonly property int primaryButtonSize: 34
  readonly property int buttonIconSize: 18
  readonly property int primaryButtonIconSize: 20
  readonly property int buttonSpacing: 4
  readonly property color buttonColor: Services.Theme.foregroundSurface
  readonly property color buttonHoverColor: Services.Theme.active
  // The play/pause capsule is filled, so its glyph contrasts with the accent
  // rather than with the panel.
  readonly property color primaryButtonBg: Services.Theme.active
  readonly property color primaryButtonColor: Services.Theme.surface
  readonly property real buttonDisabledOpacity: 0.3
  readonly property int buttonAnimationDuration: 140

  // Material Symbols codepoints for the transport row.
  readonly property string previousIcon: "chevron_left"  // skip_previous
  readonly property string playIcon: "play_arrow"      // play_arrow
  readonly property string pauseIcon: "pause"     // pause
  readonly property string nextIcon: "chevron_right"      // skip_next

  // Source badge, bottom-left. The glyph itself comes from BarConfig.appIcons
  // by way of AppIcon, so a player and its window resolve to the same icon.
  readonly property int sourceIconSize: 32
  readonly property color sourceIconColor: Services.Theme.foreground

  readonly property string fontFamily: "Adwaita Sans"
  readonly property string iconFontFamily: "Material Symbols Rounded"
}
