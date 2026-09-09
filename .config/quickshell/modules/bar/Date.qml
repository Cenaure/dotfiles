import QtQuick
import Quickshell

import qs.services as Services

Item {
  id: root

  implicitWidth: 92
  implicitHeight: parent.height

  property color timeColor: Services.Theme.foreground
  property color dateColor: Services.Theme.foreground

  // The bar shows hours and minutes, so the clock is asked to tick once a
  // minute. It wakes on the minute boundary rather than on an interval, which
  // is both cheaper and the reason the display never sits a second behind.
  //
  // This used to be a Poller running `date` every second: two forks a second,
  // for the whole life of the shell, to recompute a string that changes sixty
  // times less often than it was asked for. Formatting is something QML can do
  // on its own, so nothing needs to be spawned to do it.
  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  readonly property string timeText: Qt.formatDateTime(clock.date, "HH:mm")
  readonly property string dateText: Qt.formatDateTime(clock.date, "ddd, dd MMMM")

  Column {
    anchors.centerIn: parent
    spacing: 0

    Text {
      id: timeLabel
      text: root.timeText
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
      text: root.dateText
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
