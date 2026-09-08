pragma Singleton

import Quickshell
import QtQuick

import qs.services as Services

Singleton {
  // Offset from the pointer's hotspot. Down and to the right, so the indicator
  // sits clear of the cursor rather than under it.
  readonly property int cursorOffsetX: 18
  readonly property int cursorOffsetY: 22
  // Never let the pill touch a screen edge, however close to one the cursor is.
  readonly property int screenMargin: 8

  // Pill
  readonly property int padding: 6
  readonly property int itemSpacing: 2
  readonly property int itemPaddingX: 9
  readonly property int itemPaddingY: 4
  readonly property int fontSize: 12

  readonly property int fadeDuration: 130

  readonly property color pillColor: Services.Theme.surface
  readonly property color activeColor: Services.Theme.active
  // Sits on the accent capsule, so it contrasts with that rather than the pill.
  readonly property color activeTextColor: Services.Theme.surface
  readonly property color inactiveTextColor: Services.Theme.disabled

  readonly property string fontFamily: "AnnotationM Nerd Font"
}
