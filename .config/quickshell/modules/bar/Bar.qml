import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.services as Services
import qs.configurations

PanelWindow {
  id: bar

  anchors {
    right: true
    left: true
    top: true
  }

  color: "transparent"

  // Margins
  margins {
    top: BarConfig.margin[0]
    right: BarConfig.margin[1]
    bottom: BarConfig.margin[2]
    left: BarConfig.margin[3]
  }

  implicitHeight: BarConfig.height

  Rectangle {
    id: background
    anchors.fill: parent
    color: Services.Theme.background

    RowLayout {
      id: leftSection
      anchors {
        left: parent.left
        top: parent.top
        bottom: parent.bottom
      }

      Date {}
    }

    RowLayout {
      id: centerSection
      anchors.centerIn: parent
      height: parent.height
      HyprlandWorkspaces {}
    }

    RowLayout {
      id: rightSection
      anchors {
        right: parent.right
        top: parent.top
        bottom: parent.bottom
      }
      spacing: BarConfig.rightSectionSpacing

      SystemTray {
        Layout.alignment: Qt.AlignVCenter
      }

      Network {
        Layout.alignment: Qt.AlignVCenter
      }

      Audio {
        Layout.alignment: Qt.AlignVCenter
      }

      Battery {
        Layout.alignment: Qt.AlignVCenter
      }
    }
  }
}
