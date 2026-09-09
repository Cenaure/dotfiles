import Quickshell
import QtQuick
import QtQuick.Layouts

import "modules/bar"
import "modules/media"
import "modules/theme-switcher"
import "modules/app-launcher"
import "modules/power-menu"
import "modules/keyboard-layout"
import "modules/notifications"
import "modules/system-stats"

ShellRoot {
  id: root

  Bar {}

  Media {}
  SystemStats {}

  ThemeSwitcher {}
  AppLauncher {}
  PowerMenu {}
  LayoutOsd {}

  NotificationPopup {}
  NotificationCenter {}
}
