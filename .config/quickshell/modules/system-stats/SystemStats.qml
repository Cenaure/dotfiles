// The per-core delegates below read the strip's own geometry, which is an id
// from an outer component and needs the bound scoping rules to be legal.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.components
import qs.configurations
import qs.services as Services

// CPU and memory load, on the bare desktop only.
//
// Sits beside the media card as one row: when music starts this slides left to
// make room for it, and slides back to the middle when it stops. The row is
// centred as a whole, so the only thing the two modules share is whether the
// media card is there at all, which it publishes to Services.Desktop.
Scope {
  id: root

  readonly property var usage: Services.SystemUsage
  readonly property var desktop: Services.Desktop

  readonly property bool shouldShow: root.desktop.workspaceEmpty

  // The row is as wide as what is actually in it, and centred as a whole. With
  // the media card up that is both cards and a gap; without it, just this one.
  readonly property real rowWidth: SystemStatsConfig.panelWidth
    + (root.desktop.mediaVisible
      ? MediaConfig.panelWidth + DesktopConfig.rowSpacing
      : 0)

  // Right half of that row, or dead centre when there is no other half.
  // Animated here rather than in FloatingPanel, whose own position is
  // deliberately not animated --- it has to be able to correct itself silently
  // when the surface is first laid out.
  property real offsetX: (root.rowWidth - SystemStatsConfig.panelWidth) / 2

  Behavior on offsetX {
    NumberAnimation {
      duration: DesktopConfig.reflowDuration
      easing.type: Easing.OutQuint
    }
  }

  // Contributed to the row's resting height. Deliberately contentHeight, not
  // panelHeight: panelHeight already has the row's floor folded into it, and
  // feeding that back would be a loop.
  Binding {
    target: root.desktop
    property: "statsRestingHeight"
    value: panel.contentHeight
  }

  // Reading /proc costs nothing while nobody is looking at the numbers.
  Binding {
    target: root.usage
    property: "tracking"
    value: root.shouldShow
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

    panelWidth: SystemStatsConfig.panelWidth
    anchorWidth: SystemStatsConfig.anchorWidth
    panelRadius: SystemStatsConfig.panelRadius
    padding: SystemStatsConfig.panelPadding

    panelColor: SystemStatsConfig.panelColor

    anchorHeight: BarConfig.workspaceHeight + BarConfig.workspacesTrackPadding * 2

    duration: SystemStatsConfig.animationDuration
    panelNamespace: "quickshell:systemStats"

    // Level with the media card: the two are a row, not a stack.
    anchorY: BarConfig.margin[0] + BarConfig.height + DesktopConfig.topGap
    offsetX: root.offsetX
    minPanelHeight: root.desktop.rowHeight

    Column {
      id: content

      width: parent.width
      spacing: 0

      RowLayout {
        width: parent.width
        spacing: SystemStatsConfig.gaugeSpacing

        UsageGauge {
          Layout.fillWidth: true
          Layout.preferredWidth: 1

          icon: SystemStatsConfig.cpuIcon
          label: "CPU"
          value: root.usage.cpuUsage
          valueText: root.usage.formatPercent(root.usage.cpuUsage)
          valueSuffix: root.usage.hasTemperature
            ? root.usage.formatTemperature(root.usage.temperature)
            : ""
          valueSuffixColor: root.usage.temperature >= SystemStatsConfig.temperatureWarning
            ? SystemStatsConfig.temperatureWarningColor
            : SystemStatsConfig.valueSuffixColor
          detail: root.usage.coreCount > 0
            ? `${root.usage.coreCount} cores`
            : ""
        }

        UsageGauge {
          Layout.fillWidth: true
          Layout.preferredWidth: 1

          icon: SystemStatsConfig.memoryIcon
          label: "RAM"
          value: root.usage.memoryUsage
          valueText: root.usage.formatPercent(root.usage.memoryUsage)
          detail: root.usage.memoryTotal > 0
            ? `${root.usage.formatBytes(root.usage.memoryUsed)} / ${root.usage.formatBytes(root.usage.memoryTotal)}`
            : ""
        }
      }

      // One column per core, so an uneven load --- one core pinned, the rest
      // idle --- is visible where a single average would hide it.
      Item {
        width: parent.width
        height: SystemStatsConfig.coreStripHeight + SystemStatsConfig.coreStripTopMargin

        visible: SystemStatsConfig.showCores && root.usage.coreCount > 0

        Row {
          id: cores

          anchors.left: parent.left
          anchors.right: parent.right
          anchors.bottom: parent.bottom

          spacing: SystemStatsConfig.coreSpacing

          readonly property real columnWidth: {
            const count = root.usage.coreCount;

            if (count <= 0)
              return 0;

            const gaps = SystemStatsConfig.coreSpacing * (count - 1);

            return Math.max(1, (cores.width - gaps) / count);
          }

          Repeater {
            model: root.usage.coreUsage

            delegate: Item {
              id: core

              required property real modelData

              width: cores.columnWidth
              height: SystemStatsConfig.coreStripHeight

              Rectangle {
                anchors.bottom: parent.bottom

                width: parent.width
                height: Math.max(SystemStatsConfig.coreMinHeight,
                  parent.height * Math.min(1, Math.max(0, core.modelData)))
                radius: SystemStatsConfig.coreRadius

                color: SystemStatsConfig.coreColor
                // An idle column is still drawn, just faint, so the strip keeps
                // its shape instead of flickering in and out.
                opacity: SystemStatsConfig.coreIdleOpacity
                  + (1 - SystemStatsConfig.coreIdleOpacity) * Math.min(1, core.modelData * 1.4)

                Behavior on height {
                  NumberAnimation {
                    duration: SystemStatsConfig.animationDuration
                    easing.type: Easing.OutCubic
                  }
                }

                Behavior on opacity {
                  NumberAnimation {
                    duration: SystemStatsConfig.animationDuration
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
