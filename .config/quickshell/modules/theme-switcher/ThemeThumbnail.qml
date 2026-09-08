import QtQuick
import Qt5Compat.GraphicalEffects

import qs.services as Services
import qs.configurations

// One wallpaper preview in the carousel, with its theme's title underneath.
Item {
  id: root

  property int themeIndex: 0
  property bool current: false

  readonly property var entry: Services.Theme.themeAt(root.themeIndex)
  readonly property string themeName: root.entry ? root.entry.name : ""
  readonly property url wallpaperUrl: root.entry ? root.entry.wallpaperUrl : ""
  readonly property bool thumbReady: thumbLoader.item !== null
    && thumbLoader.item.status === Image.Ready
  readonly property bool isApplied: root.entry
    && root.entry.themeId === Services.Theme.currentThemeId

  signal clicked

  implicitWidth: ThemeSwitcherConfig.thumbWidth
  implicitHeight: ThemeSwitcherConfig.thumbHeight
    + ThemeSwitcherConfig.captionSpacing
    + ThemeSwitcherConfig.captionSize + 4

  scale: root.current ? 1 : ThemeSwitcherConfig.thumbInactiveScale
  opacity: root.current ? 1 : ThemeSwitcherConfig.thumbInactiveOpacity

  Behavior on scale {
    NumberAnimation {
      duration: ThemeSwitcherConfig.animationDuration
      easing.type: Easing.OutCubic
    }
  }

  Behavior on opacity {
    NumberAnimation { duration: ThemeSwitcherConfig.animationDuration }
  }

  Item {
    id: frame

    width: ThemeSwitcherConfig.thumbWidth
    height: ThemeSwitcherConfig.thumbHeight
    anchors.horizontalCenter: parent.horizontalCenter

    // The Image is created only once a real URL exists: Quickshell substitutes
    // its qs-blackhole placeholder for an empty source and warns every launch,
    // and the theme index populates asynchronously.
    Loader {
      id: thumbLoader
      anchors.fill: parent
      visible: false
      active: root.wallpaperUrl.toString() !== ""

      sourceComponent: Image {
        // Wallpapers are multi-megapixel; decode them at preview size instead.
        source: root.wallpaperUrl
        sourceSize.width: ThemeSwitcherConfig.thumbWidth * 2
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
      }
    }

    Rectangle {
      id: thumbMask
      anchors.fill: parent
      radius: ThemeSwitcherConfig.thumbRadius
      visible: false
    }

    OpacityMask {
      anchors.fill: parent
      source: thumbLoader
      maskSource: thumbMask
      visible: root.thumbReady
    }

    // Shown when a theme names a wallpaper file that is missing or unreadable,
    // so a broken path degrades to the theme's own colour instead of a gap.
    Rectangle {
      anchors.fill: parent
      radius: ThemeSwitcherConfig.thumbRadius
      visible: !root.thumbReady
      color: root.entry && root.entry.colors
        ? root.entry.colors.surface
        : ThemeSwitcherConfig.bubbleColor

      Text {
        anchors.centerIn: parent
        text: ""
        color: ThemeSwitcherConfig.subtitleColor
        font.family: "AnnotationM Nerd Font Mono"
        font.pixelSize: 20
      }
    }

    Rectangle {
      anchors.fill: parent
      radius: ThemeSwitcherConfig.thumbRadius
      color: "transparent"
      border.width: 2
      border.color: ThemeSwitcherConfig.focusRingColor
      opacity: root.current ? 1 : 0

      Behavior on opacity {
        NumberAnimation { duration: ThemeSwitcherConfig.animationDuration }
      }
    }
  }

  Text {
    anchors {
      top: frame.bottom
      topMargin: ThemeSwitcherConfig.captionSpacing
      horizontalCenter: parent.horizontalCenter
    }
    width: ThemeSwitcherConfig.thumbWidth
    text: root.themeName
    color: root.current
      ? ThemeSwitcherConfig.titleColor
      : ThemeSwitcherConfig.subtitleColor
    font.family: ThemeSwitcherConfig.fontFamily
    font.pixelSize: ThemeSwitcherConfig.captionSize
    font.weight: root.current ? Font.DemiBold : Font.Normal
    horizontalAlignment: Text.AlignHCenter
    elide: Text.ElideRight
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
