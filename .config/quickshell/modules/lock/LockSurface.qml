import QtQuick
import QtQuick.Effects

import Quickshell

import qs.components
import qs.configurations

// What one screen shows while the session is locked: the desktop wallpaper
// blurred back, the time over it, and the password field.
//
// One of these per monitor. It owns none of the state --- the typed password
// and the attempt in flight live on the shared Auth object handed in --- so
// every screen shows the same field and any of them can finish the login.
Item {
  id: root

  required property var auth

  // The wallpaper the desktop is currently showing, so locking does not change
  // the picture, only what is drawn over it.
  Image {
    id: wallpaper

    anchors.fill: parent
    source: LockConfig.wallpaperUrl ? "file://" + LockConfig.wallpaperUrl : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: false
    // Read by the blur rather than drawn: MultiEffect takes it as a texture.
    visible: false
  }

  // The surface is painted the moment the session locks, well before a
  // wallpaper of any size has decoded. Without something opaque underneath,
  // that gap shows as a flash of whatever the compositor last had.
  Rectangle {
    anchors.fill: parent
    color: LockConfig.dimColor
  }

  MultiEffect {
    anchors.fill: parent
    source: wallpaper

    blurEnabled: true
    blur: LockConfig.backgroundBlur
    blurMax: 64
    autoPaddingEnabled: false

    // Faded up once the image is actually there, so the wallpaper arrives
    // rather than pops.
    opacity: wallpaper.status === Image.Ready ? 1 : 0

    Behavior on opacity {
      NumberAnimation {
        duration: LockConfig.backgroundFadeDuration
        easing.type: Easing.OutCubic
      }
    }
  }

  // Pulls the whole picture down so that text at theme foreground reads over
  // any wallpaper, light or dark.
  Rectangle {
    anchors.fill: parent
    color: LockConfig.dimColor
    opacity: LockConfig.backgroundDim
  }

  Column {
    anchors.centerIn: parent
    spacing: LockConfig.stackSpacing

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: LockConfig.clockSpacing

      SystemClock {
        id: clock
        precision: SystemClock.Minutes
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter

        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: LockConfig.textColor
        font.family: LockConfig.fontFamily
        font.pixelSize: LockConfig.clockSize
        font.weight: 800
        font.letterSpacing: 2
      }

      Text {
        anchors.horizontalCenter: parent.horizontalCenter

        text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
        color: LockConfig.subtleColor
        font.family: LockConfig.fontFamily
        font.pixelSize: LockConfig.dateSize
        font.weight: 700
        font.letterSpacing: 0.4
      }
    }

    Column {
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: LockConfig.messageSpacing

      Item {
        id: fieldSlot

        width: LockConfig.fieldWidth
        height: LockConfig.fieldHeight

        Rectangle {
          id: field

          anchors.fill: parent
          radius: LockConfig.fieldRadius

          color: Qt.rgba(LockConfig.surfaceColor.r, LockConfig.surfaceColor.g, LockConfig.surfaceColor.b, LockConfig.fieldOpacity)
          border.width: LockConfig.fieldBorderWidth
          border.color: input.activeFocus ? LockConfig.accentColor : LockConfig.borderColor
          // The border only comes up to full strength once the field has the
          // keyboard, which is nearly always --- so an unfocused field reads as
          // waiting rather than as broken.
          opacity: input.activeFocus ? 1 : LockConfig.idleBorderOpacity

          Behavior on border.color {
            ColorAnimation {
              duration: LockConfig.fadeDuration
            }
          }

          Behavior on opacity {
            NumberAnimation {
              duration: LockConfig.fadeDuration
            }
          }
        }

        Text {
          id: fieldGlyph

          anchors.left: parent.left
          anchors.leftMargin: LockConfig.fieldPadding
          anchors.verticalCenter: parent.verticalCenter

          text: LockConfig.lockGlyph
          font.family: LockConfig.iconFontFamily
          font.pixelSize: LockConfig.fieldGlyphSize
          color: LockConfig.accentColor
        }

        IconButton {
          id: submit

          anchors.right: parent.right
          anchors.rightMargin: LockConfig.fieldPadding - 6
          anchors.verticalCenter: parent.verticalCenter

          implicitWidth: LockConfig.fieldGlyphSize + 12
          implicitHeight: submit.implicitWidth

          icon: LockConfig.submitGlyph
          iconSize: LockConfig.fieldGlyphSize
          fontFamily: LockConfig.iconFontFamily
          iconColor: LockConfig.subtleColor
          hoverIconColor: LockConfig.accentColor

          // Nothing to submit and nothing to interrupt: hidden while the field
          // is empty and while an attempt is already with PAM.
          opacity: input.text !== "" && !root.auth.busy ? 1 : 0
          enabled: submit.opacity === 1

          onActivated: root.auth.submit()

          Behavior on opacity {
            NumberAnimation {
              duration: LockConfig.fadeDuration
            }
          }
        }

        TextInput {
          id: input

          anchors {
            left: fieldGlyph.right
            leftMargin: LockConfig.fieldSpacing
            right: submit.left
            rightMargin: LockConfig.fieldSpacing
            verticalCenter: parent.verticalCenter
          }

          echoMode: TextInput.Password
          passwordCharacter: "•"
          passwordMaskDelay: 0
          // Inert while PAM is deciding: rejecting a wrong password takes about
          // a second, and anything typed into that gap would be answering a
          // question that has already been asked.
          enabled: !root.auth.busy
          clip: true

          color: LockConfig.textColor
          selectionColor: Qt.rgba(LockConfig.accentColor.r, LockConfig.accentColor.g, LockConfig.accentColor.b, 0.35)
          selectedTextColor: LockConfig.textColor

          font.family: LockConfig.fontFamily
          font.pixelSize: LockConfig.fieldFontSize
          font.weight: 600

          // One way on purpose, and only for edits the user made: Auth is the
          // one holding the password, and it clears it out from under every
          // field on this and every other monitor when an attempt finishes.
          onTextEdited: root.auth.password = input.text

          Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Return:
            case Qt.Key_Enter:
              root.auth.submit();
              event.accepted = true;
              break;
            case Qt.Key_Escape:
              root.auth.clear();
              event.accepted = true;
              break;
            }
          }

          Text {
            anchors.fill: parent
            visible: input.text.length === 0

            text: root.auth.busy ? LockConfig.busyPlaceholder : LockConfig.fieldPlaceholder
            color: LockConfig.subtleColor
            font: input.font
            verticalAlignment: Text.AlignVCenter
          }
        }

        // A rejected password shakes the field. The palette has no error
        // colour, and a red invented here would be the one thing on screen not
        // coming from the theme.
        SequentialAnimation {
          id: shake

          loops: 2
          NumberAnimation {
            target: fieldSlot
            property: "x"
            to: -LockConfig.shakeDistance
            duration: LockConfig.shakeDuration / 4
            easing.type: Easing.OutQuad
          }
          NumberAnimation {
            target: fieldSlot
            property: "x"
            to: LockConfig.shakeDistance
            duration: LockConfig.shakeDuration / 2
            easing.type: Easing.InOutQuad
          }
          NumberAnimation {
            target: fieldSlot
            property: "x"
            to: 0
            duration: LockConfig.shakeDuration / 4
            easing.type: Easing.InQuad
          }
        }
      }

      Text {
        id: messageLabel

        width: LockConfig.fieldWidth
        horizontalAlignment: Text.AlignHCenter

        text: root.auth.message
        color: LockConfig.subtleColor
        font.family: LockConfig.fontFamily
        font.pixelSize: LockConfig.messageSize
        font.weight: 600
        elide: Text.ElideRight

        opacity: root.auth.message !== "" ? 1 : 0

        Behavior on opacity {
          NumberAnimation {
            duration: LockConfig.fadeDuration
          }
        }
      }
    }
  }

  Connections {
    target: root.auth

    // Auth clears the password when an attempt finishes, on every monitor at
    // once. The field follows it rather than the other way round.
    function onPasswordChanged() {
      if (input.text !== root.auth.password)
        input.text = root.auth.password;
    }

    function onRejected() {
      shake.restart();
      // The compositor hands the keyboard to one surface; taking focus back
      // here is what lets you simply retype after a wrong password.
      input.forceActiveFocus();
    }
  }

  Component.onCompleted: input.forceActiveFocus()
}
