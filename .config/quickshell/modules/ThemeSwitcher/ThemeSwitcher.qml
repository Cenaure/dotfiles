import QtQuick

import Quickshell
import Quickshell.Io

import qs.components
import qs.configurations
import qs.services as Services

// Theme switcher, opened over IPC from a Hyprland keybind:
//     qs ipc call themeSwitcher toggle
//
// All of the window, shape and animation work lives in FloatingPanel; this only
// supplies the contents and the key handling.
Scope {
  id: root

  function openSwitcher() {
    const index = Math.max(0, Services.Theme.indexOfTheme(Services.Theme.currentThemeId));

    carousel.currentIndex = index;
    // Deferred: the view needs a width before it can position itself, which it
    // does not have until the panel has been laid out at least once.
    Qt.callLater(() => carousel.positionViewAtIndex(index, ListView.Center));

    panel.open();
  }

  function closeSwitcher() {
    panel.close();
  }

  function applyIndex(index) {
    const entry = Services.Theme.themeAt(index);
    if (entry)
      Services.Theme.setTheme(entry.themeId);

    panel.close();
  }

  IpcHandler {
    target: "themeSwitcher"

    function toggle(): string {
      if (panel.expanded)
        root.closeSwitcher();
      else
        root.openSwitcher();

      return panel.expanded ? "opened" : "closed";
    }

    function open(): string {
      root.openSwitcher();
      return "opened";
    }

    function close(): string {
      root.closeSwitcher();
      return "closed";
    }
  }

  FloatingPanel {
    id: panel

    panelWidth: ThemeSwitcherConfig.panelWidth
    anchorWidth: ThemeSwitcherConfig.anchorWidth
    panelRadius: ThemeSwitcherConfig.panelRadius
    padding: ThemeSwitcherConfig.panelPadding
    panelColor: ThemeSwitcherConfig.bubbleColor
    // Ties the join to the real workspaces pill, so no gap can open up if its
    // height is ever retuned in BarConfig.
    anchorHeight: BarConfig.workspaceHeight + BarConfig.workspacesTrackPadding * 2
    duration: ThemeSwitcherConfig.animationDuration
    panelNamespace: "quickshell:themeSwitcher"

    // Escape is left to FloatingPanel, which closes on it by default.
    onKeyPressed: event => {
      switch (event.key) {
      case Qt.Key_Left:
      case Qt.Key_H:
        carousel.decrementCurrentIndex();
        event.accepted = true;
        break;
      case Qt.Key_Right:
      case Qt.Key_L:
        carousel.incrementCurrentIndex();
        event.accepted = true;
        break;
      case Qt.Key_Return:
      case Qt.Key_Enter:
        root.applyIndex(carousel.currentIndex);
        event.accepted = true;
        break;
      }
    }

    Column {
      id: column

      width: parent.width
      spacing: 16

      ThemeCarousel {
        id: carousel

        width: parent.width
        onActivated: index => root.applyIndex(index)
      }

      ThemePalette {
        width: parent.width
        themeIndex: carousel.currentIndex
      }
    }
  }
}
