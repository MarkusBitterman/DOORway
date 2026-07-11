#!/usr/bin/env bash
# Controller wake for DOORway Lock. Wayland session-lock surfaces only get
# keyboard/pointer from the compositor — gamepads bypass Wayland entirely —
# so DoorwayLock spawns this while locked to watch the joystick device and
# emits "wake" lines on stdout (consumed by a SplitParser in QML; no IPC
# round-trip needed).
#
# CRITICAL: this must exit promptly when quickshell dies. doorway-quickshell
# .service uses systemd ExitType=cgroup, so Restart=always only fires once the
# service cgroup is EMPTY. A child that outlives a SIGKILL'd parent wedges the
# cgroup and blocks crash-recovery restart indefinitely. On clean unlock
# quickshell reaps this Process; on a crash the parent poll below catches it
# within one interval so the cgroup can empty and the shell can relock.
shopt -s nullglob

parent=$PPID
poll=4 # seconds — also bounds how long we linger after the parent dies
alive() { kill -0 "$parent" 2>/dev/null; }

find_pad() {
    local d
    for d in /dev/input/js*; do
        [[ -r $d ]] && printf '%s' "$d" && return 0
    done
    return 1
}

while alive; do
    if ! dev=$(find_pad); then
        sleep "$poll" # no controller yet — it may be plugged in mid-lock
        continue
    fi
    exec 3< "$dev" 2> /dev/null || { sleep "$poll"; continue; }

    # drain the synthetic init-state burst the driver emits on open
    while dd bs=512 count=1 iflag=nonblock <&3 > /dev/null 2>&1; do :; done

    # Read one event, but time-box the blocking read so we periodically
    # re-check parent liveness (an idle controller would otherwise block here
    # forever, never noticing quickshell had died).
    while alive; do
        if timeout "$poll" dd bs=8 count=1 <&3 > /dev/null 2>&1; then
            echo wake
            sleep 1
            # swallow whatever queued during the cooldown (stick wiggle spam)
            while dd bs=512 count=1 iflag=nonblock <&3 > /dev/null 2>&1; do :; done
        else
            # timeout (no input) or device error — rescan if it vanished
            [[ -r $dev ]] || break
        fi
    done

    exec 3<&-
done
