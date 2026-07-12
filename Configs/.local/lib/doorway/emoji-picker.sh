#!/usr/bin/env bash
#|- emoji-picker.sh - emoji picker (anyrun-dmenu; was rofi -dmenu)
# Recently used entries are tracked in cache and float to the top of the
# input; selection is copied with wl-copy and pasted via paste_string.
anyrun close 2> /dev/null && exit 0
if [[ $DOORWAY_SHELL_INIT -ne 1 ]]; then
    eval "$(doorway-shell init)"
else
    export_doorway_config
fi
emoji_dir=${DOORWAY_DATA_HOME:-$HOME/.local/share/doorway}
emoji_data="$emoji_dir/emoji.db"
cache_dir="${DOORWAY_CACHE_HOME:-$HOME/.cache/doorway}"
recent_data="$cache_dir/landing/show_emoji.recent"
save_recent_entry() {
    local emoji_line="$1"
    {
        echo "$emoji_line"
        cat "$recent_data"
    } | awk '!seen[$0]++' > temp && mv temp "$recent_data"
}
main() {
    if [[ ! -f $recent_data ]]; then
        mkdir -p "$(dirname "$recent_data")"
        echo " Arch linux - I use Arch, BTW" > "$recent_data"
    fi
    data_emoji=$(awk '!seen[$0]++' "$recent_data" "$emoji_data" \
        | "$LIB_DIR/doorway/anyrun-dmenu.sh" -p "🔎 Emoji")
    [[ -z $data_emoji ]] && exit 0
    local selected_emoji_char=""
    selected_emoji_char=$(printf "%s" "$data_emoji" | cut -d' ' -f1 | xargs)
    if [[ -n $selected_emoji_char ]]; then
        wl-copy "$selected_emoji_char"
        save_recent_entry "$data_emoji"
        paste_string "$@"
    fi
}
main "$@"
