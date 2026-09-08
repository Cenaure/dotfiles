-- #################
-- ### AUTOSTART ###
-- #################

hl.on("hyprland.start", function()
    hl.exec_cmd("qs")
    hl.exec_cmd("~/.config/waybar/scripts/launch.sh")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("udiskie")

    -- Feeds cliphist, which the quickshell launcher reads its clipboard
    -- history from. Text and images are separate watchers.
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)