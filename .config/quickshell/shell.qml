import Quickshell
import QtQuick
import "modules/bar"
import "modules/theme-switcher"
import "modules/app-launcher"

ShellRoot {
  id: root

  Bar {}
  ThemeSwitcher {}
  AppLauncher {}

}
