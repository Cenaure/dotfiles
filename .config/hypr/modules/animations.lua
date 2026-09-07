-- ╔══════════════════════════════════════════════════════════════════╗
-- ║        S H O R E K E E P E R   —   P I A N O   E D I T I O N  ║
-- ║                                                                  ║
-- ║  "Each motion lands like a soft key — immediate, resonant,      ║
-- ║   then fades the way only beautiful things know how to."        ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ── Bezier Curves ────────────────────────────────────────────────────

-- easeOutQuint
hl.curve("ivory", {
    type = "bezier",
    points = {
        { 0.23, 1.00 },
        { 0.32, 1.00 },
    },
})

-- Warmer, slightly softer ease-out
hl.curve("felt", {
    type = "bezier",
    points = {
        { 0.16, 0.80 },
        { 0.25, 1.00 },
    },
})

-- Ease-in
hl.curve("damper", {
    type = "bezier",
    points = {
        { 0.40, 0.00 },
        { 1.00, 1.00 },
    },
})

-- Symmetric ease-in-out
hl.curve("sustain", {
    type = "bezier",
    points = {
        { 0.45, 0.05 },
        { 0.55, 0.95 },
    },
})

-- Balanced natural ease
hl.curve("resonance", {
    type = "bezier",
    points = {
        { 0.25, 0.46 },
        { 0.45, 0.94 },
    },
})

-- Linear
hl.curve("linear", {
    type = "bezier",
    points = {
        { 0.00, 0.00 },
        { 1.00, 1.00 },
    },
})


-- ── Global ───────────────────────────────────────────────────────────

hl.animation({
    leaf = "global",
    enabled = true,
    speed = 10,
    bezier = "default",
})


-- ── Windows ─────────────────────────────────────────────────────────

hl.animation({
    leaf = "windows",
    enabled = true,
    speed = 5.00,
    bezier = "ivory",
})

hl.animation({
    leaf = "windowsIn",
    enabled = true,
    speed = 5.00,
    bezier = "ivory",
    style = "slide",
})

hl.animation({
    leaf = "windowsOut",
    enabled = true,
    speed = 3.00,
    bezier = "damper",
    style = "slide",
})

hl.animation({
    leaf = "windowsMove",
    enabled = true,
    speed = 5.00,
    bezier = "ivory",
})


-- ── Borders ──────────────────────────────────────────────────────────

hl.animation({
    leaf = "border",
    enabled = true,
    speed = 7.00,
    bezier = "sustain",
})

hl.animation({
    leaf = "borderangle",
    enabled = true,
    speed = 6.00,
    bezier = "linear",
})


-- ── Fade ─────────────────────────────────────────────────────────────

hl.animation({
    leaf = "fade",
    enabled = true,
    speed = 4.00,
    bezier = "sustain",
})

hl.animation({
    leaf = "fadeIn",
    enabled = true,
    speed = 3.50,
    bezier = "ivory",
})

hl.animation({
    leaf = "fadeOut",
    enabled = true,
    speed = 3.00,
    bezier = "damper",
})

hl.animation({
    leaf = "fadeDim",
    enabled = true,
    speed = 5.00,
    bezier = "sustain",
})

hl.animation({
    leaf = "fadeShadow",
    enabled = true,
    speed = 4.00,
    bezier = "sustain",
})

hl.animation({
    leaf = "fadeSwitch",
    enabled = true,
    speed = 3.50,
    bezier = "felt",
})


-- ── Layers ───────────────────────────────────────────────────────────

hl.animation({
    leaf = "layers",
    enabled = true,
    speed = 5.00,
    bezier = "ivory",
})

hl.animation({
    leaf = "layersIn",
    enabled = true,
    speed = 5.00,
    bezier = "felt",
    style = "fade",
})

hl.animation({
    leaf = "layersOut",
    enabled = true,
    speed = 3.00,
    bezier = "damper",
    style = "fade",
})

hl.animation({
    leaf = "fadeLayersIn",
    enabled = true,
    speed = 4.00,
    bezier = "ivory",
})

hl.animation({
    leaf = "fadeLayersOut",
    enabled = true,
    speed = 3.00,
    bezier = "damper",
})


-- ── Workspaces ───────────────────────────────────────────────────────

hl.animation({
    leaf = "workspaces",
    enabled = true,
    speed = 6.00,
    bezier = "ivory",
    style = "slide",
})

hl.animation({
    leaf = "workspacesIn",
    enabled = true,
    speed = 6.00,
    bezier = "ivory",
    style = "slide",
})

hl.animation({
    leaf = "workspacesOut",
    enabled = true,
    speed = 6.00,
    bezier = "ivory",
    style = "slide",
})


-- ── Special Workspace (scratchpad) ──────────────────────────────────

hl.animation({
    leaf = "specialWorkspace",
    enabled = true,
    speed = 5.50,
    bezier = "ivory",
    style = "slidevert",
})

hl.animation({
    leaf = "specialWorkspaceIn",
    enabled = true,
    speed = 5.50,
    bezier = "felt",
    style = "slidevert",
})

hl.animation({
    leaf = "specialWorkspaceOut",
    enabled = true,
    speed = 4.00,
    bezier = "damper",
    style = "slidevert",
})


-- ── Zoom ─────────────────────────────────────────────────────────────

hl.animation({
    leaf = "zoomFactor",
    enabled = true,
    speed = 9.00,
    bezier = "resonance",
})