pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.modules.common.models.hyprland

/**
 * DOORway subtle CRT screen shader — toggleable, default OFF.
 *
 * Mirrors HyprlandAntiFlashbangShader: applies its .glsl via Hyprland's decoration:screen_shader
 * at runtime (HyprlandConfig), which is the NixOS-safe path (the hypr/shaders.lua file selector
 * can't be rewritten — it's a read-only Nix store symlink).
 *
 * NOTE: the screen_shader slot is shared with the anti-flashbang shader — only one can be active
 * at a time. Toggle on with:  qs ipc -c doorway --any-display call crtShader toggle
 * (or bind the `toggleCrtShader` global shortcut to a key).
 */
Singleton {
    id: root

    readonly property string shaderPath: Quickshell.shellPath("services/doorwayCrt/doorway-crt.glsl")
    property bool enabled: confOpt.value == shaderPath

    function enable() {
        HyprlandConfig.setMany({
            "decoration:screen_shader": root.shaderPath,
        });
    }

    function disable() {
        HyprlandConfig.resetMany([
            "decoration:screen_shader",
        ]);
    }

    function toggle() {
        if (root.enabled) disable();
        else enable();
    }

    HyprlandConfigOption {
        id: confOpt
        key: "decoration:screen_shader"
    }

    GlobalShortcut {
        name: "toggleCrtShader"
        description: "Toggle the DOORway CRT screen shader"
        onPressed: root.toggle()
    }

    IpcHandler {
        target: "crtShader"
        function toggle(): void { root.toggle(); }
        function enable(): void { root.enable(); }
        function disable(): void { root.disable(); }
    }
}
