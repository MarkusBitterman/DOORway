#!/usr/bin/env bash
if ! source "$(which doorway-shell)"; then
    echo "[$0] :: Error: doorway-shell not found."
    echo "[$0] :: Is DOORway installed?"
    exit 1
fi

# Source argparse.sh for argument parsing
# shellcheck disable=SC1091
source "${LIB_DIR}/doorway/shutils/argparse.sh"

confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
animations_dir="$confDir/hypr/animations"
if [ ! -d "$animations_dir" ]; then
    notify-send -i "preferences-desktop-display" "Error" "Animations directory does not exist at $animations_dir"
    exit 1
fi

fn_select() {
    animation_items=$(find -L "$animations_dir" -name "*.lua" ! -name "disable.lua" ! -name "theme.lua" 2> /dev/null | sed 's/\.lua$//')
    if [ -z "$animation_items" ]; then
        notify-send -i "preferences-desktop-display" "Error" "No .lua files found in $animations_dir"
        exit 1
    fi
    animation_items="Disable Animation
Theme Preference
$animation_items"
    selected_animation=$(awk -F/ '{print $NF}' <<< "$animation_items" \
        | "$LIB_DIR/doorway/anyrun-dmenu.sh" -p "Select animation")
    if [ -z "$selected_animation" ]; then
        exit 0
    fi
    case $selected_animation in
        "Disable Animation")
            selected_animation="disable"
            ;;
        "Theme Preference") selected_animation="theme" ;;
    esac
    set_conf "HYPR_ANIMATION" "$selected_animation"
    fn_update
    notify-send -i "preferences-desktop-display" "Animation:" "$selected_animation"
}
fn_update() {
    [ -f "$DOORWAY_STATE_HOME/config" ] && source "$DOORWAY_STATE_HOME/config"
    [ -f "$DOORWAY_STATE_HOME/staterc" ] && source "$DOORWAY_STATE_HOME/staterc"
    current_animation=${HYPR_ANIMATION:-"theme"}
    echo "Animation updated to: $current_animation"
    cat <<- EOF > "$confDir/hypr/animations.lua"
		-- DOORway controlled content -- DO NOT EDIT
		-- Edit or add presets in ./hypr/animations/ and run
		-- 'doorway-shell animations --select' to update this file.
		-- See https://wiki.hypr.land/Configuring/Animations/

		local animation = "$current_animation"
		require("animations/" .. animation)
	EOF
}

# Initialize argparse
argparse_init "$@"

# Set program name and header
argparse_program "doorway-shell animations"
argparse_header "DOORway Animation Selector"

# Define arguments
argparse "--select,-S" "" "Select an animation from the available options"

# Finalize parsing
argparse_finalize

case $ARGPARSE_ACTION in
    select) fn_select ;;
    *) argparse_help ;;
esac
