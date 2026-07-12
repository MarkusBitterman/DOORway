#!/usr/bin/env bash
#|- glyph-picker.sh - nerd-font glyph picker (anyrun-dmenu; was rofi -dmenu)
# Recently used entries are tracked in cache and float to the top of the
# input; selection is copied with wl-copy and pasted via paste_string.
anyrun close 2> /dev/null && exit 0
if [[ $DOORWAY_SHELL_INIT -ne 1 ]]; then
    eval "$(doorway-shell init)"
else
    export_doorway_config
fi
glyph_dir=${DOORWAY_DATA_HOME:-$HOME/.local/share/doorway}
glyph_data="$glyph_dir/glyph.db"
cache_dir="${DOORWAY_CACHE_HOME:-$HOME/.cache/doorway}"
recent_data="$cache_dir/landing/show_glyph.recent"
save_recent_entry() {
    local glyph_line="$1"
    (
        echo "$glyph_line"
        cat "$recent_data"
    ) | awk '!seen[$0]++' > temp && mv temp "$recent_data"
}
main() {
    if [[ ! -f $recent_data ]]; then
        mkdir -p "$(dirname "$recent_data")"
        printf "\tArch linux - I use Arch, BTW\n" > "$recent_data"
    fi
    data_glyph=$(awk '!seen[$0]++' "$recent_data" "$glyph_data" \
        | "$LIB_DIR/doorway/anyrun-dmenu.sh" -p "  Glyph")
    [[ -z $data_glyph ]] && exit 0
    local sel_glyph=""
    sel_glyph=$(printf "%s" "$data_glyph" | cut -d$'\t' -f1 | xargs)
    if [[ -n $sel_glyph ]]; then
        wl-copy "$sel_glyph"
        save_recent_entry "$data_glyph"
        paste_string "$@"
    fi
}
main "$@"
