--[[
    █░█░█ █▀█ █▀█ █▄▀ █▀▀ █░░ █▀█ █░█░█ █▀
    ▀▄▀▄▀ █▄█ █▀▄ █░█ █▀░ █▄▄ █▄█ ▀▄▀▄▀ ▄█

    Workflow Loader
    https://wiki.hypr.land/Configuring/

    DOORway managed — use 'doorway-shell animations --select' to change.
    Scripts update the workflow variable below.
--]]

local workflow = "default"  -- DOORway scripts update this line
require("workflows/" .. workflow)
