import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets

import qs.components
import qs.configurations
import qs.services as Services

// The contents of the media panel: art and track above, a draggable timeline
// through the middle, and a bottom row that pairs the transport controls with a
// badge for whichever app the sound is coming from.
//
// Reads everything from Services.MediaPlayer and holds no state of its own
// except the in-progress drag, which has to override the reported position
// until the seek lands.
Column {
  id: root

  readonly property var media: Services.MediaPlayer

  width: parent.width
  spacing: MediaConfig.sectionSpacing

  Item {
    id: header

    width: parent.width
    height: MediaConfig.artSize

    ClippingRectangle {
      id: art

      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter

      width: MediaConfig.artSize
      height: MediaConfig.artSize
      radius: MediaConfig.artRadius
      color: MediaConfig.artPlaceholderColor

      Image {
        id: cover

        anchors.fill: parent

        source: root.media.artUrl
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        // Decoded at the size it is drawn rather than at whatever the player
        // publishes, which for Spotify is a 640px cover in a 64px box.
        sourceSize.width: MediaConfig.artSize * 2
        sourceSize.height: MediaConfig.artSize * 2

        visible: cover.status === Image.Ready

        WrapperItem {
          anchors.right: parent.right
          height: art.height * 2 - MediaConfig.sourceIconSize
          margin: 4
        }
      }

      // Players that publish no art at all, and the gap while a cover loads.
      Text {
        anchors.centerIn: parent

        visible: !cover.visible
        text: MediaConfig.artFallbackIcon
        font.family: MediaConfig.iconFontFamily
        font.pixelSize: MediaConfig.artFallbackSize
        color: MediaConfig.subtitleColor
      }
    }

    Column {
      anchors.left: art.right
      anchors.leftMargin: MediaConfig.sectionSpacing
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter

      spacing: MediaConfig.textSpacing

      Text {
        width: parent.width

        text: root.media.title || "Nothing playing"
        color: MediaConfig.titleColor
        font.family: MediaConfig.fontFamily
        font.pixelSize: MediaConfig.titleSize
        font.weight: 700
        font.letterSpacing: 0.7
        elide: Text.ElideRight
      }

      Text {
        width: parent.width

        visible: root.media.subtitle !== ""
        text: root.media.subtitle
        color: MediaConfig.subtitleColor
        font.family: MediaConfig.fontFamily
        font.pixelSize: MediaConfig.subtitleSize
        elide: Text.ElideRight
      }

      // Timeline
      Column {
        id: timeline

        // Where the pointer is holding the bar, or -1 when nobody is dragging.
        // While a drag is live this is what the bar shows: the player keeps
        // reporting the old position until the seek actually takes effect, and
        // following that would drag the handle back out from under the pointer.
        property real dragFraction: -1

        readonly property bool dragging: timeline.dragFraction >= 0
        readonly property real fraction: timeline.dragging ? timeline.dragFraction : root.media.progress
        readonly property real shownPosition: timeline.dragging ? timeline.dragFraction * root.media.length : root.media.position

        width: parent.width
        spacing: MediaConfig.timeSpacing

        Item {
          id: track

          width: parent.width
          // Padded out well past the bar itself, so there is something to aim at.
          height: MediaConfig.progressHitHeight

          Rectangle {
            id: groove

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            height: MediaConfig.progressHeight
            radius: MediaConfig.progressRadius
            color: MediaConfig.progressTrackColor
            opacity: MediaConfig.progressTrackOpacity
          }

          Rectangle {
            id: elapsed

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            width: groove.width * timeline.fraction
            height: MediaConfig.progressHeight
            radius: MediaConfig.progressRadius
            color: MediaConfig.progressFillColor

            // Only the once-a-second ticks are smoothed; a drag has to track the
            // pointer exactly, and the jump at the end of a seek is the point.
            Behavior on width {
              enabled: !timeline.dragging
              NumberAnimation {
                duration: root.media.positionInterval
                easing.type: Easing.Linear
              }
            }
          }

          Rectangle {
            id: handle

            anchors.verticalCenter: parent.verticalCenter

            x: Math.min(groove.width - width, Math.max(0, elapsed.width - width / 2))
            width: MediaConfig.progressHandleSize
            height: MediaConfig.progressHandleSize
            radius: width / 2
            color: MediaConfig.progressFillColor

            // Nothing to grab on a track that cannot be seeked.
            visible: root.media.canSeek
            scale: seek.pressed ? 1.3 : 1

            Behavior on scale {
              NumberAnimation {
                duration: MediaConfig.buttonAnimationDuration
                easing.type: Easing.OutCubic
              }
            }
          }

          MouseArea {
            id: seek

            anchors.fill: parent
            enabled: root.media.canSeek
            cursorShape: Qt.PointingHandCursor
            // The panel sits under a full-screen surface with other handlers in it;
            // without this a drag can be taken away mid-gesture.
            preventStealing: true

            function fractionAt(x: real): real {
              if (groove.width <= 0)
                return 0;

              return Math.min(1, Math.max(0, x / groove.width));
            }

            onPressed: event => timeline.dragFraction = seek.fractionAt(event.x)
            onPositionChanged: event => {
              if (seek.pressed)
                timeline.dragFraction = seek.fractionAt(event.x);
            }
            onReleased: event => {
              root.media.seekToFraction(seek.fractionAt(event.x));
              timeline.dragFraction = -1;
            }
            onCanceled: timeline.dragFraction = -1
          }
        }

        Item {
          width: parent.width
          height: positionLabel.implicitHeight

          Text {
            id: positionLabel

            anchors.left: parent.left

            text: root.media.formatTime(timeline.shownPosition)
            color: MediaConfig.timeColor
            font.family: MediaConfig.fontFamily
            font.pixelSize: MediaConfig.timeSize
          }

          Text {
            anchors.right: parent.right

            text: root.media.formatTime(root.media.length)
            color: MediaConfig.timeColor
            font.family: MediaConfig.fontFamily
            font.pixelSize: MediaConfig.timeSize
          }
        }
      }
    }
  }

  // Divider
  Rectangle {
    implicitHeight: 1
    implicitWidth: parent.width
    color: Services.Theme.disabled
    opacity: 0.35
  }

  Item {
    id: footer

    width: parent.width
    height: 32

    RowLayout {
      id: controls

      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter: parent.verticalCenter

      spacing: MediaConfig.buttonSpacing

      MediaButton {
        Layout.alignment: Qt.AlignVCenter

        icon: MediaConfig.previousIcon
        enabled: root.media.canGoPrevious
        onActivated: root.media.previous()
      }

      MediaButton {
        Layout.alignment: Qt.AlignVCenter

        primary: true
        icon: root.media.playing ? MediaConfig.pauseIcon : MediaConfig.playIcon
        enabled: root.media.canTogglePlaying
        onActivated: root.media.togglePlaying()
      }

      MediaButton {
        Layout.alignment: Qt.AlignVCenter

        icon: MediaConfig.nextIcon
        enabled: root.media.canGoNext
        onActivated: root.media.next()
      }
    }
  }
}
