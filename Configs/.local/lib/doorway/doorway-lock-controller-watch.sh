#!/usr/bin/env bash
# Controller wake for DOORway Lock. Wayland session-lock surfaces only get
# keyboard/pointer from the compositor — gamepads bypass Wayland entirely —
# so DoorwayLock spawns this while locked to watch the joystick device and
# emits "wake" lines on stdout (consumed by a SplitParser in QML; no IPC
# round-trip needed). Exits when the parent Process stops it on unlock.
shopt -s nullglob

find_pad() {
    local d
    for d in /dev/input/js*; do
        [[ -r $d ]] && printf '%s' "$d" && return 0
    done
    return 1
}

while :; do
    if ! dev=$(find_pad); then
        sleep 5 # no controller yet — it may be plugged in mid-lock
        continue
    fi
    exec 3<"$dev" || { sleep 5; continue; }

    # drain the synthetic init-state burst the driver emits on open
    while dd bs=512 count=1 iflag=nonblock <&3 >/dev/null 2>&1; do :; done

    # any byte after that is a human touching the controller
    while dd bs=8 count=1 <&3 >/dev/null 2>&1; do
        echo wake
        sleep 1
        # swallow whatever queued during the cooldown (stick wiggle spam)
        while dd bs=512 count=1 iflag=nonblock <&3 >/dev/null 2>&1; do :; done
    done

    exec 3<&- # device vanished (unplugged) — rescan
done
