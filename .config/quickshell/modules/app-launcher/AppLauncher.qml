import QtQuick

import Quickshell

import qs.components
import qs.configurations
import qs.services as Services

// The app launcher's view. All of the searching, ranking and launching lives in
// Services.AppLauncher; all of the shape and animation lives in FloatingPanel.
// What is left here is the search field, the result list and the key handling
// that ties them to the service.
//
// Opened over IPC from a Hyprland keybind:
//     qs ipc call appLauncher toggle
Scope {
  id: root

  readonly property var launcher: Services.AppLauncher

  FloatingPanel {
    id: panel

    // Bottom-centred rather than hanging off a bar widget: the panel unfolds
    // upward out of a pill sitting above the bottom edge.
    growUp: true
    // A translation up from below the screen edge, not a morph: there is no bar
    // widget here for a shape to grow out of.
    slideIn: true
    anchorMargin: AppLauncherConfig.bottomMargin
    panelBottomRadius: AppLauncherConfig.panelBottomRadius
    anchorBottomRadius: AppLauncherConfig.panelBottomRadius
    anchorWidth: AppLauncherConfig.anchorWidth
    anchorHeight: AppLauncherConfig.anchorHeight

    panelWidth: AppLauncherConfig.panelWidth
    panelRadius: AppLauncherConfig.panelRadius
    padding: AppLauncherConfig.panelPadding
    panelColor: AppLauncherConfig.panelColor
    duration: AppLauncherConfig.animationDuration
    panelNamespace: "quickshell:appLauncher"

    // Escape and click-outside are handled inside FloatingPanel, so the panel
    // can collapse without the service knowing. Fold that back into the
    // service, which is the single source of truth for whether we are open.
    onExpandedChanged: {
      if (!panel.expanded)
        root.launcher.close();
    }

    Column {
      id: column

      width: parent.width
      spacing: AppLauncherConfig.panelPadding

      Item {
        id: searchRow

        width: parent.width
        height: AppLauncherConfig.searchHeight

        Text {
          id: searchGlyph

          anchors.left: parent.left
          anchors.verticalCenter: parent.verticalCenter

          // Search glass in app mode, clipboard in clipboard mode: the field
          // is the only thing saying which list you are looking at.
          text: root.launcher.mode === "clipboard" ? "\ue14f"  // content_paste
          : "\ue8b6"  // search
          font.family: AppLauncherConfig.iconFontFamily
          font.pixelSize: AppLauncherConfig.searchIconSize
          color: AppLauncherConfig.accentColor
        }

        TextInput {
          id: searchInput

          anchors {
            left: searchGlyph.right
            leftMargin: AppLauncherConfig.searchSpacing
            right: parent.right
            verticalCenter: parent.verticalCenter
          }

          color: AppLauncherConfig.textColor
          selectionColor: AppLauncherConfig.selectionColor
          selectedTextColor: AppLauncherConfig.textColor
          selectByMouse: true
          clip: true

          font.family: AppLauncherConfig.fontFamily
          font.pixelSize: AppLauncherConfig.searchFontSize
          font.weight: 600

          onTextChanged: root.launcher.query = text

          Text {
            anchors.fill: parent
            visible: searchInput.text.length === 0

            text: root.launcher.mode === "clipboard" ? AppLauncherConfig.clipboardPlaceholder : AppLauncherConfig.searchPlaceholder
            color: AppLauncherConfig.captionColor
            font: searchInput.font
            verticalAlignment: Text.AlignVCenter
          }

          // Handled here rather than on the panel: the input has active focus,
          // so it sees every key first and would swallow Return before an outer
          // handler ever ran.
          Keys.onPressed: event => {
            const control = (event.modifiers & Qt.ControlModifier) !== 0;

            switch (event.key) {
            case Qt.Key_Down:
            case Qt.Key_Tab:
              root.launcher.moveSelection(1);
              event.accepted = true;
              break;
            case Qt.Key_Up:
            case Qt.Key_Backtab:
              root.launcher.moveSelection(-1);
              event.accepted = true;
              break;
            case Qt.Key_J:
              if (control) {
                root.launcher.moveSelection(1);
                event.accepted = true;
              }
              break;
            case Qt.Key_K:
              if (control) {
                root.launcher.moveSelection(-1);
                event.accepted = true;
              }
              break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
              root.launcher.activate(root.launcher.selectedIndex);
              event.accepted = true;
              break;
            case Qt.Key_Escape:
              root.launcher.back();
              event.accepted = true;
              break;
            case Qt.Key_Backspace:
              // Nothing left to delete, so the keystroke leaves the mode
              // instead of doing nothing.
              if (searchInput.text === "" && root.launcher.mode !== "apps") {
                root.launcher.back();
                event.accepted = true;
              }
              break;
            }
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 1
        color: AppLauncherConfig.separatorColor
        opacity: AppLauncherConfig.separatorOpacity
      }

      // Fixed height, so the panel is the same size for every query. Sizing it
      // from the ListView's own contentHeight would also feed back on itself: a
      // ListView only instantiates the delegates it can see, so the height it
      // measures depends on the height it was given.
      Item {
        id: resultsArea

        width: parent.width
        height: AppLauncherConfig.listHeight

        ListView {
          id: results

          anchors.fill: parent

          model: root.launcher.results
          currentIndex: root.launcher.selectedIndex

          clip: true
          spacing: AppLauncherConfig.rowSpacing
          boundsBehavior: Flickable.StopAtBounds
          reuseItems: true

          // One capsule that slides between rows, rather than each row lighting
          // up in place.
          highlight: Rectangle {
            radius: AppLauncherConfig.rowRadius
            color: AppLauncherConfig.selectionColor
          }
          highlightMoveDuration: AppLauncherConfig.highlightDuration
          highlightResizeDuration: AppLauncherConfig.highlightDuration
          highlightMoveVelocity: -1
          highlightResizeVelocity: -1

          delegate: AppListEntry {
            width: results.width

            onActivated: index => root.launcher.activate(index)
            onHovered: index => root.launcher.selectedIndex = index
          }

          Connections {
            target: root.launcher

            // Keyboard navigation can walk the cursor out of view; the list
            // does not follow the current item on its own.
            function onSelectedIndexChanged() {
              results.positionViewAtIndex(root.launcher.selectedIndex, ListView.Contain);
            }
          }
        }

        Text {
          id: empty

          anchors.centerIn: parent
          visible: root.launcher.resultCount === 0

          text: root.launcher.mode === "clipboard" ? "Clipboard history is empty" : "No matching applications"
          color: AppLauncherConfig.captionColor
          font.family: AppLauncherConfig.fontFamily
          font.pixelSize: AppLauncherConfig.nameFontSize
        }
      }
    }
  }

  Connections {
    target: root.launcher

    // The service owns the query and blanks it on every mode change, so the
    // field follows it rather than the other way round.
    function onModeChanged() {
      searchInput.text = "";
      searchInput.forceActiveFocus();
    }

    function onIsOpenChanged() {
      if (!root.launcher.isOpen) {
        panel.close();
        return;
      }

      searchInput.text = "";
      panel.open();
      // Deferred: the panel window only becomes visible on this same change,
      // and focus cannot be taken on a surface that is not mapped yet.
      Qt.callLater(() => searchInput.forceActiveFocus());
    }
  }
}
