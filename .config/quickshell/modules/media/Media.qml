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

  // Published so the rest of the row --- the system stats card --- can re-centre
  // around this one rather than being sat on top of.
  Binding {
    target: Services.Desktop
    property: "mediaVisible"
    value: root.shouldShow
  }

  // The desktop row: this card, a gap, then the stats card. The media card only
  // ever appears while the stats card is up, so the row is always both of them
  // and this offset is fixed --- it is the other card that has to move when this
  // one comes and goes.
  readonly property real rowWidth: MediaConfig.panelWidth
    + DesktopConfig.rowSpacing
    + SystemStatsConfig.panelWidth

  // This card's share of the row's resting height. The card reports itself with
  // the transport put away, so hovering grows only this panel.
  Binding {
    target: Services.Desktop
    property: "mediaRestingHeight"
    value: card.restingHeight + panel.padding * 2
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

    anchorY: BarConfig.margin[0] + BarConfig.height + DesktopConfig.topGap

    // Left half of the row, measured from the row being centred as a whole.
    offsetX: (MediaConfig.panelWidth - root.rowWidth) / 2

    // At rest the two cards in the row are the same height; the transport
    // appearing on hover is what makes this one taller than the other.
    minPanelHeight: Services.Desktop.rowHeight

    MediaCard {
      id: card

      // The panel knows about the whole card, padding included; a handler on
      // the contents would leave that padding as a dead border.
      showControls: panel.hovered
    }
  }
}
