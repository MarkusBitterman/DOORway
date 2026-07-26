pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import qs.modules.common.models.hyprland

/**
 * DOORway game mode — strips compositor eye-candy (animations, blur, shadows,
 * gaps, rounding) and allows tearing, trading looks for latency.
 *
 * Single source of truth for the feature: the right-sidebar quick toggle
 * (quickToggles/GameModeToggle.qml) and the Super+ALT+G keybind both drive this,
 * so they cannot disagree about the current state.
 *
 * ── Why hyprctl eval, and not the two obvious alternatives ──
 *
 * `hyprctl keyword <option> <value>` does NOT work on a lua config — Hyprland
 * answers "keyword can't work with non-legacy parsers. Use eval." for every
 * option, not just `source`. The retired gamemode.sh was built on it and so
 * never applied anything.
 *
 * HyprlandConfig.setMany() (inherited from end-4's dots, still used by
 * DoorwayCrtShader and HyprlandAntiFlashbangShader) is also a no-op here: it
 * execDetaches scripts/hyprland/hyprconfigurator.py, which was never ported into
 * this tree, writing to ~/.config/hypr/hyprland/shellOverrides/main.lua, a path
 * DOORway does not have and never sources. Failures are silent because
 * execDetached does not report a missing binary.
 *
 * `hyprctl eval` evaluates lua against the live config, which is the supported
 * runtime path for a lua-configured Hyprland and the one the error message
 * points at.
 *
 * Turning OFF reloads the config rather than restoring remembered values: the
 * declared config is the source of truth, so a reload is exact and needs no
 * bookkeeping. Cartridge border colours survive it — ThemeMode persists them to
 * a cache file that dynamic.lua dofiles on reload.
 *
 * State is DERIVED from Hyprland (`animations:enabled` at false is the marker)
 * via HyprlandConfigOption, which reads with `hyprctl getoption -j` and does
 * work. Nothing is stored, so the toggle stays honest if the value changes
 * behind our back.
 *
 * Toggle with:  qs -c doorway ipc --any-display call gameMode toggle
 */
Singleton {
    id: root

    readonly property string applyLua: "hl.config({ " //
    + "animations = { enabled = false }, " //
    + "decoration = { rounding = 0, shadow = { enabled = false }, blur = { enabled = false } }, " //
    + "general = { gaps_in = 0, gaps_out = 0, border_size = 1, allow_tearing = true } " //
    + "})"

    readonly property bool enabled: confOpt.value === false

    // Singletons are lazily instantiated, and the IpcHandler/GlobalShortcut
    // below only register once the singleton exists. shell.qml calls this at
    // startup — without it `qs ipc call gameMode toggle` has no target until
    // something in the UI happens to touch the singleton first.
    function load() {}

    function enable(): void {
        Quickshell.execDetached(["hyprctl", "eval", root.applyLua]);
        // eval does not raise Hyprland's `configreloaded`, so the option cache
        // would keep reporting the stale value; refetch shortly after.
        refetch.restart();
    }

    function disable(): void {
        // Emits configreloaded, which HyprlandConfigOption already listens for.
        Quickshell.execDetached(["hyprctl", "reload", "config-only"]);
    }

    function toggle(): void {
        if (root.enabled)
            root.disable();
        else
            root.enable();
    }

    HyprlandConfigOption {
        id: confOpt
        key: "animations:enabled"
    }

    Timer {
        id: refetch
        interval: 250
        onTriggered: confOpt.fetch()
    }

    GlobalShortcut {
        name: "toggleGameMode"
        description: "Toggle DOORway game mode"
        onPressed: root.toggle()
    }

    IpcHandler {
        target: "gameMode"
        function toggle(): void {
            root.toggle();
        }
        function enable(): void {
            root.enable();
        }
        function disable(): void {
            root.disable();
        }
        function status(): string {
            return root.enabled ? "on" : "off";
        }
    }
}
