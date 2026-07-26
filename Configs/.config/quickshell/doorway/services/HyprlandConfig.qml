pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

/**
 * Runtime Hyprland configuration.
 *
 * Rewritten 2026-07-25 onto `hyprctl eval`. The inherited implementation (from
 * end-4's dots) execDetached `scripts/hyprland/hyprconfigurator.py` against
 * `~/.config/hypr/hyprland/shellOverrides/main.lua`. Neither exists in DOORway —
 * the script was never ported and nothing sources that path — and execDetached
 * reports nothing when the binary is missing, so every call was a silent no-op.
 * DoorwayCrtShader and HyprlandAntiFlashbangShader therefore did nothing at all.
 *
 * `hyprctl keyword` is NOT an alternative: on a lua config Hyprland rejects it
 * for every option ("keyword can't work with non-legacy parsers. Use eval."),
 * not just for `source`. `hyprctl eval` runs lua against the live config and is
 * what that error message points at.
 *
 * Keys keep their `section:option` form. Both `:` and `.` are treated as path
 * separators (`general:col.active_border`) and rebuilt into a nested lua table,
 * merged so several keys under one section stay a single table instead of
 * colliding as duplicate keys in the literal.
 */
Singleton {
    id: root

    signal reloaded

    // ── lua serialisation ──

    function luaLiteral(value: var): string {
        if (typeof value === "boolean")
            return value ? "true" : "false";
        if (typeof value === "number")
            return String(value);
        return '"' + String(value).replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"';
    }

    function luaTable(node: var): string {
        const parts = [];
        for (const key in node) {
            const value = node[key];
            const isBranch = value !== null && typeof value === "object";
            parts.push(`${key} = ${isBranch ? `{ ${root.luaTable(value)} }` : root.luaLiteral(value)}`);
        }
        return parts.join(", ");
    }

    // {"decoration:blur:enabled": false, "decoration:rounding": 0}
    //   -> decoration = { blur = { enabled = false }, rounding = 0 }
    function buildTree(entries: var): var {
        const tree = {};
        for (const key in entries) {
            const path = key.split(/[:.]/);
            let node = tree;
            for (let i = 0; i < path.length - 1; i++) {
                if (node[path[i]] === undefined || typeof node[path[i]] !== "object")
                    node[path[i]] = {};
                node = node[path[i]];
            }
            node[path[path.length - 1]] = entries[key];
        }
        return tree;
    }

    // ── api ──

    function set(key: string, value: var): void {
        const entries = {};
        entries[key] = value;
        root.setMany(entries);
    }

    function setMany(entries: var): void {
        const body = root.luaTable(root.buildTree(entries));
        if (body.length === 0)
            return;
        Quickshell.execDetached(["hyprctl", "eval", `hl.config({ ${body} })`]);
        // eval does not raise Hyprland's `configreloaded`, so anything caching an
        // option value (HyprlandConfigOption) would keep reporting the old one.
        // Announce it ourselves once the detached call has had time to land.
        settleTimer.restart();
    }

    /**
     * NOTE: resetting is whole-config, not per-key. Hyprland exposes no way to
     * recover a single option's *declared* value at runtime — `getoption` returns
     * the current one — so the only exact revert is re-reading the config, which
     * restores every declared value at once. The key list stays in the signature
     * for call-site readability. Committed runtime state survives a reload:
     * ThemeMode writes cartridge border colours to a file dynamic.lua dofiles.
     */
    function reset(key: string): void {
        root.resetMany([key]);
    }

    function resetMany(keys: list<string>): void {
        Quickshell.execDetached(["hyprctl", "reload", "config-only"]);
    }

    Timer {
        id: settleTimer
        interval: 250
        onTriggered: root.reloaded()
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name == "configreloaded") {
                root.reloaded();
            }
        }
    }
}
