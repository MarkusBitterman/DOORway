#!/usr/bin/env bash
#|- gamelauncher.sh - game launcher (anyrun-dmenu; was rofi steam_deck theme)
# Backends emit "display<TAB>command" lines; the picker shows the display
# column and the selected game's command is exec'd.
anyrun close 2> /dev/null && exit 0
[[ $DOORWAY_SHELL_INIT -ne 1 ]] && eval "$(doorway-shell init)"

# shellcheck disable=SC1091
source "${LIB_DIR}/doorway/shutils/argparse.sh"
argparse_init "$@"
argparse_program "doorway-shell gamelauncher"
argparse_header "DOORway Game Launcher"
argparse "--backend,-b" "BACKEND" "Specify the backend (steam, lutris, default: all)" "parameter"
argparse_finalize

backend="${BACKEND:-$backend}"
python_bin="${XDG_STATE_HOME:-$HOME/.local/state}/doorway/python_env/bin/python"

case "$backend" in
    steam)
        backend_command=("$python_bin" "$LIB_DIR/doorway/gamelauncher/steam.py" --rofi-string)
        ;;
    lutris)
        backend_command=("$python_bin" "$LIB_DIR/doorway/gamelauncher/lutris.py" --rofi-string)
        ;;
    *)
        backend_command=("$python_bin" "$LIB_DIR/doorway/gamelauncher/catalog.py" --rofi-string)
        ;;
esac

selected=$("${backend_command[@]}" | "$LIB_DIR/doorway/anyrun-dmenu.sh" -p "Catalog" -d 1 -s $'\t')
if [ -z "$selected" ]; then
    exit 0
fi

cmd=${selected#*$'\t'}

eval exec "$cmd"
