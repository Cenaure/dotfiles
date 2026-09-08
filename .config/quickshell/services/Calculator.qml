pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Turns a launcher query into a calculation, when it looks like one.
//
// Backed by qalc (libqalculate), so this is not only arithmetic: unit and
// currency conversion, percentages and base conversion all work, which is why
// it is worth spawning a process instead of parsing expressions in JS.
Singleton {
  id: root

  // qalc answers in well under 100ms, but a keystroke should not cost a process
  // each. One evaluation per pause in typing is plenty.
  readonly property int debounceInterval: 120

  property string expression: ""
  property string result: ""

  readonly property bool hasResult: root.result !== ""

  // Deliberately narrow. Anything accepted here spawns a process, so a plain
  // app search must not qualify: a leading "=" is always math, and otherwise
  // there has to be a digit *and* something to do with it.
  function looksLikeMath(text) {
    const candidate = text.trim();

    if (candidate === "")
      return false;

    if (candidate.startsWith("="))
      return true;

    if (!/\d/.test(candidate))
      return false;

    return /[-+*\/^%()]|\b(to|in|mod)\b|\b(sqrt|cbrt|abs|exp|ln|log|sin|cos|tan)\b/i.test(candidate);
  }

  function evaluate(text) {
    if (!root.looksLikeMath(text)) {
      root.clear();
      return;
    }

    root.expression = text.trim();
    debounce.restart();
  }

  function clear() {
    debounce.stop();
    root.expression = "";
    root.result = "";
  }

  Timer {
    id: debounce
    interval: root.debounceInterval
    onTriggered: {
      // -t prints the result alone, -m 0 keeps it from trying to be clever
      // about how long it thinks about the expression.
      calculation.command = ["qalc", "-t", "-m", "0", root.source()];
      calculation.running = true;
    }
  }

  // The "=" is ours, not qalc's.
  function source() {
    return root.expression.replace(/^=\s*/, "");
  }

  Process {
    id: calculation

    stdout: StdioCollector {
      onStreamFinished: root.handleOutput(this.text)
    }
  }

  function handleOutput(text) {
    const output = text.trim();

    // qalc echoes the input back when it cannot evaluate it, so an answer that
    // is just the question restated is not an answer.
    if (output === "" || /^error/i.test(output) || root.compact(output) === root.compact(root.source())) {
      root.result = "";
      return;
    }

    root.result = output;
  }

  function compact(text) {
    return text.replace(/\s+/g, "").toLowerCase();
  }
}
