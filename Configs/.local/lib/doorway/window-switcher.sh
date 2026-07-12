#!/usr/bin/env bash
#|- window-switcher.sh - Super+TAB window switcher (hyprctl → anyrun-dmenu)
# Replaces `rofi -show window` (rofi → anyrun migration). Lists mapped
# windows MRU-first; selecting one focuses it. The window address rides
# along as a hidden ':::' payload field.
[[ $DOORWAY_SHELL_INIT -ne 1 ]] && eval "$(doorway-shell init)"

entries=$(hyprctl clients -j | jq -r '
    [ .[] | select(.mapped and (.hidden | not)) ]
    | sort_by(.focusHistoryID)
    | .[]
    | "[\(.workspace.name)] \(.class) — \(.title):::\(.address)"')
[[ -n $entries ]] || exit 0

selection=$("$LIB_DIR/doorway/anyrun-dmenu.sh" -d 1 <<< "$entries") || exit 0
hyprctl dispatch focuswindow "address:${selection##*:::}"
