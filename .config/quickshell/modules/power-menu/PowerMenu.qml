import QtQuick

import Quickshell
import Quickshell.Io

import qs.components
import qs.configurations

// The power menu, replacing wlogout: three tiles that slide up out of the
// bottom edge. Opened over IPC from a Hyprland keybind:
//     qs ipc call powerMenu toggle
//
// The window, shape and animation all live in FloatingPanel; what is left here
// is the row of tiles, the cursor they share, and the key handling.
Scope {
  id: root

  readonly property var actions: PowerMenuConfig.actions

  // Which tile the keyboard and the pointer are both pointing at. One cursor
  // for both, so moving the mouse and then pressing Return does what the
  // highlight says it will.
  property int selectedIndex: 0

  function openMenu() {
    // Always back to the first tile, so the menu never opens with the cursor
    // left on whatever was last hovered --- on a menu where two of the three
    // choices end your session, where the highlight sits has to be predictable.
    root.selectedIndex = 0;
    panel.open();
  }

  function closeMenu() {
    panel.close();
  }

  function moveSelection(step) {
    const count = root.actions.length;
    root.selectedIndex = (root.selectedIndex + step + count) % count;
  }

  function activate(index) {
    const action = root.actions[index];
    if (!action)
      return;

    // Closed first: poweroff and reboot take a moment to tear the session down,
    // and leaving the menu on screen for it looks like the click missed.
    panel.close();
    Quickshell.execDetached(action.command);
  }

  // The letter that runs an action directly, as wlogout's keybinds do. Returns
  // -1 for anything else.
  function indexForKey(key) {
    for (let i = 0; i < root.actions.length; i++) {
      if (root.actions[i].key === key)
        return i;
    }
    return -1;
  }

  IpcHandler {
    target: "powerMenu"

    function toggle(): string {
      if (panel.expanded)
        root.closeMenu();
      else
        root.openMenu();

      return panel.expanded ? "opened" : "closed";
    }

    function open(): string {
      root.openMenu();
      return "opened";
    }

    function close(): string {
      root.closeMenu();
      return "closed";
    }
  }

  FloatingPanel {
    id: panel

    // Bottom-centred and sliding in from below the edge rather than morphing:
    // there is no bar widget here for a shape to grow out of.
    growUp: true
    slideIn: true
    anchorMargin: PowerMenuConfig.bottomMargin
    panelBottomRadius: PowerMenuConfig.panelBottomRadius
    anchorBottomRadius: PowerMenuConfig.panelBottomRadius
    anchorWidth: PowerMenuConfig.anchorWidth
    anchorHeight: PowerMenuConfig.anchorHeight

    panelWidth: PowerMenuConfig.panelWidth
    panelRadius: PowerMenuConfig.panelRadius
    padding: PowerMenuConfig.panelPadding
    panelColor: PowerMenuConfig.panelColor
    duration: PowerMenuConfig.animationDuration
    panelNamespace: "quickshell:powerMenu"

    // Escape is left to FloatingPanel, which closes on it by default.
    //
    // Deliberately no vim keys for movement: wlogout activates on the letter
    // that names the action, and `l` there means lock. Keeping that costs h/l
    // as arrows, which is the right trade on a menu you use by pressing one
    // letter far more often than by walking across it.
    onKeyPressed: event => {
      const direct = root.indexForKey(event.key);
      if (direct >= 0) {
        root.activate(direct);
        event.accepted = true;
        return;
      }

      switch (event.key) {
      case Qt.Key_Left:
      case Qt.Key_Backtab:
        root.moveSelection(-1);
        event.accepted = true;
        break;
      case Qt.Key_Right:
      case Qt.Key_Tab:
        root.moveSelection(1);
        event.accepted = true;
        break;
      case Qt.Key_Return:
      case Qt.Key_Enter:
        root.activate(root.selectedIndex);
        event.accepted = true;
        break;
      }
    }

    Row {
      id: tiles

      width: parent.width
      spacing: PowerMenuConfig.tileSpacing

      Repeater {
        model: root.actions

        PowerButton {
          required property int index
          required property var modelData

          icon: modelData.icon
          label: modelData.label
          selected: root.selectedIndex === index

          onHovered: root.selectedIndex = index
          onActivated: root.activate(index)
        }
      }
    }
  }
}
