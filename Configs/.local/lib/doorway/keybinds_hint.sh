#!/usr/bin/env bash
#|- keybinds_hint.sh - searchable keybinding hints (anyrun-dmenu; was rofi)
# hint-hyprland.py parses `hyprctl binds -j` into
# "display ::: dispatcher ::: arg ::: repeat ::: meta" lines; the picker
# shows the display column and returns the full line so the selected bind
# can be dispatched.
anyrun close 2> /dev/null && exit 0
[[ $DOORWAY_SHELL_INIT -ne 1 ]] && eval "$(doorway-shell init)"
kb_cache="$XDG_RUNTIME_DIR/doorway/keybinds_hint.cache"
[ -f "$kb_cache" ] && {
    trap '${LIB_DIR}/doorway/keybinds/hint-hyprland.py --format rofi > "$kb_cache" && echo "Keybind cache updated" ' EXIT
}
output="$(if
    ! cat "$kb_cache" 2> /dev/null
then
    "${LIB_DIR}/doorway/keybinds/hint-hyprland.py" --format rofi | tee "$kb_cache"
fi)"
wait
if [ -z "$output" ]; then
    notify-send "Keybind Hint" "Initialization failed."
    exit 0
fi
selected=$(echo -e "$output" | "$LIB_DIR/doorway/anyrun-dmenu.sh" -p "⌨️ Keybindings" -d 1)
if [ -z "$selected" ]; then exit 0; fi
dispatch=$(awk -F ':::' '{print $2}' <<< "$selected" | xargs)
arg=$(awk -F ':::' '{print $3}' <<< "$selected" | xargs)
repeat=$(awk -F ':::' '{print $4}' <<< "$selected" | xargs)
RUN() {
    case "$(eval "hyprctl dispatch '$dispatch' '$arg'")" in *"Not enough arguments"*) exec $0 ;; esac
}
if [ -n "$dispatch" ] && [ "$(echo "$dispatch" | wc -l)" -eq 1 ]; then
    if [ "$repeat" = repeat ]; then
        while true; do
            repeat_command=$(echo -e "Repeat" | "$LIB_DIR/doorway/anyrun-dmenu.sh" -p "[Enter] repeat; [ESC] exit")
            if [ "$repeat_command" = "Repeat" ]; then
                RUN
            else
                exit 0
            fi
        done
    else
        RUN
    fi
else
    exec $0
fi
