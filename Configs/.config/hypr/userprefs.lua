--[[
    █░█ █▀ █▀▀ █▀█   █▀█ █▀█ █▀▀ █▀▀ █▀
    █▄█ ▄█ ██▄ █▀▄   █▀▀ █▀▄ ██▄ █▀░ ▄█

    User Preferences
    https://wiki.hypr.land/Configuring/Variables/

    Set your personal Hyprland configuration here.
    Uncomment and modify settings as needed.
--]]

--------------------------------------------------------------------------------
-- Input Configuration
-- https://wiki.hypr.land/Configuring/Variables/#input
--------------------------------------------------------------------------------

-- On Nix installs, this file is replaced by the generated version from
-- doorway.input options in your home config. Edits here only affect bare installs.
hl.config({
    input = {
        -- kb_layout = "us",        -- set via doorway.keyboard
        -- follow_mouse = 1,
        -- sensitivity = 0,
        -- force_no_accel = false,
        accel_profile      = "flat",       -- doorway.input.accelProfile
        numlock_by_default = true,         -- doorway.input.numlock

        -- Touchpad settings
        -- https://wiki.hypr.land/Configuring/Variables/#touchpad
        touchpad = {
            natural_scroll = false,        -- doorway.input.naturalScroll
        },
    },
    decoration = {
        active_opacity   = 0.9,            -- doorway.input.activeOpacity
        inactive_opacity = 0.75,           -- doorway.input.inactiveOpacity
    },
})

--------------------------------------------------------------------------------
-- Gestures
-- https://wiki.hypr.land/Configuring/Variables/#gestures
--------------------------------------------------------------------------------

hl.config({
    gestures = {
        -- workspace_swipe = true,
        -- workspace_swipe_fingers = 3,
    },
})

--------------------------------------------------------------------------------
-- Miscellaneous
-- https://wiki.hypr.land/Configuring/Variables/#misc
--------------------------------------------------------------------------------

hl.config({
    misc = {
        -- Window swallowing (similar to devour)
        -- enable_swallow = true,
        -- swallow_regex = "(foot|kitty|alacritty|Alacritty|ghostty|Ghostty|org.wezfurlong.wezterm)",
    },
})

--------------------------------------------------------------------------------
-- Ecosystem
--------------------------------------------------------------------------------

hl.config({
    ecosystem = {
        -- Don't show update news on first launch
        -- no_update_news = true,
    },
})
