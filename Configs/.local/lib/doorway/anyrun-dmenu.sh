#!/usr/bin/env bash
#|- anyrun-dmenu.sh - dmenu-style picker on anyrun's stdin plugin ------------
# Replaces `rofi -dmenu` (rofi → anyrun migration, see TODO.md).
# Reads lines on stdin, prints the selection to stdout, exits 1 on dismiss
# (mirrors dmenu so `|| exit 0` call sites keep working).
#
#   -p, --placeholder TEXT   accepted for call-site readability; anyrun has
#                            no prompt/placeholder text, so it is ignored
#   -l, --lines N            max entries shown (default 15)
#   -d, --display COL        show only awk field COL of each line, but print
#                            the FULL selected line (rofi -display-columns)
#   -s, --separator SEP      field separator for --display (default ':::')
#
# Anything else (position, width, theme) comes from ~/.config/anyrun/
# (config.ron + style.css + stdin.ron), so pickers match the launcher look.

lines=15
display_col=""
separator=":::"
while (($# > 0)); do
    case $1 in
        -p | --placeholder) shift ;;
        -l | --lines)
            [[ $2 =~ ^[0-9]+$ ]] && lines=$2
            shift
            ;;
        -d | --display)
            display_col=$2
            shift
            ;;
        -s | --separator)
            separator=$2
            shift
            ;;
    esac
    shift
done

run_anyrun() {
    anyrun --plugins libstdin.so \
        --show-results-immediately true \
        --hide-plugin-info true \
        --hide-icons true \
        --max-entries "$lines"
}

if [[ -z $display_col ]]; then
    selection=$(run_anyrun)
    [[ -n $selection ]] || exit 1
    printf '%s\n' "$selection"
    exit 0
fi

# Display-column mode: show one field, return the whole line. Selection is
# mapped back by exact display-text match (first hit wins on duplicates).
mapfile -t input
((${#input[@]})) || exit 1
display=$(printf '%s\n' "${input[@]}" | awk -F "$separator" -v c="$display_col" '{print $c}')
selection=$(run_anyrun <<< "$display")
[[ -n $selection ]] || exit 1
index=$(grep -nxF -m1 -- "$selection" <<< "$display" | cut -d: -f1)
[[ -n $index ]] || exit 1
printf '%s\n' "${input[index - 1]}"
