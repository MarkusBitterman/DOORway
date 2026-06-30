#!/usr/bin/env bash
#
# rescue-stranded-workspaces.sh — pull workspaces off the phantom HEADLESS-1
# output and back onto a real monitor.
#
# DOORway keeps a persistent HEADLESS-1 virtual output alive so Hyprland never
# reaches the zero-monitor "unsafe state" that segfaults on physical-display
# disconnect (see Configs/.local/share/hypr/startup.lua). The side effect is
# that when the real monitor disconnects, Hyprland relocates its workspaces to
# the only survivor — HEADLESS-1 — and never moves them back on reconnect, so
# windows end up stranded on an output you can't see.
#
# This script is invoked from the `monitor.added` hook in startup.lua: whenever
# a real monitor (re)appears, any workspace currently parked on HEADLESS-1 that
# still holds windows is moved onto it.
#
# Dispatch note: this Hyprland evaluates every `hyprctl dispatch` argument as
# Lua (`return hl.dispatch(<arg>)`), so the move must be expressed through the
# `hl.dsp` DSL rather than the legacy `moveworkspacetomonitor N MON` syntax.

set -euo pipefail

readonly PHANTOM="HEADLESS-1"

# Target monitor: the first enabled, real (non-phantom) output. Prefer an
# explicit name passed as $1 (the just-added monitor), else the focused one,
# else any real monitor.
target="${1:-}"
if [[ -z "$target" || "$target" == "$PHANTOM" ]]; then
    target="$(hyprctl -j monitors \
        | jq -r --arg phantom "$PHANTOM" '
            ([.[] | select(.name != $phantom and (.disabled | not))]) as $real
            | ( $real | map(select(.focused)) | .[0].name )
              // ( $real | .[0].name )
              // empty')"
fi

# No real monitor to rescue onto (only the phantom is up) — nothing to do.
[[ -z "$target" ]] && exit 0

# Workspace ids currently on the phantom that still hold windows.
mapfile -t stranded < <(hyprctl -j workspaces \
    | jq -r --arg phantom "$PHANTOM" \
        '.[] | select(.monitor == $phantom and .windows > 0) | .id')

for ws in "${stranded[@]}"; do
    hyprctl dispatch "hl.dsp.workspace.move({ workspace = ${ws}, monitor = \"${target}\" })" >/dev/null
done
