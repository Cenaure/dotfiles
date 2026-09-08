import QtQuick
import Quickshell
import Quickshell.Services.UPower

import qs.configurations

// Charge level, on the same track as the tray and the workspaces.
//
// UPower's display device is the one to read: on a laptop it is the battery, on
// a machine without one it reports nothing present, which is what hides this
// entirely rather than showing a permanent 100%.
Item {
  id: root

  readonly property var device: UPower.displayDevice

  readonly property bool present: (root.device?.isPresent ?? false)
    && (root.device?.isLaptopBattery ?? false)

  // 0..1. UPower reports a percentage, not a fraction.
  readonly property real level: Math.min(1, Math.max(0,
    (root.device?.percentage ?? 0)))

  readonly property bool charging: root.device?.state === UPowerDeviceState.Charging
    || root.device?.state === UPowerDeviceState.PendingCharge

  // Done charging but still plugged in, which UPower reports as its own state
  // rather than as charging. It is not filling, so it does not get the bolt.
  readonly property bool full: root.device?.state === UPowerDeviceState.FullyCharged

  readonly property bool plugged: root.charging || root.full

  readonly property bool low: !root.plugged && root.level <= BarConfig.batteryLowLevel
  readonly property bool critical: !root.plugged
    && root.level <= BarConfig.batteryCriticalLevel

  // The glyph steps through the seven-bar set, so the icon says roughly as much
  // as the number does. Charging, full and empty have their own.
  readonly property string glyph: {
    if (root.charging)
      return BarConfig.batteryChargingIcon;

    if (root.full)
      return BarConfig.batteryFullIcon;

    if (root.critical)
      return BarConfig.batteryAlertIcon;

    const steps = BarConfig.batteryIcons;
    const index = Math.min(steps.length - 1,
      Math.max(0, Math.round(root.level * (steps.length - 1))));

    return steps[index];
  }

  readonly property color tint: {
    if (root.critical)
      return BarConfig.batteryCriticalColor;

    if (root.low)
      return BarConfig.batteryLowColor;

    if (root.plugged)
      return BarConfig.batteryChargingColor;

    return BarConfig.workspaceColor;
  }

  visible: root.present

  implicitWidth: root.visible
    ? content.implicitWidth + BarConfig.workspacesTrackPadding * 2
      + BarConfig.batteryPadding * 2
    : 0
  implicitHeight: BarConfig.workspaceHeight + BarConfig.workspacesTrackPadding * 2

  Rectangle {
    anchors.fill: parent

    radius: height / 2
    color: BarConfig.workspacesTrackColor
    opacity: BarConfig.workspacesTrackOpacity
  }

  Row {
    id: content

    anchors.centerIn: parent
    spacing: BarConfig.batterySpacing

    Text {
      anchors.verticalCenter: parent.verticalCenter

      text: root.glyph
      font.family: BarConfig.batteryIconFontFamily
      font.pixelSize: BarConfig.batteryIconSize
      color: root.tint

      Behavior on color {
        ColorAnimation {
          duration: BarConfig.workspacesAnimationDuration
        }
      }

      // A battery about to die is the one thing in the bar worth being
      // insistent about.
      SequentialAnimation on opacity {
        running: root.critical
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation {
          to: 0.35
          duration: 700
          easing.type: Easing.InOutQuad
        }
        NumberAnimation {
          to: 1
          duration: 700
          easing.type: Easing.InOutQuad
        }
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter

      visible: BarConfig.batteryShowPercent
      text: `${Math.round(root.level * 100)}%`
      color: root.tint
      font.family: BarConfig.fontFamily
      font.pixelSize: BarConfig.batteryTextSize
      font.weight: 700

      Behavior on color {
        ColorAnimation {
          duration: BarConfig.workspacesAnimationDuration
        }
      }
    }
  }
}
