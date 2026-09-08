pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Pointer position, polled only while something is actually watching.
//
// Hyprland publishes no cursor-motion event, so this has to ask. It asks over
// Hyprland's request socket rather than by running hyprctl: the answer costs
// well under a millisecond that way, where a fork would dominate, and the
// callers here poll while a widget is on screen.
Singleton {
  id: root

  // Nothing runs unless this is set. Callers turn it on for as long as they
  // need a position and off the moment they are done.
  property bool tracking: false

  property int x: 0
  property int y: 0

  readonly property int pollInterval: 33

  onTrackingChanged: {
    if (root.tracking)
      root.poll();
  }

  function poll() {
    // A request socket serves exactly one command and then closes, so every
    // poll is its own connection.
    if (!query.connected)
      query.connected = true;
  }

  Timer {
    interval: root.pollInterval
    running: root.tracking
    repeat: true
    onTriggered: root.poll()
  }

  Socket {
    id: query

    path: Hyprland.requestSocketPath

    onConnectionStateChanged: {
      if (query.connected)
        query.write("cursorpos");
    }

    parser: SplitParser {
      // Hyprland answers "<x>, <y>" with no trailing newline, so there is no
      // marker to split on: an empty marker hands over each chunk as it lands.
      splitMarker: ""

      onRead: data => {
        query.connected = false;
        root.apply(data);
      }
    }
  }

  function apply(text) {
    const parts = String(text).split(",");
    if (parts.length !== 2)
      return;

    const x = parseInt(parts[0], 10);
    const y = parseInt(parts[1], 10);

    if (isNaN(x) || isNaN(y))
      return;

    root.x = x;
    root.y = y;
  }
}
