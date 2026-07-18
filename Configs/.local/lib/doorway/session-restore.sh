#!/usr/bin/env bash
# DOORway session restore — reopen the apps recorded by session-save.sh,
# each on the workspace it was on, silently (no workspace switching).
#
# Runs once per session as doorway-session-restore.service (oneshot,
# doorway.session.restore). Apps reopen FRESH — per-app state (tabs,
# buffers) is each app's own session-restore's job. True window-state
# restore waits on ext-session-management-v1 landing in Hyprland.
set -euo pipefail

state_file="${XDG_STATE_HOME:-$HOME/.local/state}/doorway/session.json"
[[ -s "$state_file" ]] || exit 0

if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    for d in "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr"/*/; do
        [[ -S "$d.socket.sock" ]] && HYPRLAND_INSTANCE_SIGNATURE=$(basename "$d")
    done
    [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || exit 0
    export HYPRLAND_INSTANCE_SIGNATURE
fi

# @tsv keeps the field count stable (embedded tabs arrive escaped); cmd is
# last so `read` collects any remainder into it.
jq -r '.clients[] | [.ws, .floating, .at[0], .at[1], .size[0], .size[1], .cmd] | @tsv' \
    "$state_file" |
    while IFS=$'\t' read -r ws floating x y w h cmd; do
        [[ -n "$cmd" ]] || continue
        rules="workspace $ws silent"
        [[ "$floating" == "true" ]] && rules+=";float;move $x $y;size $w $h"
        # This Hyprland evals every dispatch as Lua — a bare `exec ...` is a
        # syntax error. exec_cmd still parses the legacy [rules] prefix.
        # Escape for embedding in a Lua double-quoted string ($cmd is %q-shell-
        # quoted, so it can contain backslashes and quotes but no newlines).
        lua_cmd=${cmd//\\/\\\\}
        lua_cmd=${lua_cmd//\"/\\\"}
        hyprctl dispatch "hl.dsp.exec_cmd(\"[$rules] $lua_cmd\")" > /dev/null || true
        # Stagger launches — 8 GB box; a thundering herd of app starts makes
        # every app slower and can push the session into swap immediately.
        sleep 0.2
    done

exit 0
