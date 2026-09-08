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
