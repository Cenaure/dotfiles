pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history, backed by cliphist.
//
// cliphist keeps the store itself --- deduplicated, capped, and able to hold
// images --- and is fed by the two `wl-paste --watch` lines in the Hyprland
// autostart. This only reads that store and writes entries back to the
// clipboard.
Singleton {
  id: root

  // { id, text } per entry, newest first, as cliphist lists them.
  property var entries: []

  function refresh() {
    listing.running = true;
  }

  Process {
    id: listing

    command: ["cliphist", "list"]

    stdout: StdioCollector {
      onStreamFinished: root.entries = root.parseListing(this.text)
    }
  }

  // cliphist prints "<id>\t<preview>", one entry per line. Images arrive as a
  // "[[ binary data ... ]]" preview, which is what gets shown; decoding still
  // returns the real image.
  function parseListing(text) {
    const parsed = [];
    const lines = text.split("\n");

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      if (line === "")
        continue;

      const separator = line.indexOf("\t");
      if (separator === -1)
        continue;

      parsed.push({
        id: line.slice(0, separator),
        text: line.slice(separator + 1)
      });
    }

    return parsed;
  }

  Process {
    id: restore
  }

  function copyEntry(id) {
    // The id goes through as an argument rather than being spliced into the
    // command string, so nothing in it can be read as shell syntax.
    restore.command = ["sh", "-c", 'cliphist decode "$1" | wl-copy', "sh", id];
    restore.running = true;
  }

  Process {
    id: copy
  }

  function copyText(text) {
    if (!text)
      return;

    copy.command = ["wl-copy", "--", text];
    copy.running = true;
  }
}
