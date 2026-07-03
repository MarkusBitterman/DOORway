pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.common
import qs.services

/**
 * Cartridge-mode switcher — dark (gray NES cart) vs gold (gold LoZ cart).
 * Sets Config appearance.palette.mode, which persists to config.json and drives
 * DoorwayPalette.goldCart → Appearance.m3colors. Replaces the ii-port
 * MaterialThemeLoader, which watched a matugen colors.json DOORway never generates.
 *
 * Auto mode (appearance.palette.autoMode) follows the same sunset/sunrise window
 * as the blue-light filter: gold cart by day, dark cart by night. A manual toggle
 * overrides auto until the next day/night boundary, mirroring Hyprsunset's
 * manualActive semantics.
 *
 * Every mode change also propagates to the freedesktop color-scheme via gsettings,
 * so portal-aware apps (Firefox, GTK, KF6) follow the cartridge.
 */
Singleton {
    id: root

    readonly property bool goldCart: DoorwayPalette.goldCart
    property bool autoMode: (Config.options?.appearance?.palette?.autoMode ?? true) && (Config?.ready ?? true)
    property bool nightNow: Hyprsunset.shouldBeOn
    // undefined, or set by a manual toggle; cleared at the next day/night boundary
    property var manualOverride

    // Singletons are lazily instantiated, and the IpcHandler/GlobalShortcut below
    // only register once the singleton exists. shell.qml calls this at startup.
    function load() {
        root.applyAuto();
        root.propagate();
    }

    onNightNowChanged: {
        root.manualOverride = undefined;
        root.applyAuto();
    }
    onAutoModeChanged: root.applyAuto()
    // Covers every mode-change path (IPC, launcher, config.json load) in one place.
    onGoldCartChanged: root.propagate()

    function applyAuto() {
        if (!root.autoMode || root.manualOverride !== undefined)
            return;
        root.setMode(root.nightNow ? "dark" : "gold");
    }

    // Mirror the cartridge into the system color-scheme; xdg-desktop-portal-gtk
    // serves org.freedesktop.appearance from dconf, so one write reaches all
    // portal-aware apps. dconf (not gsettings) because the session env lacks
    // compiled glib schemas — gsettings fails with "No schemas installed".
    function propagate() {
        const scheme = root.goldCart ? "prefer-light" : "prefer-dark";
        Quickshell.execDetached(["dconf", "write", "/org/gnome/desktop/interface/color-scheme", `'${scheme}'`]);
    }

    function setMode(mode) {
        // Accept the generic light/dark vocabulary used by upstream call sites.
        if (mode === "light") mode = "gold";
        if (mode !== "gold" && mode !== "dark") return;
        Config.options.appearance.palette.mode = mode;
    }

    function toggleLightDark() {
        const mode = root.goldCart ? "dark" : "gold";
        root.manualOverride = mode;
        root.setMode(mode);
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
