pragma Singleton

import Quickshell
import QtQuick

import qs.services as Services

Singleton {
  // The PAM stack the password is checked against. `login` is what a local
  // session authenticates with on Arch, and works unprivileged because pam_unix
  // shells out to the setuid unix_chkpwd helper to read the shadow file.
  //
  // If authentication fails for every password, this is the first thing to
  // change --- some distributions want a lock-screen-specific stack instead.
  readonly property string pamConfig: "login"

  // Background. The desktop wallpaper, blurred back far enough that the clock
  // and the field read cleanly over any of them.
  readonly property real backgroundBlur: 0.55
  readonly property real backgroundDim: 0.55
  // How long the wallpaper takes to fade up. The surface is painted before the
  // image has decoded, so without this the lock screen flashes its dim colour.
  readonly property int backgroundFadeDuration: 420

  // Clock
  readonly property int clockSize: 92
  readonly property int dateSize: 17
  readonly property int clockSpacing: 4

  // Password field
  readonly property int fieldWidth: 340
  readonly property int fieldHeight: 52
  readonly property int fieldRadius: 26
  readonly property int fieldBorderWidth: 1
  readonly property int fieldPadding: 20
  readonly property int fieldGlyphSize: 20
  readonly property int fieldSpacing: 12
  readonly property int fieldFontSize: 16
  readonly property string fieldPlaceholder: "Password"
  readonly property string busyPlaceholder: "Checking…"

  // Gap between the clock block and the field block.
  readonly property int stackSpacing: 56
  readonly property int messageSpacing: 16
  readonly property int messageSize: 13

  readonly property int fadeDuration: 200
  // A failed attempt shakes the field rather than turning it red: the palette
  // has no error colour, and inventing one would be the only thing on screen
  // not coming from the theme.
  readonly property int shakeDuration: 340
  readonly property int shakeDistance: 12

  // Colors, all from the active theme, so the lock screen recolours with the
  // rest of the rice.
  readonly property color dimColor: Services.Theme.surface
  readonly property color surfaceColor: Services.Theme.surface
  readonly property color textColor: Services.Theme.foregroundSurface
  readonly property color subtleColor: Services.Theme.secondary
  readonly property color accentColor: Services.Theme.active
  readonly property color borderColor: Services.Theme.disabled
  readonly property real fieldOpacity: 0.72
  readonly property real idleBorderOpacity: 0.4

  readonly property string wallpaperUrl: Services.Theme.wallpaperUrl

  readonly property string fontFamily: "AnnotationM Nerd Font"
  readonly property string iconFontFamily: "Material Symbols Outlined"

  readonly property string lockGlyph: "\ue88d"  // lock
  readonly property string submitGlyph: "\ue5c8"  // arrow_forward
}
