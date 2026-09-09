hl.window_rule({
    name = "spotify",
    match = {
        class = "spotify",
    },
    opacity = "0.85 0.7",
    rounding = 12,
    animation = "fadeIn",
    match = { class = "spotify" }
})

hl.window_rule({
    name = "suppress-maximize-events",
    match = {
        class = ".*",
    },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})

hl.window_rule({
    name = "move-hyprland-run",
    match = {
        class = "hyprland-run",
    },
    move = "20 monitor_h-120",
    float = true,
})
-- ── Fullscreen ───────────────────────────────────────────────────────

hl.window_rule({
  name = "fullscreen-no-effects",
  match = {
    fullscreen = true,
  },
  no_blur = true,
  no_shadow = true,
  no_dim = true,
  no_anim = true,
  rounding = 0,
})

-- ── Games ────────────────────────────────────────────────────────────

hl.window_rule({
  name = "game-tearing",
  match = {
    class = "^(steam_app_\\d+|gamescope|.*\\.exe|osu!|cs2|hl2_linux|factorio)$",
  },
  immediate = true,
})

hl.window_rule({
  name = "steam-client-no-tearing",
  match = {
    class = "^(steam|Steam)$",
  },
  immediate = false,
})
