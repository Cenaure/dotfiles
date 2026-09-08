pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import "root:/modules/common/functions/fuzzysort.js" as Fuzzy

// Everything the app launcher knows how to do, minus how it looks. The module
// under modules/app-launcher is a pure view over this singleton: it renders
// `results`, reflects `selectedIndex`, and calls back in here to activate.
//
// `results` is a list of records that are not all applications. Every record
// carries a `kind`, and `activate` routes on it:
//
//   app     a desktop entry               -> launch it
//   action  a built-in, e.g. clipboard    -> switch the launcher into that mode
//   math    a qalc answer for the query   -> copy the answer
//   clip    an entry from cliphist        -> put it back on the clipboard
//
// They share the string fields fuzzysort searches (name, generic, comment,
// keywords, command) so one search path covers all of them.
//
// Opened over IPC from a Hyprland keybind:
//     qs ipc call appLauncher toggle
//
// Note this service deliberately does not import qs.configurations: the config
// singletons read colors from qs.services, and importing them back would make
// the two modules circular. Tunables here are behavioural, not visual.
Singleton {
  id: root

  // ------------------------------------------------------------- behaviour --

  // Results kept per query. Generous, since the list scrolls.
  readonly property int maxResults: 40
  // How many launches are remembered in the state file.
  readonly property int recentLimit: 12
  // Normalized fuzzysort score below which a match is noise. fuzzysort's own
  // default is 0.5, which drops useful acronym matches like "gimp" -> "GNU
  // Image Manipulation Program".
  readonly property real matchThreshold: 0.3
  // Added to the score of a recently launched app, scaled by how recent it is.
  // Small on purpose: it should break ties, not outrank a better match.
  readonly property real recencyWeight: 0.2

  // ----------------------------------------------------------------- state --

  property bool isOpen: false
  property string query: ""
  property int selectedIndex: 0

  // "apps" is the launcher proper; "clipboard" reuses the same field and list
  // to search clipboard history instead.
  property string mode: "apps"

  // Math is evaluated off the query as you type, in app mode only.
  onQueryChanged: {
    if (root.mode === "apps")
      Calculator.evaluate(root.query);
  }

  function open() {
    root.reset("apps");
    root.isOpen = true;
  }

  function close() {
    root.isOpen = false;
    root.reset("apps");
  }

  function reset(mode) {
    root.mode = mode;
    root.query = "";
    root.selectedIndex = 0;
    Calculator.clear();
  }

  function openClipboard() {
    root.reset("clipboard");
    ClipboardHistory.refresh();
  }

  // Backing out of a mode returns to the app list; only app mode closes the
  // launcher outright, so Escape never loses more than one step at a time.
  function back() {
    if (root.mode === "apps")
      root.close();
    else
      root.reset("apps");
  }

  function toggle() {
    if (root.isOpen)
      root.close();
    else
      root.open();
  }

  // ----------------------------------------------------------------- index --

  // Built-ins that behave like applications: searchable by name, launchable
  // with Enter, but handled inside the launcher instead of by exec.
  readonly property var actionRecords: [{
    kind: "action",
    action: "clipboard",
    id: "action:clipboard",
    name: "Clipboard History",
    generic: "Browse and copy earlier clipboard entries",
    comment: "",
    keywords: "clipboard history paste copy clip cliphist",
    command: "",
    glyph: "\ue14f"
  }]

  // One plain JS record per launchable desktop entry. fuzzysort searches these
  // rather than the DesktopEntry objects themselves: it prepares and caches its
  // targets by string, and feeding it QObjects means every key access crosses
  // the QML property system for every entry, on every keystroke.
  readonly property var appRecords: {
    const records = [];
    const apps = DesktopEntries.applications.values;

    for (let i = 0; i < apps.length; i++) {
      const app = apps[i];
      if (!app || app.noDisplay)
        continue;

      const keywords = app.keywords ?? [];

      records.push({
        kind: "app",
        entry: app,
        id: app.id ?? app.name ?? "",
        name: app.name ?? "",
        generic: app.genericName ?? "",
        comment: app.comment ?? "",
        keywords: keywords.join(" "),
        // Matches the binary you actually mean when you type "codium" at an
        // entry named "VSCodium".
        command: app.execString ?? ""
      });
    }

    records.sort((a, b) => a.name.localeCompare(b.name));
    return records;
  }

  // What a search runs against: the built-ins compete with the apps on score,
  // so typing "fire" still puts Firefox first.
  readonly property var index: root.actionRecords.concat(root.appRecords)

  // Position in the recents list, or -1. Drives the ranking bonus.
  function recencyOf(id) {
    return root.recentIds.indexOf(id);
  }

  // Shown when the search box is empty: the built-ins first, then what you
  // launched last, most recent first, falling back to the alphabetical list
  // before anything is recorded.
  function recentRecords() {
    const records = root.appRecords;
    const ids = root.recentIds;
    const byId = ({});

    for (let i = 0; i < records.length; i++)
      byId[records[i].id] = records[i];

    const recent = [];
    for (let i = 0; i < ids.length; i++) {
      const record = byId[ids[i]];
      if (record)
        recent.push(record);
    }

    const rest = recent.length > 0 ? recent : records.slice(0, root.maxResults);
    return root.actionRecords.concat(rest);
  }

  // Clipboard mode: the same fuzzy search, over cliphist's entries.
  function clipboardRecords() {
    const entries = ClipboardHistory.entries;
    const records = [];

    for (let i = 0; i < entries.length; i++) {
      records.push({
        kind: "clip",
        clipId: entries[i].id,
        id: "clip:" + entries[i].id,
        name: entries[i].text,
        generic: "",
        comment: "",
        keywords: "",
        command: "",
        glyph: "\ue14f"
      });
    }

    const needle = root.query.trim();
    if (needle === "")
      return records.slice(0, root.maxResults);

    const matches = Fuzzy.go(needle, records, {
      keys: ["name"],
      limit: root.maxResults,
      threshold: root.matchThreshold
    });

    return matches.map(match => match.obj);
  }

  // ---------------------------------------------------------------- search --

  // The answer to the current query, when it is a question qalc could answer.
  // Pinned above everything else: if you typed a sum, the sum is what you want.
  function mathRecords() {
    if (root.mode !== "apps" || !Calculator.hasResult)
      return [];

    return [{
      kind: "math",
      id: "math",
      name: Calculator.result,
      generic: "Enter to copy",
      comment: "",
      keywords: "",
      command: "",
      glyph: "\uea5f"
    }];
  }

  readonly property var results: {
    if (root.mode === "clipboard")
      return root.clipboardRecords();

    const needle = root.query.trim();

    if (needle === "")
      return root.recentRecords();

    const matches = Fuzzy.go(needle, root.index, {
      keys: ["name", "generic", "keywords", "comment", "command"],
      limit: root.maxResults,
      threshold: root.matchThreshold
    });

    // Re-rank rather than pass a scoreFn: fuzzysort applies the limit and
    // threshold against its own score, and the recency bonus should only
    // reorder what already matched, never pull in a non-match.
    const ranked = [];
    for (let i = 0; i < matches.length; i++) {
      const record = matches[i].obj;
      const at = root.recencyOf(record.id);
      const bonus = at === -1
        ? 0
        : root.recencyWeight * (1 - at / root.recentLimit);

      ranked.push({ record: record, score: matches[i].score + bonus });
    }

    ranked.sort((a, b) => b.score - a.score);
    return root.mathRecords().concat(ranked.map(entry => entry.record));
  }

  readonly property int resultCount: root.results.length

  // A new result set invalidates wherever the cursor was sitting.
  onResultsChanged: root.selectedIndex = 0

  function moveSelection(delta) {
    const count = root.resultCount;
    if (count === 0)
      return;

    root.selectedIndex = (root.selectedIndex + delta + count) % count;
  }

  function activate(index) {
    const list = root.results;
    if (index < 0 || index >= list.length)
      return;

    const record = list[index];

    switch (record.kind) {
    case "action":
      if (record.action === "clipboard")
        root.openClipboard();
      return;

    case "math":
      ClipboardHistory.copyText(record.name);
      root.close();
      return;

    case "clip":
      ClipboardHistory.copyEntry(record.clipId);
      root.close();
      return;
    }

    root.recordLaunch(record.id);
    // Closed first so the layer surface has given up keyboard focus by the
    // time the new window maps and asks for it.
    root.close();
    record.entry.execute();
  }

  // ----------------------------------------------------------------- state --

  readonly property var recentIds: launcherState.adapter.recentAppIds ?? []

  FileView {
    id: launcherState

    path: Qt.resolvedUrl("../state/app-launcher.state.json")
    watchChanges: true
    onFileChanged: reload()

    JsonAdapter {
      property var recentAppIds: []
    }
  }

  function recordLaunch(id) {
    if (!id)
      return;

    let list = (launcherState.adapter.recentAppIds ?? []).slice();
    const at = list.indexOf(id);

    if (at !== -1)
      list.splice(at, 1);

    list.unshift(id);

    if (list.length > root.recentLimit)
      list = list.slice(0, root.recentLimit);

    launcherState.adapter.recentAppIds = list;
    launcherState.writeAdapter();
  }

  function clearRecent() {
    launcherState.adapter.recentAppIds = [];
    launcherState.writeAdapter();
  }

  // ------------------------------------------------------------------- ipc --

  IpcHandler {
    target: "appLauncher"

    function toggle(): string {
      root.toggle();
      return root.isOpen ? "opened" : "closed";
    }

    function open(): string {
      root.open();
      return "opened";
    }

    function close(): string {
      root.close();
      return "closed";
    }
  }
}
