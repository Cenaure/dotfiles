pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.components
import qs.configurations
import qs.services as Services

// Connection status in the bar, and the list of wifi networks behind it.
//
// Everything about which connection is being reported, and what can be done to
// it, is Services.Network's; this is the icon and the popup.
Item {
  id: root

  readonly property var net: Services.Network

  readonly property string glyph: {
    if (root.net.wired)
      return NetworkConfig.wiredIcon;

    if (!root.net.wifiEnabled)
      return NetworkConfig.wifiOffIcon;

    if (!root.net.connected)
      return NetworkConfig.offlineIcon;

    const icons = NetworkConfig.wifiIcons;
    const index = Math.min(icons.length - 1,
      Math.max(0, Math.floor(root.net.strength * icons.length)));

    return icons[index];
  }

  readonly property color tint: {
    if (root.net.connecting)
      return NetworkConfig.connectingColor;

    if (!root.net.connected)
      return NetworkConfig.offlineColor;

    return NetworkConfig.color;
  }

  implicitWidth: content.implicitWidth + BarConfig.workspacesTrackPadding * 2
    + NetworkConfig.padding * 2
  implicitHeight: BarConfig.workspaceHeight + BarConfig.workspacesTrackPadding * 2

  // The radio only scans while the list is up.
  Binding {
    target: root.net
    property: "scanning"
    value: popup.expanded
  }

  Rectangle {
    anchors.fill: parent

    radius: height / 2
    color: BarConfig.workspacesTrackColor
    opacity: BarConfig.workspacesTrackOpacity
  }

  Row {
    id: content

    anchors.centerIn: parent
    spacing: NetworkConfig.spacing

    Text {
      anchors.verticalCenter: parent.verticalCenter

      text: root.glyph
      font.family: NetworkConfig.iconFontFamily
      font.pixelSize: NetworkConfig.iconSize
      color: root.tint

      Behavior on color {
        ColorAnimation {
          duration: BarConfig.workspacesAnimationDuration
        }
      }

      // A connection being negotiated is the one state worth animating, since
      // it is the one that is going to change on its own.
      SequentialAnimation on opacity {
        running: root.net.connecting
        loops: Animation.Infinite
        alwaysRunToEnd: true

        NumberAnimation {
          to: 0.4
          duration: 600
          easing.type: Easing.InOutQuad
        }
        NumberAnimation {
          to: 1
          duration: 600
          easing.type: Easing.InOutQuad
        }
      }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter

      visible: NetworkConfig.showLabel
      width: Math.min(implicitWidth, NetworkConfig.labelMaxWidth)
      text: root.net.label
      color: root.tint
      font.family: NetworkConfig.fontFamily
      font.pixelSize: NetworkConfig.labelSize
      font.weight: 700
      elide: Text.ElideRight
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor

    onClicked: popup.toggle()
  }

  // ----------------------------------------------------------------- popup --

  BarPopup {
    id: popup

    anchorItem: root
    // The passphrase field needs the keyboard, so this one asks for focus.
    takesFocus: true
    popupNamespace: "quickshell:network"

    // Which network is being asked for a passphrase, if any. Cleared whenever
    // the popup closes, so it never reopens mid-prompt.
    property var promptFor: null

    onDismissed: popup.promptFor = null

    Column {
      id: panel

      width: NetworkConfig.popupWidth
      spacing: BarConfig.popupPadding / 2

      // ---------------------------------------------------------- header --

      Item {
        width: parent.width
        height: NetworkConfig.headerHeight

        Text {
          anchors.left: parent.left
          anchors.leftMargin: NetworkConfig.rowPadding
          anchors.right: wifiSwitch.left
          anchors.rightMargin: NetworkConfig.rowSpacing
          anchors.verticalCenter: parent.verticalCenter

          text: root.net.label
          color: BarConfig.popupTextColor
          font.family: NetworkConfig.fontFamily
          font.pixelSize: NetworkConfig.headerSize
          font.weight: 700
          elide: Text.ElideRight
        }

        // Wifi on/off. Hidden entirely on a machine with no wifi radio.
        Rectangle {
          id: wifiSwitch

          anchors.right: parent.right
          anchors.rightMargin: NetworkConfig.rowPadding
          anchors.verticalCenter: parent.verticalCenter

          visible: root.net.wifiAvailable
          width: NetworkConfig.switchWidth
          height: NetworkConfig.switchHeight
          radius: height / 2

          color: root.net.wifiEnabled
            ? NetworkConfig.switchOnColor
            : NetworkConfig.switchOffColor

          Behavior on color {
            ColorAnimation {
              duration: BarConfig.popupAnimationDuration
            }
          }

          Rectangle {
            width: NetworkConfig.switchKnob
            height: NetworkConfig.switchKnob
            radius: height / 2
            y: (parent.height - height) / 2
            x: root.net.wifiEnabled
              ? parent.width - width - (parent.height - height) / 2
              : (parent.height - height) / 2

            color: NetworkConfig.switchKnobColor

            Behavior on x {
              NumberAnimation {
                duration: BarConfig.popupAnimationDuration
                easing.type: Easing.OutCubic
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onClicked: root.net.toggleWifi()
          }
        }
      }

      // ------------------------------------------------------------ list --

      ListView {
        id: list

        width: parent.width
        height: Math.min(list.contentHeight, NetworkConfig.listMaxHeight)

        visible: root.net.wifiEnabled && list.count > 0
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        model: root.net.networks

        delegate: Item {
          id: entry

          required property var modelData

          readonly property bool prompting: popup.promptFor === entry.modelData

          width: list.width
          height: NetworkConfig.rowHeight
            + (entry.prompting ? NetworkConfig.passwordHeight + NetworkConfig.rowSpacing : 0)

          Rectangle {
            id: entryRow

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            height: NetworkConfig.rowHeight
            radius: NetworkConfig.rowRadius

            color: entryPointer.containsMouse
              ? BarConfig.popupRowHoverColor
              : "transparent"

            Behavior on color {
              ColorAnimation {
                duration: BarConfig.popupAnimationDuration / 2
              }
            }

            Text {
              id: entryStrength

              anchors.left: parent.left
              anchors.leftMargin: NetworkConfig.rowPadding
              anchors.verticalCenter: parent.verticalCenter

              text: {
                const icons = NetworkConfig.wifiIcons;
                const index = Math.min(icons.length - 1, Math.max(0,
                  Math.floor((entry.modelData.signalStrength ?? 0) * icons.length)));

                return icons[index];
              }
              font.family: NetworkConfig.iconFontFamily
              font.pixelSize: NetworkConfig.rowIconSize
              color: BarConfig.popupTextColor
              opacity: 0.8
            }

            Text {
              anchors.left: entryStrength.right
              anchors.leftMargin: NetworkConfig.rowSpacing
              anchors.right: entryMarks.left
              anchors.rightMargin: NetworkConfig.rowSpacing
              anchors.verticalCenter: parent.verticalCenter

              text: entry.modelData.name
              color: BarConfig.popupTextColor
              font.family: NetworkConfig.fontFamily
              font.pixelSize: NetworkConfig.rowTextSize
              font.weight: entry.modelData.connected ? 700 : 400
              elide: Text.ElideRight
            }

            Row {
              id: entryMarks

              anchors.right: parent.right
              anchors.rightMargin: NetworkConfig.rowPadding
              anchors.verticalCenter: parent.verticalCenter

              spacing: NetworkConfig.rowSpacing / 2

              Text {
                anchors.verticalCenter: parent.verticalCenter

                visible: root.net.isSecured(entry.modelData)
                text: NetworkConfig.lockIcon
                font.family: NetworkConfig.iconFontFamily
                font.pixelSize: NetworkConfig.rowIconSize - 2
                color: BarConfig.popupSubtleColor
              }

              Text {
                anchors.verticalCenter: parent.verticalCenter

                visible: entry.modelData.connected
                text: NetworkConfig.checkIcon
                font.family: NetworkConfig.iconFontFamily
                font.pixelSize: NetworkConfig.rowIconSize
                color: NetworkConfig.connectingColor
              }
            }

            MouseArea {
              id: entryPointer

              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor

              onClicked: {
                const network = entry.modelData;

                if (network.connected) {
                  root.net.disconnect();
                  return;
                }

                // Already configured, or open: nothing to ask for.
                if (!root.net.needsPassword(network)) {
                  root.net.connectTo(network);
                  popup.close();
                  return;
                }

                popup.promptFor = popup.promptFor === network ? null : network;
              }
            }
          }

          // ------------------------------------------------------ prompt --

          Loader {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: entryRow.bottom
            anchors.topMargin: NetworkConfig.rowSpacing
            anchors.leftMargin: NetworkConfig.rowPadding
            anchors.rightMargin: NetworkConfig.rowPadding

            active: entry.prompting
            visible: entry.prompting
            height: NetworkConfig.passwordHeight

            sourceComponent: Rectangle {
              radius: NetworkConfig.passwordRadius
              color: NetworkConfig.passwordBg

              TextInput {
                id: password

                anchors.fill: parent
                anchors.leftMargin: NetworkConfig.rowPadding
                anchors.rightMargin: NetworkConfig.rowPadding

                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: BarConfig.popupTextColor
                font.family: NetworkConfig.fontFamily
                font.pixelSize: NetworkConfig.passwordSize
                clip: true

                focus: true
                Component.onCompleted: password.forceActiveFocus()

                onAccepted: {
                  root.net.connectWithPassword(entry.modelData, password.text);
                  popup.promptFor = null;
                  popup.close();
                }

                Text {
                  anchors.verticalCenter: parent.verticalCenter

                  visible: password.text === ""
                  text: NetworkConfig.passwordPlaceholder
                  color: BarConfig.popupSubtleColor
                  font.family: NetworkConfig.fontFamily
                  font.pixelSize: NetworkConfig.passwordSize
                }
              }
            }
          }
        }
      }

      // ----------------------------------------------------------- empty --

      Item {
        width: parent.width
        height: NetworkConfig.emptyHeight

        visible: !list.visible

        Text {
          anchors.centerIn: parent

          text: root.net.wifiEnabled
            ? NetworkConfig.emptyText
            : NetworkConfig.disabledText
          color: BarConfig.popupSubtleColor
          font.family: NetworkConfig.fontFamily
          font.pixelSize: NetworkConfig.rowTextSize
        }
      }
    }
  }
}
