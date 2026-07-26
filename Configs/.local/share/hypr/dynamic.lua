--[[
    DOORway dynamic.lua — runtime theme settings, groupbar config,
    post-load exec. Originally dynamic.conf (hyprlang).

    Colors: matugen writes ~/.local/share/matugen/hyprland-colors.lua
    on every wallpaper change (doorway-matugen-watcher.service).
    dynamic.lua dofiles it if present; hyprctl reload propagates the change.
    Groupbar colors follow suit once the file exists.
--]]

local vars = require("variables")

-- // █▀ █▀█ █░█ █▀█ █▀▀ █▀▀
-- // ▄█ █▄█ █▄█ █▀▄ █▄▄ ██▄

local home = os.getenv("HOME")

-- Screen shaders are owned by services/DoorwayCrtShader.qml, which sets
-- `decoration:screen_shader` through HyprlandConfig at runtime. The old
-- hypr/shaders.lua selector and its shaders.sh compiler were removed: both
-- wrote into ~/.config/hypr/shaders/, a read-only Nix store symlink.

-- Cartridge-driven window border colors (dark/gold NES-cart cartridge mode),
-- written by services/ThemeMode.qml on every mode change and at shell
-- startup. This is the default border source — committed DoorwayPalette
-- tokens, not wallpaper-derived — matching the bar corners and sidebars.
-- pcall swallows "file missing" (before QuickShell has started once).
do
    local xdg_cache = os.getenv("XDG_CACHE_HOME") or (home .. "/.cache")
    local cartridge_file = xdg_cache .. "/doorway/hyprland-cartridge-colors.lua"
    local f = io.open(cartridge_file, "r")
    if f then
        f:close()
        pcall(dofile, cartridge_file)
    end
end

-- Matugen-generated colors (Material You palette from current wallpaper).
-- Opt-in only (doorway.theme.matugenBorders.enable): off by default, so
-- doorway-matugen-watcher.service never runs and this file never exists.
-- When enabled it overrides the cartridge colors above — loaded second,
-- last write wins. pcall swallows both "file missing" and any future
-- hl.config() key changes in the generated output.
do
    local xdg_data = os.getenv("XDG_DATA_HOME") or (home .. "/.local/share")
    local colors_file = xdg_data .. "/matugen/hyprland-colors.lua"
    local f = io.open(colors_file, "r")
    if f then
        f:close()
        pcall(dofile, colors_file)
    end
end

-- // █▀▀ █▀█ █▀█ █░█ █▀█ █▄▄ ▄▀█ █▀█
-- // █▄█ █▀▄ █▄█ █▄█ █▀▀ █▄█ █▀█ █▀▄

-- // █▀▀ █▀█ █▄░█ ▀█▀
-- // █▀░ █▄█ █░▀█ ░█░

-- Groupbar — structural config only; colors rely on Hyprland defaults
-- until wallbash → lua port (see header comment + TODO.md).
hl.config({
    group = {
        groupbar = {
            enabled              = true,
            gradients            = 1,
            render_titles        = 1,
            font_weight_inactive = "normal",
            font_weight_active   = "semibold",
            blur                 = true,
            font_size            = vars.FONT_SIZE,
            font_family          = vars.GROUPBAR_FONT,
        },
    },
    misc = {
        font_family = vars.FONT,
    },
})

-- // █▀█ █▀█ █▀▀ █▀█
-- // █▀▀ █▀▄ ██▄ █▀▀

-- $XDG_* references stay literal so hyprland resolves them at exec time.
local mkdir_cmd = "mkdir -p $XDG_RUNTIME_DIR/doorway "
               .. "$XDG_CACHE_HOME/doorway/wallbash "
               .. "$XDG_CONFIG_HOME/doorway "
               .. "$XDG_DATA_HOME/doorway "
               .. "$(dirname $XDG_DATA_HOME)/state/doorway"

local keybinds_hint_cmd = 'bash -c \'eval "$(doorway-shell init)" && '
                       .. '$LIB_DIR/doorway/keybinds/hint-hyprland.py '
                       .. '--format rofi > $XDG_RUNTIME_DIR/doorway/keybinds_hint.cache\''

-- Runtime side-effects: `exec` is not an HL.ConfigKey, so call hl.exec_cmd
-- directly. Re-fires on every config (re)load — matches hyprlang `exec`
-- semantics; mkdir is idempotent and re-generating the keybinds hint on
-- reload is the desired behaviour.
hl.exec_cmd(mkdir_cmd .. " & " .. keybinds_hint_cmd)
