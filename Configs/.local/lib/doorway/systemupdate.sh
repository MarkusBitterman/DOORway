#!/usr/bin/env bash
[[ $DOORWAY_SHELL_INIT -ne 1 ]] && eval "$(doorway-shell init)"
notify-send -a "Deprecation Notice" "systemupdate is deprecated. Please use doorway-shell system.update instead." -i dialog-information
"${LIB_DIR}/doorway/system.update.sh" "$@"
