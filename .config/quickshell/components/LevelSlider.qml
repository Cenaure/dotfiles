import QtQuick

import qs.configurations

// A horizontal 0..1 slider: click anywhere on the track to jump there, or drag.
//
// While a drag is live the shown value is the pointer's, not the one that comes
// back from whatever is being set --- pipewire rounds what it is given, and
// following that would have the handle twitching out from under the pointer.
Item {
  id: root

  property real value: 0
  // Item.enabled is the switch: setting it false already stops the drag
  // handler underneath, so all this has to add is looking inert.

  // Emitted continuously through a drag, so whatever is listening follows the
  // pointer rather than waiting for it to be let go.
  signal moved(real value)

  property real dragValue: -1

  readonly property bool dragging: root.dragValue >= 0
  readonly property real shownValue: root.dragging
    ? root.dragValue
    : Math.min(1, Math.max(0, root.value))

  implicitHeight: AudioConfig.sliderHitHeight
  opacity: root.enabled ? 1 : AudioConfig.sliderDisabledOpacity

  Rectangle {
    id: groove

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter

    height: AudioConfig.sliderHeight
    radius: height / 2
    color: AudioConfig.sliderTrackColor
    opacity: AudioConfig.sliderTrackOpacity
  }

  Rectangle {
    id: fill

    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter

    width: groove.width * root.shownValue
    height: AudioConfig.sliderHeight
    radius: height / 2
    color: AudioConfig.sliderFillColor

    // Only the steps that arrive on their own are smoothed; a drag has to
    // track the pointer exactly.
    Behavior on width {
      enabled: !root.dragging
      NumberAnimation {
        duration: AudioConfig.sliderAnimationDuration
        easing.type: Easing.OutCubic
      }
    }
  }

  Rectangle {
    id: handle

    anchors.verticalCenter: parent.verticalCenter

    x: Math.min(groove.width - width, Math.max(0, fill.width - width / 2))
    width: AudioConfig.sliderHandleSize
    height: width
    radius: width / 2
    color: AudioConfig.sliderFillColor

    scale: pointer.pressed ? 1.3 : 1

    Behavior on scale {
      NumberAnimation {
        duration: AudioConfig.sliderAnimationDuration
        easing.type: Easing.OutCubic
      }
    }
  }

  MouseArea {
    id: pointer

    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    preventStealing: true

    function valueAt(x: real): real {
      if (groove.width <= 0)
        return 0;

      return Math.min(1, Math.max(0, x / groove.width));
    }

    onPressed: event => {
      root.dragValue = pointer.valueAt(event.x);
      root.moved(root.dragValue);
    }

    onPositionChanged: event => {
      if (!pointer.pressed)
        return;

      root.dragValue = pointer.valueAt(event.x);
      root.moved(root.dragValue);
    }

    onReleased: event => {
      root.moved(pointer.valueAt(event.x));
      root.dragValue = -1;
    }

    onCanceled: root.dragValue = -1
  }
}
