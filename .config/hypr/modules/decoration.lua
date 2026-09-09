-- #####################
-- ### LOOK AND FEEL ###
-- #####################

-- Border colours are generated from the active quickshell theme by
-- quickshell/scripts/themes/change-hyprland-colors.bash. The values below are
-- the fallback: if that file has never been generated, or will not load, the
-- config still comes up rather than failing on a missing require.
local defaults = {
    active_border = { "rgba(5b7fa6ff)", "rgba(3a5270ff)" },
    active_border_angle = 135,
    inactive_border = "rgba(2a335055)",
}

local ok, generated = pcall(require, "modules.colors")
local colors = ok and generated or defaults

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 10,

        border_size = 1,

        col = {
            active_border = {
                colors = colors.active_border,
                angle = colors.active_border_angle,
            },

            inactive_border = colors.inactive_border,
        },

        resize_on_border = true,
        allow_tearing = true,

        layout = "dwindle",
    },

    decoration = {
        rounding = 10,
        rounding_power = 5,

        active_opacity = 1.0,
        inactive_opacity = 0.9,

        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },

        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
        },
    },
})