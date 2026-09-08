local programs = require("modules.programs")

local mainMod = "SUPER"
local terminal = programs.terminal
local fileManager = programs.fileManager
local menu = programs.menu
local themeSwitcher = programs.themeSwitcher

-- Binds declared through this are registered globally *and* remembered, so the
-- "panel" submap at the bottom of this file can re-register the same set. A
-- submap only has the binds it is given, so anything declared with hl.bind
-- directly --- which is to say workspace switching, and nothing else --- goes
-- dead while a panel is open. That is the whole point of the submap.
local universal = {}

local function bind(keys, dispatcher, opts)
    universal[#universal + 1] = { keys = keys, dispatcher = dispatcher, opts = opts }
    return hl.bind(keys, dispatcher, opts)
end

-- Application and window controls
bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
bind(mainMod .. " + Q", hl.dsp.window.close())
bind(mainMod .. " + M", hl.dsp.exec_cmd("wlogout"))
bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
bind(mainMod .. " + P", hl.dsp.window.pseudo({ action = "toggle" }))
bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
bind(mainMod .. " + R", hl.dsp.exec_cmd("~/.config/waybar/scripts/launch.sh"))
bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))

bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd(menu))
bind(mainMod .. " + T", hl.dsp.exec_cmd(themeSwitcher))
    
-- Screenshots
bind("PRINT", hl.dsp.exec_cmd("hyprshot -m window"))
bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m output"))
bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region"))

-- Move focus
bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Switch workspaces (mainMod + [0-9]) and move active window to workspace (mainMod + ALT + [0-9])
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + ALT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Workspace navigation via scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Keyboard layout switch
bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("hyprctl switchxkblayout all next"))

-- Mouse binds: move / resize window by dragging (old bindm)
bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume / brightness keys: repeat while held, work even when screen is locked (old bindel)
bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
bind("XF86KbdBrightnessUp", hl.dsp.exec_cmd("brightnessctl -d asus::kbd_backlight -e4 set 33%+"), { locked = true, repeating = true })
bind("XF86KbdBrightnessDown", hl.dsp.exec_cmd("brightnessctl -d asus::kbd_backlight -e4 set 33%-"), { locked = true, repeating = true })

-- Media player controls: work even when screen is locked, no repeat (old bindl)
bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Entered by components/FloatingPanel.qml when a panel expands and left when it
-- collapses, so that an open app launcher or theme switcher cannot have the
-- workspace pulled out from under it. Everything except workspace switching is
-- replayed in, so the rest of the keyboard behaves normally while a panel is up.
--
-- Escape also resets the submap. That is the way out if quickshell ever dies
-- with a panel open, which would otherwise leave workspace switching dead.
hl.define_submap("panel", function()
    for _, entry in ipairs(universal) do
        hl.bind(entry.keys, entry.dispatcher, entry.opts)
    end

    hl.bind("escape", hl.dsp.submap("reset"))
end)
