#!/usr/bin/env bash
# DOORway Lock launcher — discovered by lockscreen.sh when
# DOORWAY_LOCKSCREEN=doorway-lock. The lock itself lives inside the running
# QuickShell process (WlSessionLock); this wrapper just asks it to engage and
# then verifies it actually did. Never fail open: any doubt → exec hyprlock.
[[ $DOORWAY_SHELL_INIT -ne 1 ]] && eval "$(doorway-shell init)"

fallback() {
    printf 'doorway-lock: %s — falling back to hyprlock\n' "$1" >&2
    exec hyprlock.sh
}

systemctl --user is-active --quiet doorway-quickshell.service ||
    fallback "doorway-quickshell.service not active"

timeout 5 qs -c doorway ipc --any-display call lock lock ||
    fallback "lock IPC call failed"

# trust nothing: confirm the state machine reports engaged before returning
for _ in 1 2 3 4 5 6; do
    status=$(timeout 2 qs -c doorway ipc --any-display call lock status 2>/dev/null)
    if [[ -n $status && $status != inactive ]]; then
        exit 0
    fi
    sleep 0.5
done
fallback "lock did not engage within 3s"
