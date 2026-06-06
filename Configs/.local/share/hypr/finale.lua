--[[
    DOORway finale.lua — exposes theme metadata as doorway:* keywords
    for fast hyprctl querying. Must be loaded LAST in the chain.
    Originally finale.conf (hyprlang).
--]]

local vars = require("variables")

-- doorway:* custom keywords. hl.keyword may emit unknown-keyword warnings;
-- this is the lua equivalent of hyprlang's `# noerror true` block.
local function setkw(k, v)
    pcall(function() hl.keyword("doorway:" .. k, tostring(v)) end)
end

setkw("theme",              os.getenv("DOORWAY_THEME") or "")
setkw("gtk-theme",          vars.GTK_THEME)
setkw("icon-theme",         vars.ICON_THEME)
setkw("color-scheme",       vars.COLOR_SCHEME)
setkw("cursor-theme",       vars.CURSOR_THEME)
setkw("cursor-size",        vars.CURSOR_SIZE)
setkw("font",               vars.FONT)
setkw("font-size",          vars.FONT_SIZE)
setkw("bar-font",           vars.BAR_FONT)
setkw("notification-font",  vars.NOTIFICATION_FONT)
setkw("menu-font",          vars.MENU_FONT)
setkw("document-font",      vars.DOCUMENT_FONT)
setkw("document-font-size", vars.DOCUMENT_FONT_SIZE)
setkw("monospace-font",     vars.MONOSPACE_FONT)
setkw("monospace-font-size",vars.MONOSPACE_FONT_SIZE)
setkw("font-antialiasing",  vars.FONT_ANTIALIASING)
setkw("font-hinting",       vars.FONT_HINTING)
setkw("button-layout",      vars.BUTTON_LAYOUT)
setkw("terminal",           vars.TERMINAL)
setkw("lockscreen",         vars.LOCKSCREEN)
