pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.components
import qs.configurations
import qs.services as Services

// Volume in the bar, and the mixer behind it.
//
// The widget itself is the quick controls --- scroll to change the level,
// middle click to mute --- and clicking it opens the manager: output and input
// devices, and a slider per application that is making noise.
Item {
  id: root

  readonly property var audio: Services.Audio

  readonly property string glyph: {
    if (root.audio.muted || root.audio.volume <= 0)
      return AudioConfig.mutedIcon;

    const icons = AudioConfig.volumeIcons;
    const index = Math.min(icons.length - 1,
      Math.max(0, Math.ceil(root.audio.volume * icons.length) - 1));

    return icons[index];
  }

  implicitWidth: content.implicitWidth + BarConfig.workspacesTrackPadding * 2
    + AudioConfig.padding * 2
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
    spacing: AudioConfig.spacing

    Text {
      anchors.verticalCenter: parent.verticalCenter

      text: root.glyph
      font.family: AudioConfig.iconFontFamily
      font.pixelSize: AudioConfig.iconSize
      color: root.audio.muted ? AudioConfig.mutedColor : AudioConfig.color

      Behavior on color {
        ColorAnimation {
          duration: BarConfig.workspacesAnimationDuration
        }
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter

      visible: AudioConfig.showPercent
      text: `${Math.round(root.audio.volume * 100)}%`
      color: root.audio.muted ? AudioConfig.mutedColor : AudioConfig.color
      font.family: AudioConfig.fontFamily
      font.pixelSize: AudioConfig.labelSize
      font.weight: 700
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton

    onClicked: mouse => {
      if (mouse.button === Qt.MiddleButton) {
        root.audio.toggleMute();
        return;
      }

      mixer.toggle();
    }

    // The wheel is the reason to have this in the bar at all: it changes the
    // level without opening anything.
    onWheel: wheel => {
      if (wheel.angleDelta.y === 0)
        return;

      root.audio.nudgeVolume(wheel.angleDelta.y > 0 ? 1 : -1);
    }
  }

  // ----------------------------------------------------------------- mixer --

  BarPopup {
    id: mixer

    anchorItem: root
    popupNamespace: "quickshell:audio"

    Column {
      width: AudioConfig.popupWidth
      spacing: AudioConfig.sectionSpacing

      // ---------------------------------------------------------- output --

      AudioSection {
        width: parent.width

        label: AudioConfig.outputLabel
        node: root.audio.sink
        icon: root.audio.muted ? AudioConfig.mutedIcon : AudioConfig.outputIcon
        devices: root.audio.sinks

        onSelected: device => root.audio.selectSink(device)
        onMuteToggled: root.audio.toggleMute()
        onLevelChanged: level => root.audio.setVolumeOf(root.audio.sink, level)
      }

      // ----------------------------------------------------------- input --

      AudioSection {
        width: parent.width

        visible: root.audio.sources.length > 0
        label: AudioConfig.inputLabel
        node: root.audio.source
        icon: root.audio.inputMuted ? AudioConfig.micMutedIcon : AudioConfig.micIcon
        devices: root.audio.sources

        onSelected: device => root.audio.selectSource(device)
        onMuteToggled: root.audio.toggleInputMute()
        onLevelChanged: level => root.audio.setVolumeOf(root.audio.source, level)
      }

      // ------------------------------------------------------------ apps --

      Column {
        width: parent.width
        spacing: AudioConfig.rowSpacing

        Text {
          text: AudioConfig.appsLabel
          color: AudioConfig.sectionLabelColor
          font.family: AudioConfig.fontFamily
          font.pixelSize: AudioConfig.sectionLabelSize
          font.weight: 700
        }

        // Applications come and go as they start and stop playing, so this is
        // empty as often as not.
        Item {
          width: parent.width
          height: AudioConfig.emptyHeight

          visible: root.audio.streams.length === 0

          Text {
            anchors.left: parent.left
            anchors.leftMargin: AudioConfig.rowPadding
            anchors.verticalCenter: parent.verticalCenter

            text: AudioConfig.emptyText
            color: AudioConfig.detailColor
            font.family: AudioConfig.fontFamily
            font.pixelSize: AudioConfig.nameSize
          }
        }

        Repeater {
          model: root.audio.streams

          delegate: Item {
            id: stream

            required property var modelData

            width: parent.width
            height: streamName.implicitHeight + AudioConfig.sliderHitHeight

            AppIcon {
              id: streamIcon

              anchors.left: parent.left
              anchors.top: parent.top

              windowClass: root.audio.iconKeyOf(stream.modelData)
              font.pixelSize: AudioConfig.rowIconSize
              color: AudioConfig.detailColor
            }

            Text {
              id: streamName

              anchors.left: streamIcon.right
              anchors.leftMargin: AudioConfig.rowSpacing
              anchors.right: streamMute.left
              anchors.rightMargin: AudioConfig.rowSpacing
              anchors.top: parent.top

              text: root.audio.labelOf(stream.modelData)
              color: AudioConfig.nameColor
              font.family: AudioConfig.fontFamily
              font.pixelSize: AudioConfig.nameSize
              elide: Text.ElideRight
            }

            IconButton {
              id: streamMute

              anchors.right: parent.right
              anchors.top: parent.top

              implicitWidth: AudioConfig.muteButtonSize
              implicitHeight: AudioConfig.muteButtonSize

              icon: stream.modelData.audio?.muted
                ? AudioConfig.mutedIcon
                : AudioConfig.volumeIcons[AudioConfig.volumeIcons.length - 1]
              iconSize: AudioConfig.muteIconSize
              fontFamily: AudioConfig.iconFontFamily
              iconColor: stream.modelData.audio?.muted
                ? AudioConfig.detailColor
                : AudioConfig.nameColor
              hoverIconColor: AudioConfig.sliderFillColor

              onActivated: root.audio.setMutedOf(stream.modelData,
                !stream.modelData.audio?.muted)
            }

            LevelSlider {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom

              value: stream.modelData.audio?.volume ?? 0
              enabled: !(stream.modelData.audio?.muted ?? false)

              onMoved: level => root.audio.setVolumeOf(stream.modelData, level)
            }
          }
        }
      }

      // ----------------------------------------------------------- mixer --

      // Everything this panel deliberately does not do --- routing, moving an
      // application to another device, latency --- lives in the real mixer.
      Rectangle {
        width: parent.width
        height: AudioConfig.rowHeight
        radius: AudioConfig.rowRadius

        color: mixerPointer.containsMouse
          ? BarConfig.popupRowHoverColor
          : "transparent"

        Behavior on color {
          ColorAnimation {
            duration: BarConfig.popupAnimationDuration / 2
          }
        }

        Text {
          id: mixerGlyph

          anchors.left: parent.left
          anchors.leftMargin: AudioConfig.rowPadding
          anchors.verticalCenter: parent.verticalCenter

          text: AudioConfig.mixerIcon
          font.family: AudioConfig.iconFontFamily
          font.pixelSize: AudioConfig.rowIconSize
          color: AudioConfig.detailColor
        }

        Text {
          anchors.left: mixerGlyph.right
          anchors.leftMargin: AudioConfig.rowSpacing
          anchors.verticalCenter: parent.verticalCenter

          text: AudioConfig.mixerLabel
          color: AudioConfig.nameColor
          font.family: AudioConfig.fontFamily
          font.pixelSize: AudioConfig.nameSize
        }

        MouseArea {
          id: mixerPointer

          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor

          onClicked: {
            root.audio.openExternalMixer();
            mixer.close();
          }
        }
      }
    }
  }
}
