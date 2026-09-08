import Quickshell
import QtQuick

import qs.configurations
import qs.components
import qs.services as Services

// The now-playing widget. It puts itself on screen when both things are true at
// once: the focused workspace is empty, so there is room for it, and something
// is actually playing, so there is anything to say.
//
// Which player that is, and what counts as playing, is Services.MediaPlayer's
// decision; MediaCard draws it; FloatingPanel owns the window and animation.
// What is left here is only the when.
Scope {
  id: root

  readonly property var media: Services.MediaPlayer

  // Whether there is a bare desktop to appear on is Services.Desktop's answer,
  // shared with everything else that only shows up on one.
  readonly property bool shouldShow: Services.Desktop.workspaceEmpty
    && root.media.active

  // Published so that whatever stacks beneath this --- the system stats panel
  // --- can slide down out of its way rather than being covered by it.
  Binding {
    target: Services.Desktop
    property: "mediaVisible"
    value: root.shouldShow
  }

  Binding {
    target: Services.Desktop
    property: "mediaHeight"
    value: panel.panelHeight
  }

  onShouldShowChanged: {
    if (root.shouldShow)
      panel.open();
    else
      panel.close();
  }

  FloatingPanel {
    id: panel

    interactive: false

    panelWidth: MediaConfig.panelWidth
    anchorWidth: MediaConfig.anchorWidth
    panelRadius: MediaConfig.panelRadius
    padding: MediaConfig.panelPadding

    panelColor: MediaConfig.mediaBg

    anchorHeight: BarConfig.workspaceHeight + BarConfig.workspacesTrackPadding * 2

    duration: MediaConfig.animationDuration
    panelNamespace: "quickshell:media"

    anchorY: BarConfig.margin[0] + BarConfig.height + 10

    MediaCard {}
  }
}
