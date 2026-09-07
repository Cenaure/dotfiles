-- Sourcing files
require("modules.monitors")
require("modules.programs")
require("modules.autostart")
require("modules.env")
require("modules.permissions")
require("modules.decoration")
require("modules.animations")
require("modules.window_rules")
require("modules.layout")
require("modules.misc")
require("modules.input")
require("modules.keybinds")

-- GTK4
hl.exec_cmd('gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"')

-- GTK3
hl.exec_cmd('gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3"')

-- Qt
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")