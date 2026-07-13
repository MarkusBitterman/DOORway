--[[
    DOORway startup.lua — exec-once autostart chain.

    Hyprland 0.55+ lua API: exec-once is not a `hl.config` key. The schema
    in /nix/store/.../hyprland-0.55.2/share/hypr/stubs/hl.meta.lua accepts
    only declarative section keys; unknown keys are silently dropped.
    Side-effects ride lifecycle events instead.

    `hyprland.start` fires once IPC is ready, matching hyprlang exec-once.
--]]

local vars = require("variables")

-- Park the persistent headless output (created below in hyprland.start) far
-- off-canvas. Auto-placement otherwise lands it at (1920,0), directly right of
-- the real screen, where the cursor can slide onto it — and layer-shell
-- launchers (anyrun) open on the FOCUSED monitor, so one triggered while focus
-- sat on the phantom renders invisibly ("nothing happens" on Super+A; the
-- daemon reports "already visible"). A large offset leaves an unbridgeable gap
-- so the cursor can't reach it. Declarative rule, not `hyprctl keyword` (which
-- errors on lua configs — "use eval"); it applies when the output appears. The
-- zero-monitor safety-net role is position-independent.
hl.monitor({ output = "HEADLESS-1", mode = "1920x1080@60", position = "10000x10000", scale = "1" })

hl.on("hyprland.start", function()
    -- Cursor: must run inside hyprland.start so hyprctl IPC is reachable.
    -- Everything else is declarative (flake.nix systemd.user.services.*);
    -- UWSM handles env propagation before Hyprland starts; HALLway-side
    -- services.gnome.gnome-keyring.enable handles the keyring daemon + PAM.
    hl.exec_cmd("hyprctl setcursor " .. vars.CURSOR_THEME .. " " .. tostring(vars.CURSOR_SIZE))

    -- Persistent headless virtual output: prevents Hyprland from entering
    -- "unsafe state" (zero monitors) when the physical display is unplugged.
    -- Without this, onDisconnect → enterUnsafeState → getViewsForWorkspace
    -- segfaults in Hyprland 0.55.x (confirmed across all crash reports).
    hl.exec_cmd("hyprctl output create headless")
end)

-- Reconnect recovery: when the physical monitor disconnects, Hyprland moves its
-- workspaces to the only survivor (the headless output above) and never moves
-- them back on reconnect, stranding windows on an invisible monitor. On every
-- monitor (re)connect, sweep any workspaces parked on HEADLESS-1 back onto the
-- real output. The phantom stays a quiet zero-monitor safety net, nothing more.
hl.on("monitor.added", function(mon)
    -- The callback arg is untyped (fun(...)); accept a monitor table, a bare
    -- name string, or nil. The helper auto-detects the target when no usable
    -- name is passed, so this stays correct regardless of the payload shape.
    local name = (type(mon) == "table" and mon.name) or (type(mon) == "string" and mon) or nil
    if name == "HEADLESS-1" then return end
    hl.exec_cmd("rescue-stranded-workspaces.sh" .. (name and (" " .. name) or ""))
end)
