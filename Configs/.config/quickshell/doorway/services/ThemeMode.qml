pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.common

/**
 * Cartridge-mode switcher — dark (gray NES cart) vs gold (gold LoZ cart).
 * Sets Config appearance.palette.mode, which persists to config.json and drives
 * DoorwayPalette.goldCart → Appearance.m3colors. Replaces the ii-port
 * MaterialThemeLoader, which watched a matugen colors.json DOORway never generates.
 */
Singleton {
    id: root

    readonly property bool goldCart: DoorwayPalette.goldCart

    // No-op: singletons are lazily instantiated, and the IpcHandler/GlobalShortcut
    // below only register once the singleton exists. shell.qml calls this at startup.
    function load() {}

    function setMode(mode) {
        // Accept the generic light/dark vocabulary used by upstream call sites.
        if (mode === "light") mode = "gold";
        if (mode !== "gold" && mode !== "dark") return;
        Config.options.appearance.palette.mode = mode;
    }

    function toggleLightDark() {
        root.setMode(root.goldCart ? "dark" : "gold");
    }

    GlobalShortcut {
        name: "toggleLightDark"
        description: "Toggle between the dark (gray) and gold cartridge schemes"

        onPressed: {
            root.toggleLightDark();
        }
    }

    IpcHandler {
        target: "theme"

        function toggleLightDark(): void {
            root.toggleLightDark();
        }

        function setMode(mode: string): void {
            root.setMode(mode);
        }

        function getMode(): string {
            return Config.options?.appearance?.palette?.mode ?? "unset";
        }
    }
}
