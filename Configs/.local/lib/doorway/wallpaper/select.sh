#!/usr/bin/env bash

Wall_Select() {
    # anyrun-dmenu shows the basename (field 1) and returns the full
    # "name:::path:::thumbnail" line; rofi's thumbnail grid is gone until the
    # QuickShell wallpaper surface lands (TODO.md, rofi → anyrun migration).
    local entry
    entry=$(Wall_Json | jq -r '.[].rofi_sqre' | sed 's/\x0.*//' \
        | "$LIB_DIR/doorway/anyrun-dmenu.sh" -p "🖼️ Wallpaper" -d 1)
    selected_thumbnail="$(awk -F ':::' '{print $3}' <<<"$entry")"
    selected_wallpaper_path="$(awk -F ':::' '{print $2}' <<<"$entry")"
    selected_wallpaper="$(awk -F ':::' '{print $1}' <<<"$entry")"
    export selected_wallpaper selected_wallpaper_path selected_thumbnail
    if [ -z "$selected_wallpaper" ]; then
        print_log -err "wallpaper" " No wallpaper selected"
        exit 0
    fi
}
