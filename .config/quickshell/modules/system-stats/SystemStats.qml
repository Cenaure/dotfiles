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
// Appears on the same terms as the media panel and stacks under it: when music
// starts, this slides down to make room, and slides back up when it stops. The
// media panel publishes its height to Services.Desktop, which is the only thing
// the two modules share.
Scope {
  id: root

  readonly property var usage: Services.SystemUsage
  readonly property var desktop: Services.Desktop

  readonly property bool shouldShow: root.desktop.workspaceEmpty

  // Top of the stack, level with where the media panel starts.
  readonly property real stackTop: BarConfig.margin[0] + BarConfig.height
    + SystemStatsConfig.topGap

  // Slid down past the media panel when there is one. Animated here rather than
  // in FloatingPanel, whose own position is deliberately not animated --- it
  // has to be able to correct itself silently when the surface is first laid
  // out.
  property real stackY: root.stackTop + (root.desktop.mediaVisible
    ? root.desktop.mediaHeight + SystemStatsConfig.stackSpacing
    : 0)

  Behavior on stackY {
    NumberAnimation {
      duration: SystemStatsConfig.reflowDuration
      easing.type: Easing.OutQuint
    }
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

    anchorY: root.stackY

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
