--[[
    DOORway default Hyprland settings.

    Originally `defaults.conf` (hyprlang). Hyprland 0.55+ lua migration.

    Covers monitor fallback, decoration, animations, input, layouts, misc,
    xwayland, and floating-window snap. Theme-driven values live in
    dynamic.lua; this file is intentionally static.
--]]

-- // █▀▄▀█ █▀█ █▄░█ █ ▀█▀ █▀█ █▀█
-- // █░▀░█ █▄█ █░▀█ █ ░█░ █▄█ █▀▄

-- Fallback monitor: any output, preferred mode, auto-positioned.
-- See https://wiki.hypr.land/Configuring/Monitors/
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- // █▀ █▀█ █▀▀ █▀▀ █ ▄▀█ █░░
-- // ▄█ █▀▀ ██▄ █▄▄ █ █▀█ █▄▄

hl.config({
    decoration = {
        rounding           = 10,
        dim_special        = 0.3,
        -- active_opacity and inactive_opacity live in userprefs.lua (loads first)
        -- so they can be driven by doorway.input without being overridden here.
        fullscreen_opacity = 1,
        -- Drop shadow: windows sit on the wallpaper like a cartridge label on a
        -- magazine page, so the light is soft and comes from straight above.
        -- No `ignore_window` key — it existed in older Hyprland and is gone in
        -- 0.55, which always clips the shadow to outside the window. That's the
        -- behaviour we want anyway: active_opacity is 0.9, and a shadow drawn
        -- under the window would show through every translucent surface.
        -- Colors are overwritten at runtime by services/ThemeMode.qml
        -- (cartridge-aware: warm brown on gold, near-black on dark); these are
        -- the bare-install and pre-shell-startup fallback.
        shadow = {
            enabled        = true,
            range          = 18,
            render_power   = 3,
            sharp          = false,
            offset         = { 0, 4 },
            scale          = 1.0,
            color          = "rgba(1c1c1ccc)",
            color_inactive = "rgba(1c1c1c80)",
        },
        blur = {
            enabled           = true,
            size              = 6,
            passes            = 3,
            new_optimizations = true,
            ignore_opacity    = true,
            xray              = false,
            special           = true,
        },
    },

    -- // ▄▀█ █▄░█ █ █▀▄▀█ ▄▀█ ▀█▀ █ █▀█ █▄░█
    -- // █▀█ █░▀█ █ █░▀░█ █▀█ ░█░ █ █▄█ █░▀█
    -- Only `animations.enabled` is a valid HL.ConfigKey; bezier curves and
    -- per-leaf animation specs use hl.curve / hl.animation below.
    animations = {
        enabled = true,
    },

    -- // █░░ ▄▀█ █▄█ █▀█ █░█ ▀█▀ █▀
    -- // █▄▄ █▀█ ░█░ █▄█ █▄█ ░█░ ▄█
    dwindle = {
        preserve_split = true,
    },

    master = {
        new_status = "master",
    },

    -- // █▀▄▀█ █ █▀ █▀▀
    -- // █░▀░█ █ ▄█ █▄▄
    misc = {
        vrr                       = 0,
        disable_hyprland_logo     = true,
        disable_splash_rendering  = true,
        force_default_wallpaper   = 0,
        anr_missed_pings          = 5,
        allow_session_lock_restore = true,
    },

    xwayland = {
        force_zero_scaling = true,
    },

    general = {
        gaps_in          = 3,
        gaps_out         = 5,
        border_size      = 2,
        layout           = "dwindle",
        resize_on_border = true,
        snap = {
            enabled = true,
        },
    },
})

-- // █▀▀ █░█ █▀█ █░█ █▀▀ █▀
-- // █▄▄ █▄█ █▀▄ ▀▄▀ ██▄ ▄█
-- Bezier curves: hyprlang `bezier = name, x0, y0, x1, y1` becomes
-- hl.curve(name, {type="bezier", points={{x0,y0},{x1,y1}}}). See the
-- vendored example at /nix/store/.../hyprland-0.55.2/share/hypr/hyprland.lua.
hl.curve("wind",   { type = "bezier", points = { {0.05, 0.9 }, {0.1, 1.05} } })
hl.curve("winIn",  { type = "bezier", points = { {0.1,  1.1 }, {0.1, 1.1 } } })
hl.curve("winOut", { type = "bezier", points = { {0.3, -0.3 }, {0,   1   } } })
hl.curve("liner",  { type = "bezier", points = { {1,    1   }, {1,   1   } } })

-- Animations: hyprlang `animation = leaf, on, speed, curve, [style]` becomes
-- hl.animation({leaf=..., enabled=..., speed=..., bezier=..., style=...}).
hl.animation({ leaf = "windows",     enabled = true, speed = 6,  bezier = "wind",    style = "slide" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 6,  bezier = "winIn",   style = "slide" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 5,  bezier = "winOut",  style = "slide" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5,  bezier = "wind",    style = "slide" })
hl.animation({ leaf = "border",      enabled = true, speed = 1,  bezier = "liner"                    })
hl.animation({ leaf = "borderangle", enabled = true, speed = 30, bezier = "liner",   style = "once"  })
hl.animation({ leaf = "fade",        enabled = true, speed = 10, bezier = "default"                  })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 5,  bezier = "wind"                     })

-- Touchpad gestures. See https://wiki.hypr.land/Configuring/Gestures/
-- Guard: hl.gesture is a Lua-specific binding function; existence check follows the
-- same pattern as hl.source in dynamic.lua — avoids a crash if not yet implemented.
if hl.gesture then
    hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
    hl.gesture({ fingers = 3, direction = "pinchin",    action = "float", action_modifier = "tile" })
    hl.gesture({ fingers = 3, direction = "pinchout",   action = "float", action_modifier = "float" })
end

-- Optional theme override generated by Home Manager into ~/.config/hypr/.
-- Falls back silently to the static values above for non-Nix installs.
local _t_ok, _t = pcall(require, "doorway-theme")
if _t_ok then
    hl.config({
        general = {
            gaps_in     = _t.gaps_in,
            gaps_out    = _t.gaps_out,
            border_size = _t.border_size,
            layout      = _t.layout,
        },
        decoration = {
            rounding = _t.rounding,
            blur = {
                enabled = _t.blur_enabled,
                size    = _t.blur_size,
                passes  = _t.blur_passes,
            },
            -- Keys whose value is nil simply don't exist in a Lua table, so an
            -- older generated doorway-theme.lua (written before these options
            -- existed) leaves the static block above untouched. `offset` is the
            -- exception — it must be a full vec2 or nothing at all.
            shadow = {
                enabled      = _t.shadow_enabled,
                range        = _t.shadow_range,
                render_power = _t.shadow_render_power,
                sharp        = _t.shadow_sharp,
                offset       = _t.shadow_offset_x and _t.shadow_offset_y
                    and { _t.shadow_offset_x, _t.shadow_offset_y } or nil,
            },
        },
    })
end
