import QtQuick
import Quickshell

import qs.services as Services
import qs.components

Item {
  id: root

  implicitWidth: 92
  implicitHeight: parent.height

  property color timeColor: Services.Theme.foreground
  property color dateColor: Services.Theme.foreground

  Poller {
    id: dateTime
    command: "date '+%a, %d %B|%H:%M'"
    interval: 1000
  }

  readonly property var dateParts: dateTime.value ? dateTime.value.split("|") : ["", ""]

  Column {
    anchors.centerIn: parent
    spacing: 0

    Text {
      id: timeLabel
      text: dateParts[1] ?? ""
      width: root.width
      color: root.timeColor
      font.pixelSize: 14
      font.weight: 800
      font.letterSpacing: 1
      horizontalAlignment: Text.AlignHLeft
      verticalAlignment: Text.AlignVCenter
    }

    Text {
      id: dateLabel
      text: dateParts[0] ?? ""
      width: root.width
      color: root.dateColor
      font.pixelSize: 14
      font.weight: 700
      font.letterSpacing: 0.4
      opacity: 0.8
      horizontalAlignment: Text.AlignHLeft
      verticalAlignment: Text.AlignVCenter
    }
  }
}
