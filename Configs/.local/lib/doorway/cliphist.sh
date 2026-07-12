#!/usr/bin/env bash
#|- cliphist.sh - clipboard manager (anyrun-dmenu; was rofi -dmenu)
# Interim port: multi-select, Alt-key accelerators and image thumbnails were
# rofi features with no anyrun equivalent — menu navigation is row-based
# (the ':x:y:' sentinel rows). A QuickShell surface will replace this
# (TODO.md, rofi → anyrun migration).
anyrun close 2> /dev/null && exit 0
[[ $DOORWAY_SHELL_INIT -ne 1 ]] && eval "$(doorway-shell init)"
cache_dir="${DOORWAY_CACHE_HOME:-$HOME/.cache/doorway}"
favorites_file="$cache_dir/landing/cliphist_favorites"
[ -f "$HOME/.cliphist_favorites" ] && favorites_file="$HOME/.cliphist_favorites"

process_deletion() {
    while IFS= read -r line; do
        echo "$line"
        if [[ $line == ":w:i:p:e:"* ]]; then
            "$0" --wipe
            break
        elif [[ $line == ":b:a:r:"* ]]; then
            "$0" --delete
            break
        elif [ -n "$line" ]; then
            cliphist delete <<< "$line"
            notify-send "Deleted" "$line"
        fi
    done
    exit 0
}
process_selections() {
    mapfile -t lines
    total_lines=${#lines[@]}
    handle_special_commands "${lines[@]}"
    local output=""
    for ((i = 0; i < total_lines; i++)); do
        local line="${lines[$i]}"
        local decoded_line
        decoded_line="$(echo -e "$line\t" | cliphist decode)"
        if [ $i -lt $((total_lines - 1)) ]; then
            printf -v output '%s%s\n' "$output" "$decoded_line"
        else
            printf -v output '%s%s' "$output" "$decoded_line"
        fi
    done
    echo -n "$output"
}
handle_special_commands() {
    local lines=("$@")
    case "${lines[0]}" in
        ":d:e:l:e:t:e:"*) exec "$0" --delete exit 0 ;;
        ":w:i:p:e:"*) exec "$0" --wipe exit 0 ;;
        ":b:a:r:"* | *":c:o:p:y:"*) exec "$0" --copy exit 0 ;;
        ":f:a:v:"*) exec "$0" --favorites exit 0 ;;
        ":i:m:g:") exec "$0" --image-history ;;
        ":o:p:t:"*) exec "$0" exit 0 ;;
        ":o:c:r:"*) exec "$0" --scan-image ;;
    esac
}
check_content() {
    local line
    read -r line
    if [[ $line == *"[[ binary data"* ]]; then
        cliphist decode <<< "$line" | wl-copy
        local img_idx
        img_idx=$(awk -F '\t' '{print $1}' <<< "$line")
        local temp_preview="$XDG_RUNTIME_DIR/doorway/pastebin-preview_$img_idx"
        wl-paste > "$temp_preview"
        notify-send -a "Pastebin:" "Preview: $img_idx" -i "$temp_preview" -t 2000
        return 1
    fi
}
run_menu() {
    # anyrun has no prompt text or Alt-accelerators; the placeholder is kept
    # for call-site readability and the ':x:y:' sentinel rows do navigation.
    local placeholder="$1"
    shift
    "$LIB_DIR/doorway/anyrun-dmenu.sh" -p "$placeholder"
}
ensure_favorites_dir() {
    local dir
    dir=$(dirname "$favorites_file")
    [ -d "$dir" ] || mkdir -p "$dir"
}
prepare_favorites_for_display() {
    if [ ! -f "$favorites_file" ] || [ ! -s "$favorites_file" ]; then
        return 1
    fi
    mapfile -t favorites < "$favorites_file"
    decoded_lines=()
    for favorite in "${favorites[@]}"; do
        local decoded_favorite
        decoded_favorite=$(echo "$favorite" | base64 --decode)
        local single_line_favorite
        single_line_favorite=$(echo "$decoded_favorite" | tr '\n' ' ')
        decoded_lines+=("$single_line_favorite")
    done
    return 0
}
cliphist_cmd() {
    if [[ $CLIPHIST_IMAGE_HISTORY != true ]]; then
        echo -e ":f:a:v:\t📌 Favorites"
        echo -e ":o:p:t:\t⚙️ Options"
        cliphist list
    else
        # strip the rofi-era "\0icon\x1f<path>" suffix — anyrun has no icons
        DOORWAY_CLIPHIST_IMAGE_ONLY=true cliphist.image.py | sed 's/\x0.*//'
    fi
}
show_history() {
    local selected_item placeholder
    placeholder=" 📜 History..."
    [[ $CLIPHIST_IMAGE_HISTORY == true ]] && placeholder=" 🏞️ Image History"

    selected_item=$(cliphist_cmd | run_menu "$placeholder")
    [ -n "$selected_item" ] || exit 0
    handle_special_commands "${selected_item##*$'\n'}"
    if echo -e "$selected_item" | check_content; then
        process_selections <<< "$selected_item" | wl-copy
        paste_string "$@"
        echo -e "$selected_item\t" | cliphist delete
    else
        paste_string "$@"
        exit 0
    fi
}

delete_items() {
    local selected_item
    selected_item="$(cliphist list | run_menu " 🗑️ Delete")"
    handle_special_commands "${selected_item##*$'\n'}"
    process_deletion <<< "$selected_item"
}
view_favorites() {
    prepare_favorites_for_display || {
        notify-send "No favorites."
        return
    }
    local selected_item
    selected_item=$(printf "%s\n" "${decoded_lines[@]}" | run_menu "📌 View Favorites") || exit 0
    if [ -n "$selected_item" ]; then
        handle_special_commands "${selected_item##*$'\n'}"
        local index
        index=$(printf "%s\n" "${decoded_lines[@]}" | grep -nxF "$selected_item" | cut -d: -f1)
        if [ -n "$index" ]; then
            local selected_encoded_favorite="${favorites[$((index - 1))]}"
            echo "$selected_encoded_favorite" | base64 --decode | wl-copy
            paste_string "$@"
            notify-send "Copied to clipboard."
        else
            notify-send "Error: Selected favorite not found."
        fi
    fi
}
add_to_favorites() {
    ensure_favorites_dir
    local item
    item=$(cliphist list | run_menu "➕ Add to Favorites...") || exit 0
    if [ -n "$item" ]; then
        local full_item
        full_item=$(echo "$item" | cliphist decode)
        local encoded_item
        encoded_item=$(echo "$full_item" | base64 -w 0)
        if [ -f "$favorites_file" ] && grep -Fxq "$encoded_item" "$favorites_file"; then
            notify-send "Item is already in favorites."
        else
            echo "$encoded_item" >> "$favorites_file"
            notify-send "Added to favorites."
        fi
    fi
}
delete_from_favorites() {
    prepare_favorites_for_display || {
        notify-send "No favorites to remove."
        return
    }
    local selected_favorite
    selected_favorite=$(printf "%s\n" "${decoded_lines[@]}" | run_menu "➖ Remove from Favorites...") || exit 0
    if [ -n "$selected_favorite" ]; then
        local index
        index=$(printf "%s\n" "${decoded_lines[@]}" | grep -nxF "$selected_favorite" | cut -d: -f1)
        if [ -n "$index" ]; then
            local selected_encoded_favorite="${favorites[$((index - 1))]}"
            if [ "$(wc -l < "$favorites_file")" -eq 1 ]; then
                : > "$favorites_file"
            else
                grep -vF -x "$selected_encoded_favorite" "$favorites_file" > "$favorites_file.tmp" && mv "$favorites_file.tmp" "$favorites_file"
            fi
            notify-send "Item removed from favorites."
        else
            notify-send "Error: Selected favorite not found."
        fi
    fi
}
clear_favorites() {
    if [ -f "$favorites_file" ] && [ -s "$favorites_file" ]; then
        local confirm
        confirm=$(echo -e "Yes\nNo" | run_menu "☢️ Clear All Favorites?") || exit 0
        if [ "$confirm" = "Yes" ]; then
            : > "$favorites_file"
            notify-send "All favorites have been deleted."
        fi
    else
        notify-send "No favorites to delete."
    fi
}
manage_favorites() {
    local manage_action
    manage_action=$(echo -e "Add to Favorites\nDelete from Favorites\nClear All Favorites" | run_menu "📓 Manage Favorites") || exit 0
    case "$manage_action" in
        "Add to Favorites")
            add_to_favorites
            ;;
        "Delete from Favorites")
            delete_from_favorites
            ;;
        "Clear All Favorites")
            clear_favorites
            ;;
        *)
            [ -n "$manage_action" ] || return 0
            echo "Invalid action"
            exit 1
            ;;
    esac
}
clear_history() {
    local selected_item
    selected_item=$(echo -e "Yes\nNo" | run_menu "☢️ Clear Clipboard History?")
    handle_special_commands "${selected_item##*$'\n'}"
    if [ "$selected_item" = "Yes" ]; then
        cliphist wipe
        notify-send "Clipboard history cleared."
    fi
}
main_menu_options() {
    cat <<- EOF
		History
		Image History
		Delete Item
		Clear History
		View Favorites
		Manage Favorites
	EOF
}

ocr_scan() {

    # shellcheck disable=SC1091
    source "${LIB_DIR}/doorway/shutils/ocr.sh"
    source ${XDG_STATE_HOME}/doorway/config
    local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/${EUID}}/doorway"
    local image_path="${runtime_dir}/cliphist_ocr.png"
    local index
    index="$(DOORWAY_CLIPHIST_IMAGE_ONLY=1 "${LIB_DIR}/doorway/cliphist.image.py" | head -n1)"
    [[ -n $index ]] || {
        send_notifs "OCR Error" "No images in clipboard history..." -r 9
        exit 1
    }

    mkdir -p "$runtime_dir"
    cliphist decode "$index" > "${image_path}"
    if [ ! -s "${image_path}" ]; then
        notify-send "OCR Error" "No image data in clipboard -r 9"
        exit 1
    fi
    print_log -g "Scanning ${image_path}"
    send_notifs "OCR" "Scanning latest image from clipboard..." -i "${image_path}" -r 9
    ocr_extract "$image_path"

}

main() {
    # shellcheck disable=SC1091
    source "${LIB_DIR}/doorway/shutils/argparse.sh"

    argparse_init "$@"
    argparse_program "doorway-shell cliphist"
    argparse_header "DOORway Clipboard Manager"

    argparse "--copy,-c" "ACTION=copy" "Show clipboard history and copy selected item"
    argparse "--delete,-d" "ACTION=delete" "Delete selected item from clipboard history"
    argparse "--favorites,-f" "ACTION=favorites" "View favorite clipboard items"
    argparse "--manage-fav,-mf" "ACTION=manage_fav" "Manage favorite clipboard items"
    argparse "--wipe,-w" "ACTION=wipe" "Clear clipboard history"
    argparse "--image-history,-i" "ACTION=image_history" "Show image history"
    argparse "--scan-image,-sc" "ACTION=ocr_image" "Use tesseract the latest image from clipboard"
    argparse_finalize

    unset CLIPHIST_IMAGE_HISTORY # prevent image history side effects

    if [ -z "$ACTION" ]; then
        # No arguments provided, show menu
        local main_action
        main_action=$(main_menu_options | run_menu "🔎 Options")
        handle_special_commands "${main_action##*$'\n'}"

        case "$main_action" in
            "History") ACTION=copy ;;
            "Image History") ACTION=image_history ;;
            "Delete Item") ACTION=delete ;;
            "Clear History") ACTION=wipe ;;
            "View Favorites") ACTION=favorites ;;
            "Manage Favorites") ACTION=manage_fav ;;
            *) exit 0 ;;
        esac
    fi

    # Execute the action
    case "$ACTION" in
        copy) show_history "$@" ;;
        delete) delete_items ;;
        favorites) view_favorites "$@" ;;
        manage_fav) manage_favorites ;;
        wipe) clear_history ;;
        image_history) CLIPHIST_IMAGE_HISTORY=true show_history "$@" ;;
        ocr_image) ocr_scan ;;
    esac
}
main "$@"
