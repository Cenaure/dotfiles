pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Qt.labs.folderlistmodel

Singleton {
  id: root

  readonly property string themesRoute: "../themes/"
  readonly property string wallpapersDir: "../wallpapers/"

  // Theme Config
  property string currentThemeId: state.adapter.currentThemeId

  // Colors of the active theme, consumed across the shell.
  property color background: theme.adapter.colors.background
  property color surface: theme.adapter.colors.surface
  property color foreground: theme.adapter.colors.foreground
  property color foregroundSurface: theme.adapter.colors.foregroundSurface
  property color active: theme.adapter.colors.active
  property color secondary: theme.adapter.colors.secondary
  property color disabled: theme.adapter.colors.disabled

  // awww transition used when a theme is applied. Kept here rather than in a
  // config singleton so that Theme has no import cycle with the configs, which
  // read colors from it.
  property string wallpaperTransition: "wipe"
  property int wallpaperTransitionFps: 60
  property string wallpaperTransitionDuration: "1"

  // ---------------------------------------------------------------- index --

  // Every themes/*.json becomes one entry, so dropping a new theme file in is
  // all it takes to have it appear in the switcher.
  FolderListModel {
    id: themeFiles
    folder: Qt.resolvedUrl(root.themesRoute)
    nameFilters: ["*.json"]
    showDirs: false
    sortField: FolderListModel.Name
  }

  readonly property int themeCount: themeIndex.count

  Instantiator {
    id: themeIndex

    model: themeFiles

    delegate: QtObject {
      id: entry

      required property string fileBaseName
      required property string filePath

      readonly property string themeId: entry.fileBaseName
      readonly property string name: entry.view.adapter ? entry.view.adapter.name : ""
      readonly property string wallpaper: entry.view.adapter ? entry.view.adapter.wallpaper : ""
      readonly property var colors: entry.view.adapter ? entry.view.adapter.colors : null
      readonly property string wallpaperUrl: root.wallpaperUrlFor(entry.wallpaper)

      property FileView view: FileView {
        path: entry.filePath
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
          property string name: ""
          property string wallpaper: ""
          property JsonObject colors: JsonObject {
            property string background: "transparent"
            property string surface: "#000000"
            property string foreground: "#ffffff"
            property string active: "#ffffff"
            property string secondary: "#888888"
            property string disabled: "#666666"
          }
        }
      }
    }
  }

  // Instantiator objects must be read through objectAt(); holding them in a JS
  // array hands back stale references once the model rebuilds.
  function themeAt(index) {
    if (index < 0 || index >= themeIndex.count)
      return null;

    return themeIndex.objectAt(index);
  }

  function indexOfTheme(themeId) {
    for (let i = 0; i < themeIndex.count; i++) {
      if (themeIndex.objectAt(i).themeId === themeId)
        return i;
    }
    return -1;
  }

  function wallpaperPathFor(fileName) {
    return root.wallpapersDir + fileName;
  }

  function wallpaperUrlFor(fileName) {
    const path = root.wallpaperPathFor(fileName);
    return path ? Qt.resolvedUrl(path).toString().replace(/^file:\/\//, "") : "";
  }

  // ---------------------------------------------------------------- state --

  // Current Theme Id Loader
  FileView {
    id: state
    path: Qt.resolvedUrl("../state/current-theme.state.json")
    watchChanges: true
    onFileChanged: reload()

    JsonAdapter {
      property string currentThemeId: "shorekeeper-blue"
    }
  }

  // Finds a Theme using loaded Id
  FileView {
    id: theme
    path: Qt.resolvedUrl(root.themesRoute + root.currentThemeId + ".json")
    watchChanges: true
    onFileChanged: reload()
    blockLoading: true

    JsonAdapter {
      property string name: ""
      property string wallpaper: ""
      property JsonObject colors: JsonObject {
        property string background: "transparent"
        property string surface: "#000"
        property string foreground: "#000"
        property string active: "#000"
        property string secondary: "#000"
        property string disabled: "#000"
        property string foregroundSurface: "#000"
      }
    }
  }

  // --------------------------------------------------------------- apply --

  function delay(ms, callback) {
    var timer = Qt.createQmlObject('import QtQuick 2.0; Timer {}', root);
    timer.interval = ms;
    timer.repeat = false;
    timer.triggered.connect(function () {
      callback();
      timer.destroy(); // Clean up timer object after execution
    });
    timer.start();
  }

  function setTheme(themeId) {
    if (!themeId)
      return;

    state.adapter.currentThemeId = themeId;
    state.writeAdapter();

    delay(10, function () {
      root.applyWallpaper();
      root.applySystemTheme(themeId);
    });
  }

  Process {
    id: wallpaperProcess
  }

  function applyWallpaper() {
    const path = root.wallpaperUrlFor(theme.adapter.wallpaper);
    if (!path)
      return;

    wallpaperProcess.command = ["awww", "img", path, "--transition-type", root.wallpaperTransition, "--transition-fps", String(root.wallpaperTransitionFps), "--transition-duration", root.wallpaperTransitionDuration,];
    wallpaperProcess.running = true;
  }

  // Repaints everything the theme reaches outside quickshell. The script is a
  // dispatcher: it runs every script in scripts/themes/, one per application,
  // so teaching the theme about another program means dropping a file there.
  //
  // Failures are surfaced rather than swallowed. A broken script here is
  // otherwise invisible, because the shell itself has already recoloured and
  // only the other application is left looking wrong.
  Process {
    id: systemThemeProcess

    stderr: StdioCollector {
      onStreamFinished: {
        const message = this.text.trim();
        if (message !== "")
          console.warn("apply-theme:", message);
      }
    }
  }

  function applySystemTheme(themeId) {
    if (!themeId)
      return;

    systemThemeProcess.command = [root.scriptPath("apply-theme.bash"), themeId];
    systemThemeProcess.running = true;
  }

  // Resolved relative to this file rather than through $HOME, so the shell can
  // be run from a checkout that is not the installed one. Qt hands back a
  // file:// URL and the process needs a plain path, the same unwrapping
  // wallpaperUrlFor has to do.
  function scriptPath(name) {
    return Qt.resolvedUrl("../scripts/" + name).toString().replace(/^file:\/\//, "");
  }
}
