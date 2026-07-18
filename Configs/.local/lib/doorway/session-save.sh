#!/usr/bin/env bash
# DOORway session save — snapshot the running clients so session-restore.sh
# can reopen them at the next login (macOS-style "reopen windows").
#
# Run by the doorway-session-save.timer (flake.nix, doorway.session.restore);
# safe to invoke manually right before an intentional reboot.
#
# State: $XDG_STATE_HOME/doorway/session.json
#   { version: 1, clients: [ {pid, class, ws, floating, at, size, cmd} ] }
set -euo pipefail

# Services inherit HYPRLAND_INSTANCE_SIGNATURE via UWSM's import-environment,
# but a manual invocation from a TTY/nested shell may lack it — recover the
# live instance from its runtime socket dir.
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    for d in "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr"/*/; do
        [[ -S "$d.socket.sock" ]] && HYPRLAND_INSTANCE_SIGNATURE=$(basename "$d")
    done
    [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] || exit 0
    export HYPRLAND_INSTANCE_SIGNATURE
fi

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/doorway"
state_file="$state_dir/session.json"
mkdir -p "$state_dir"

# One entry per PROCESS, not per window: a multi-window app (two Firefox
# windows) is one relaunch — the app's own session restore handles its
# window set. Special workspaces (id < 0) are scratchpads, not session state.
rows=$(hyprctl -j clients | jq -c '
    [ .[]
      | select(.pid > 0 and .mapped and .workspace.id >= 1)
      | { pid, class, ws: .workspace.id, floating, at, size } ]
    | group_by(.pid) | map(first) | .[]')

entries=()
while IFS= read -r row; do
    [[ -n "$row" ]] || continue
    pid=$(jq -r '.pid' <<< "$row")
    [[ -r "/proc/$pid/cmdline" ]] || continue
    mapfile -d '' -t argv < "/proc/$pid/cmdline"
    ((${#argv[@]})) || continue

    # Shell infrastructure is restarted by systemd, never by us.
    case "${argv[0]##*/}" in
        quickshell | qs | anyrun | Hyprland | Xwayland) continue ;;
    esac

    # %q-quote each arg so the restore side can hand the string straight to
    # `hyprctl dispatch exec` (which runs it through /bin/sh = bash on NixOS).
    cmd=""
    for a in "${argv[@]}"; do
        cmd+=$(printf '%q ' "$a")
    done
    entries+=("$(jq -c --arg cmd "${cmd% }" '. + { cmd: $cmd }' <<< "$row")")
done <<< "$rows"

# Never clobber a good snapshot with an empty one (e.g. a save firing during
# a not-yet-restored fresh session).
((${#entries[@]})) || exit 0

tmp=$(mktemp "$state_dir/.session.json.XXXXXX")
printf '%s\n' "${entries[@]}" | jq -s '{ version: 1, clients: . }' > "$tmp"
mv "$tmp" "$state_file"
