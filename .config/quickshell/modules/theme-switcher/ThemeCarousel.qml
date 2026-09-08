import QtQuick

import qs.services as Services
import qs.configurations

// Horizontal strip of wallpaper previews. The focused entry is held in the
// centre by StrictlyEnforceRange, which also lets the first and last entries
// reach the middle without extra margins.
ListView {
  id: root

  signal activated(int index)

  orientation: ListView.Horizontal
  spacing: ThemeSwitcherConfig.thumbSpacing
  clip: true

  implicitHeight: ThemeSwitcherConfig.thumbHeight + ThemeSwitcherConfig.captionSpacing + ThemeSwitcherConfig.captionSize + 4

  model: Services.Theme.themeCount

  preferredHighlightBegin: (root.width - ThemeSwitcherConfig.thumbWidth) / 2
  preferredHighlightEnd: (root.width + ThemeSwitcherConfig.thumbWidth) / 2
  highlightRangeMode: ListView.StrictlyEnforceRange
  snapMode: ListView.SnapToItem
  highlightMoveDuration: ThemeSwitcherConfig.animationDuration
  highlightMoveVelocity: -1

  delegate: ThemeThumbnail {
    required property int index

    themeIndex: index
    current: index === root.currentIndex

    // Clicking a neighbour brings it to the centre; clicking the centred one
    // applies it, so a single click never applies a theme you cannot see.
    onClicked: {
      if (index === root.currentIndex)
        root.activated(index);
      else
        root.currentIndex = index;
    }
  }

  WheelHandler {
    onWheel: event => {
      if (event.angleDelta.y < 0)
        root.incrementCurrentIndex();
      else
        root.decrementCurrentIndex();
    }
  }
}
