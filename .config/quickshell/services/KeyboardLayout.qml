pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// The keyboard layout cycle and which of it is active, plus the two reasons the
// on-screen indicator appears: you just switched, or you are holding Alt to
// check. modules/keyboard-layout renders it and owns nothing else.
//
// Driven by Hyprland's activelayout event rather than by the keybind, so it is
// correct however the layout changed --- SUPER+SPACE, the grp:alt_shift_toggle
// from input.lua, or anything else.
Singleton {
  id: root

  // ------------------------------------------------------------- behaviour --

  // Holding Alt has to outlast this before the indicator appears, so Alt+Tab
  // and the Alt+Shift layout toggle do not flash it on every use.
  readonly property int holdDelay: 250
  // The indicator always goes away on its own this long after appearing,
  // whichever reason put it there. Holding Alt does not keep it up
  // indefinitely: by then you have read it. It also means a missing key-release
  // --- a bare ALT_L bind does not necessarily see one, since the modifier mask
  // differs between press and release --- cannot leave it stuck on screen.
  readonly property int visibleDuration: 1000

  // Display label per xkb layout code. Anything not listed falls back to the
  // code in upper case, so adding a layout to input.lua needs no change here
  // unless you dislike what it is called.
  readonly property var displayOverrides: ({
      "us": "EN"
    })

  // Hyprland's activelayout event names the layout ("English (US)"), not its
  // xkb code, so this is how the event is resolved back to a position in the
  // cycle. Keys are the names Hyprland uses.
  readonly property var keymapCodes: ({
      "English (US)": "us",
      "Russian": "ru",
      "Ukrainian": "ua",
      "Slovak": "sk"
    })

  // ----------------------------------------------------------------- layout --

  // xkb codes in cycle order, e.g. ["us", "ru", "ua", "sk"].
  property var layouts: []
  // The keyboard whose layout is reported. Switching happens for every device
  // at once, so without this the indicator would react nine times per switch.
  property string mainDevice: ""
  property int currentIndex: -1

  readonly property var displayCodes: {
    const codes = [];

    for (let i = 0; i < root.layouts.length; i++) {
      const code = root.layouts[i];
      codes.push(root.displayOverrides[code] ?? code.toUpperCase());
    }

    return codes;
  }

  Process {
    id: devices

    command: ["hyprctl", "devices", "-j"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: root.readDevices(this.text)
    }
  }

  function readDevices(text) {
    let data;

    try {
      data = JSON.parse(text);
    } catch (error) {
      console.warn("keyboard layout: could not parse hyprctl devices:", error);
      return;
    }

    const keyboards = data.keyboards ?? [];
    const main = keyboards.find(keyboard => keyboard.main) ?? keyboards[0];

    if (!main)
      return;

    root.mainDevice = main.name ?? "";
    root.layouts = String(main.layout ?? "").split(",").filter(code => code !== "");
    root.applyKeymap(main.active_keymap ?? "");
  }

  function applyKeymap(name) {
    const code = root.keymapCodes[name];

    if (code === undefined) {
      console.warn("keyboard layout: unknown keymap name", JSON.stringify(name));
      return;
    }

    root.currentIndex = root.layouts.indexOf(code);
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      if (event.name !== "activelayout")
        return;

      // "<device>,<Layout Name>". The device comes first, so the first comma
      // is the separator even though a layout name could contain one.
      const separator = event.data.indexOf(",");
      if (separator === -1)
        return;

      const device = event.data.slice(0, separator);
      if (root.mainDevice && device !== root.mainDevice)
        return;

      root.applyKeymap(event.data.slice(separator + 1));
      root.announce();
    }
  }

  // --------------------------------------------------------------- visibility --

  // A switch shows the whole cycle, so you can see what you moved from and to.
  // Holding Alt is only asking "what am I typing in", so it shows one pill.
  readonly property string cycleMode: "cycle"
  readonly property string currentMode: "current"

  property string mode: root.cycleMode
  property bool osdVisible: false

  // What the indicator renders: every layout with the active one marked, or
  // just the active one.
  readonly property var osdEntries: {
    const codes = root.displayCodes;
    const entries = [];

    if (root.mode === root.currentMode) {
      if (root.currentIndex >= 0 && root.currentIndex < codes.length)
        entries.push({
          code: codes[root.currentIndex],
          active: true
        });

      return entries;
    }

    for (let i = 0; i < codes.length; i++)
      entries.push({
        code: codes[i],
        active: i === root.currentIndex
      });

    return entries;
  }

  // The indicator sits at the pointer, so the pointer has to be watched --- but
  // only while it is on screen.
  onOsdVisibleChanged: Cursor.tracking = root.osdVisible

  Timer {
    id: hold
    interval: root.holdDelay
    onTriggered: root.show(root.currentMode)
  }

  Timer {
    id: visibility
    interval: root.visibleDuration
    onTriggered: root.osdVisible = false
  }

  function show(mode) {
    root.mode = mode;
    root.osdVisible = true;
    visibility.restart();
  }

  function hide() {
    visibility.stop();
    root.osdVisible = false;
  }

  // Alt down. Nothing shows yet: only holding it past holdDelay does.
  function peek() {
    hold.restart();
  }

  function release() {
    hold.stop();

    // Only the peek belongs to the Alt key. Letting go of Alt right after an
    // Alt+Shift switch must not cut the switch announcement short.
    if (root.mode === root.currentMode)
      root.hide();
  }

  // A switch announces itself with the full cycle, taking over from a peek if
  // one is already up --- which it is when you switched with Alt+Shift.
  function announce() {
    root.show(root.cycleMode);
  }

  // Bound in keybinds.lua as `hl.dsp.global("quickshell:layoutPeek")`. The
  // global shortcut protocol reports press and release both, so holding Alt
  // costs nothing beyond two signals.
  GlobalShortcut {
    appid: "quickshell"
    name: "layoutPeek"

    onPressed: root.peek()
    onReleased: root.release()
  }
}
