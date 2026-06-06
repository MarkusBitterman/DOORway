#!/usr/bin/env bash
[[ $DOORWAY_SHELL_INIT -ne 1 ]] && eval "$(doorway-shell init)"
notify-send -a "Deprecation Notice" "sysmonitor.sh is deprecated. Please use doorway-shell system.monitor open instead." -i dialog-information

"${LIB_DIR}/doorway/system.monitor.sh" "$@"
