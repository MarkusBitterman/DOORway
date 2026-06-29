--[[
    Animation preset: DOORway Zap
    Dramatic "laser zap in / collapse out" — windows pop into existence from a point with an
    overshoot, and collapse fast to a point on close (a CRT power-off feel). Far beyond the
    default slide/wobble. (True per-pixel disintegration isn't possible on stock Hyprland —
    that's a future custom-plugin spike.)

    Select with: doorway-shell animations --select
--]]

hl.config({
    animations = {
        enabled = true,
        bezier = {
            { "zapIn",       0.15, 1.5, 0.40, 1.0 }, -- fast rise, overshoots past full, settles
            { "collapseOut", 0.55, 0.0, 0.95, 0.25 }, -- eases in then snaps shut
            { "snap",        0.20, 1.0, 0.20, 1.0 }, -- crisp move
        },
        animation = {
            { "windowsIn",   1, 3.2, "zapIn",       "popin 2%" }, -- zap in from a point + overshoot
            { "windowsOut",  1, 2.6, "collapseOut", "popin 2%" }, -- collapse to a point
            { "windowsMove", 1, 4.0, "snap" },
            { "border",      1, 6.0, "default" },
            { "borderangle", 1, 8.0, "default" },
            { "fade",        1, 3.0, "default" }, -- quick fade pairs with the pop/collapse
            { "workspaces",  1, 5.0, "snap",        "slide" },
        },
    },
})
