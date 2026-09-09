import QtQuick

import qs.configurations

// Resolves a Hyprland window class to a Nerd Font glyph.
//
// Desktop-entry lookup is deliberately not used here: XDG_DATA_DIRS is empty in
// this session, so DesktopEntries resolves nothing, and window classes often
// disagree with icon names anyway (class "codium" -> icon "vscodium"). An
// explicit map in BarConfig is both deterministic and easy to extend.
Text {
  id: root

  property string windowClass: ""

  readonly property string glyph: {
    if (!root.windowClass)
      return BarConfig.defaultAppIcon;

    const icons = BarConfig.appIcons;

    if (icons[root.windowClass] !== undefined)
      return icons[root.windowClass];

    const lower = root.windowClass.toLowerCase();
    if (icons[lower] !== undefined)
      return icons[lower];

    // Substring pass, so "firefox-esr" and "org.telegram.desktop" still land.
    for (const key in icons) {
      if (lower.includes(key))
        return icons[key];
    }

    return BarConfig.defaultAppIcon;
  }

  text: root.glyph
  // The Mono variant, not the proportional one. In the proportional font these
  // icons have a 500-unit advance but ink running out to ~925 units, so they
  // spill to the right of the box Qt centres, throwing them off by up to 3.5px.
  // The Mono glyphs are redrawn to fit the advance (ink offset ~0.00px), at the
  // cost of being smaller, which workspaceIconSize compensates for.
  font.family: "AnnotationM Nerd Font Mono"
  font.pixelSize: BarConfig.workspaceIconSize
  verticalAlignment: Text.AlignVCenter
  horizontalAlignment: Text.AlignHCenter
}
