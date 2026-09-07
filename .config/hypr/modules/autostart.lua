-- #################
-- ### AUTOSTART ###
-- #################

hl.on("hyprland.start", function()
    hl.exec_cmd("vicinae server")
    hl.exec_cmd("~/.config/waybar/scripts/launch.sh")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("udiskie")
end)