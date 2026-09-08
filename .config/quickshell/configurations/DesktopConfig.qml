pragma Singleton

import Quickshell
import QtQuick

// Where the widgets that only appear on a bare desktop sit, and how they are
// arranged relative to each other. Shared by modules/media and
// modules/system-stats, which lay out as one row and therefore cannot each keep
// their own idea of the geometry.
Singleton {
  // Gap between the bottom of the bar and the top of the row.
  readonly property int topGap: 10

  // Between the cards in the row.
  readonly property int rowSpacing: 12

  // How long a card takes to slide across when the row's width changes ---
  // which happens when the media card appears or goes away and the rest has to
  // re-centre around it.
  readonly property int reflowDuration: 320
}
