pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

import qs.modules.common.models.hyprland
import qs.services

/**
 * DOORway game mode — strips compositor eye-candy (animations, blur, shadows,
 * gaps, rounding) and allows tearing, trading looks for latency.
 *
 * Single source of truth for the feature: the right-sidebar quick toggle
 * (quickToggles/GameModeToggle.qml) and the Super+ALT+G keybind both drive this,
 * so they cannot disagree about the current state.
 *
 * Applies through HyprlandConfig, which runs `hyprctl eval` against the live lua
 * config. The retired gamemode.sh instead used `hyprctl keyword source ...`;
 * `hyprctl keyword` is refused outright on a lua config, for every option and
 * not only `source`, so it never applied anything.
 *
 * Turning OFF goes through resetMany, i.e. a config reload: the declared config
 * is the source of truth, so that reverts exactly with no bookkeeping. Cartridge
 * border colours survive it (ThemeMode persists them to a file dynamic.lua
 * dofiles).
 *
 * State is DERIVED from Hyprland — `animations:enabled` at false is the marker —
 * via HyprlandConfigOption, which reads with `hyprctl getoption -j` and refetches
 * on HyprlandConfig's `reloaded` signal. Nothing is stored, so the toggle stays
 * honest if the value changes behind our back.
 *
 * Toggle with:  qs -c doorway ipc --any-display call gameMode toggle
 */
Singleton {
    id: root

    readonly property var overrides: ({
            "animations:enabled": false,
            "decoration:shadow:enabled": false,
            "decoration:blur:enabled": false,
            "decoration:rounding": 0,
            "general:gaps_in": 0,
            "general:gaps_out": 0,
            "general:border_size": 1,
            "general:allow_tearing": true
        })

    readonly property bool enabled: confOpt.value === false

    // Singletons are lazily instantiated, and the IpcHandler/GlobalShortcut
    // below only register once the singleton exists. shell.qml calls this at
    // startup — without it `qs ipc call gameMode toggle` has no target until
    // something in the UI happens to touch the singleton first.
    function load() {}

    function enable(): void {
        HyprlandConfig.setMany(root.overrides);
    }

    function disable(): void {
        HyprlandConfig.resetMany(Object.keys(root.overrides));
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
