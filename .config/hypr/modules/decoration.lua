-- #####################
-- ### LOOK AND FEEL ###
-- #####################

hl.config({
    general = {
        gaps_in = 6,
        gaps_out = 10,

        border_size = 1,

        col = {
            active_border = {
                colors = {
                    "rgba(5b7fa6ff)",
                    "rgba(3a5270ff)",
                },
                angle = 135,
            },

            inactive_border = "rgba(2a335055)",
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