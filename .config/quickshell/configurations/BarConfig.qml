pragma Singleton

import Quickshell
import QtQuick

import qs.services as Services

Singleton {
  // Bar
  readonly property int height: 40
  // [top, right, bottom, left]
  readonly property list<int> margin: [10, 15, 0, 15]
  readonly property list<int> padding: [10, 15, 0, 15]

  // Hyprland Workspaces
  readonly property int visibleWorkspaces: 6
  readonly property int totalWorkspaces: 99

  // Slot geometry. Every slot starts out at workspaceWidth so empty slots stay
  // uniform; a slot only grows past that once it holds more than one icon.
  readonly property int workspaceHeight: 24
  readonly property int workspaceWidth: 30
  readonly property int workspacePadding: 8
  readonly property int workspacesSpacing: 2

  // Icons shown inside a slot, capped so a busy workspace can't stretch the bar.
  readonly property int workspaceMaxIcons: 3
  // Sized for the Mono icon font, whose glyphs are drawn smaller than the
  // proportional ones; 19 here matches the previous on-screen icon size.
  readonly property int workspaceIconSize: 19
  readonly property int workspaceIconSpacing: 5

  // Colors
  readonly property color workspaceActiveColor: Services.Theme.active
  // Content sitting on the active capsule needs to contrast against it, not
  // against the bar, so it borrows the dark surface color.
  readonly property color workspaceActiveForeground: Services.Theme.surface
  readonly property color workspaceColor: Services.Theme.foregroundSurface
  readonly property color workspaceEmptyColor: Services.Theme.disabled
  readonly property color workspaceUrgentColor: "#e0707e"

  // The bar itself is transparent, so the widget carries its own subtle track
  // to stay legible over an arbitrary wallpaper.
  readonly property color workspacesTrackColor: Services.Theme.surface
  readonly property real workspacesTrackOpacity: 1
  readonly property int workspacesTrackPadding: 4

  readonly property int workspacesAnimationDuration: 220

  // Show the workspace number on slots that hold no windows.
  readonly property bool showId: true

  // Hyprland's Lua config evaluates dispatch strings as Lua, so the plain
  // "workspace 3" form is a syntax error there and switching silently fails.
  // With this on, workspace switches are sent as hl.dsp.focus({ workspace = N }),
  // matching the binds in .config/hypr/modules/keybinds.lua. Set it to false if
  // the Hyprland config is ever moved back to the classic .conf syntax.
  // Note: Quickshell's Hyprland.usingLua reports false here even on a Lua
  // config, so it cannot be used to detect this automatically.
  readonly property bool hyprlandLuaConfig: true

  // Scroll moves between existing workspaces ("e+1"/"e-1"), matching the
  // mouse_down/mouse_up binds in keybinds.lua.
  readonly property bool scrollExistingOnly: true

  // Between the widgets at the right end of the bar.
  readonly property int rightSectionSpacing: 6

  // ------------------------------------------------------------------ tray --

  // Items an application has marked Passive are ones it says are not worth
  // showing right now. Leaving them out is what keeps the tray from filling up
  // with idle icons.
  readonly property bool trayShowPassive: false

  readonly property int trayIconSize: 16
  readonly property int trayIconPadding: 4
  readonly property int trayIconSpacing: 0
  // Icons sit back a little until the pointer is on them, so a busy tray does
  // not compete with the workspaces for attention.
  readonly property real trayIconOpacity: 0.75
  readonly property real trayHoverOpacity: 0.25

  // --------------------------------------------------------------- battery --

  // Fractions, matching UPower, which reports 0..1 rather than a percentage.
  readonly property real batteryLowLevel: 0.25
  readonly property real batteryCriticalLevel: 0.1

  readonly property bool batteryShowPercent: true
  readonly property int batteryIconSize: 16
  readonly property int batteryTextSize: 12
  readonly property int batterySpacing: 4
  readonly property int batteryPadding: 4

  readonly property color batteryLowColor: "#e0b070"
  readonly property color batteryCriticalColor: "#e0707e"
  readonly property color batteryChargingColor: Services.Theme.active

  // Material Symbols, not the Nerd Font used for the app icons: the bar set
  // steps evenly, which is what lets the glyph carry the level.
  readonly property string batteryIconFontFamily: "Material Symbols Outlined"

  // Empty to full, chosen by rounding the level across the list.
  readonly property list<string> batteryIcons: [
    "",  // battery_0_bar
    "",  // battery_1_bar
    "",  // battery_2_bar
    "",  // battery_3_bar
    "",  // battery_4_bar
    "",  // battery_5_bar
    ""   // battery_6_bar
  ]

  readonly property string batteryFullIcon: ""      // battery_full
  readonly property string batteryChargingIcon: ""  // battery_charging_full
  readonly property string batteryAlertIcon: ""     // battery_alert

  readonly property string fontFamily: "AnnotationM Nerd Font"

  // ---------------------------------------------------------------- popups --

  // Surfaces that drop out of a bar widget: a tray item's menu, the network
  // list. Shared so the two look like the same thing in two places.
  readonly property int popupGap: 168
  readonly property int popupScreenMargin: 8
  readonly property int popupPadding: 8
  readonly property int popupRadius: 16
  readonly property int popupRiseDistance: 8
  readonly property int popupAnimationDuration: 180

  readonly property color popupColor: Services.Theme.surface
  readonly property color popupTextColor: Services.Theme.foregroundSurface
  readonly property color popupSubtleColor: Services.Theme.disabled
  readonly property color popupRowHoverColor: Services.Theme.background
  readonly property color popupSeparatorColor: Services.Theme.disabled
  readonly property real popupDisabledOpacity: 0.4

  readonly property int popupTextSize: 12
  readonly property int popupIconSize: 14
  readonly property int popupRowHeight: 30
  readonly property int popupRowRadius: 10
  readonly property int popupRowPadding: 10
  readonly property int popupSeparatorHeight: 9

  readonly property int popupMenuWidth: 220
  // How far a submenu is pushed in from its parent entry.
  readonly property int popupMenuIndent: 12

  readonly property string popupSubmenuIcon: "\ue409"   // chevron_right
  readonly property string popupCheckOnIcon: "\ue834"   // check_box
  readonly property string popupCheckOffIcon: "\ue835"  // check_box_outline_blank
  readonly property string popupRadioOnIcon: "\ue837"   // radio_button_checked
  readonly property string popupRadioOffIcon: "\ue836"  // radio_button_unchecked

  // Window class -> Nerd Font glyph, matched case-insensitively with a
  // substring fallback (so "code-oss" resolves through "code"). Keys are
  // ordered most-specific-first because the substring pass takes the first
  // match. Every glyph below was checked against AnnotationM Nerd Font.
  readonly property string defaultAppIcon: ""

  readonly property var appIcons: ({
      "kitty": "",
      "alacritty": "",
      "wezterm": "",
      "foot": "",
      "codium": "",
      "code-oss": "",
      "code": "",
      "firefox": "",
      "librewolf": "",
      "google-chrome": "",
      "chromium": "",
      "brave": "",
      "vesktop": "",
      "discord": "",
      "telegram": "",
      "spotify": "",
      "steam": "",
      "lutris": "",
      "obsidian": "",
      "thunderbird": "",
      "thunar": "",
      "nautilus": "",
      "dolphin": "",
      "nemo": "",
      "gimp": "",
      "quickshell": ""
    })
}
