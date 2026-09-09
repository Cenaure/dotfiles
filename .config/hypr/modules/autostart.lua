-- #################
-- ### AUTOSTART ###
-- #################

hl.on("hyprland.start", function()
    hl.exec_cmd("qs")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("udiskie")

    -- The polkit agent udiskie needs to ask for a password. Started through
    -- systemd rather than directly, because that is the unit the package ships
    -- and it is what restarts the agent if it ever dies.
    hl.exec_cmd("systemctl --user start hyprpolkitagent.service")

    -- Feeds cliphist, which the quickshell launcher reads its clipboard
    -- history from. Text and images are separate watchers.
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)