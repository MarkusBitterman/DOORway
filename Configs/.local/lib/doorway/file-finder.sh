#!/usr/bin/env bash
#|- file-finder.sh - Super+Shift+E fuzzy file opener (fd → anyrun-dmenu)
# Replaces `rofi -show filebrowser` (rofi → anyrun migration). One flat
# fuzzy-searchable list beats directory navigation for a keyboard flow;
# depth is capped so the pipe stays fast on large home dirs.
[[ $DOORWAY_SHELL_INIT -ne 1 ]] && eval "$(doorway-shell init)"

cd "$HOME" || exit 1
selection=$(fd --type f --hidden \
    --exclude '.git' --exclude '.cache' --exclude 'node_modules' \
    --max-depth "${FILE_FINDER_DEPTH:-6}" \
    | "$LIB_DIR/doorway/anyrun-dmenu.sh") || exit 0
setsid -f xdg-open "$HOME/$selection" > /dev/null 2>&1
