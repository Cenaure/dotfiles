pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

// What the shell knows about the bare desktop: whether you are looking at one,
// and what is already sitting on it.
//
// Several widgets appear only on an empty workspace, and they stack down the
// middle of the screen rather than overlapping, so they need one answer to
// "is the desktop showing" and a way to see how much room the widget above has
// taken. Both live here rather than being worked out separately in each module.
Singleton {
  id: root

  // Nothing on the focused workspace, so there is a desktop to decorate.
  readonly property bool workspaceEmpty: {
    const workspace = Hyprland.focusedWorkspace;

    if (!workspace)
      return false;

    return (workspace.toplevels?.values.length ?? 0) === 0;
  }

  // Published by modules/media. The rest of the row reads it to re-centre: the
  // media card is the only part of the row that comes and goes, so its presence
  // is what decides how wide the row is and therefore where everything sits.
  property bool mediaVisible: false

  // What each card in the row asks for when nothing is being hovered, published
  // by its own module. The media card's is its collapsed height --- the
  // transport it reveals on hover is deliberately not counted, so hovering
  // grows that one card rather than the whole row.
  property real mediaRestingHeight: 0
  property real statsRestingHeight: 0

  // The row is as tall as the tallest card in it, and both cards take this as a
  // floor, so they line up at rest whichever of them happens to be taller.
  readonly property real rowHeight: Math.max(root.statsRestingHeight,
    root.mediaVisible ? root.mediaRestingHeight : 0)
}
