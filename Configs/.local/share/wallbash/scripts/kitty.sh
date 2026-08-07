#!/usr/bin/env bash
# Wallbash post-render hook for kitty.
#
# color.set.sh renders theme/kitty.dcol into ~/.config/kitty/theme.conf and then
# runs this. Two jobs: make the generated palette legible, then reload kitty.
#
# The palette needs correcting because kitty.dcol maps ANSI slots onto wallbash's
# accent ramps (<wallbash_4xa9> and friends), which have no contrast relationship
# to <wallbash_pry1> — the background the same template sets. Legibility is
# therefore luck of the wallpaper. Measured 2026-08-06: 14 of 16 slots below the
# WCAG 3:1 floor, color7 (the "white" most TUI text uses) at 1.62:1.

set -uo pipefail

confDir="${confDir:-$HOME/.config}"
kittyThemeConf="${confDir}/kitty/theme.conf"

# NOTE: this script used to `sed -i` ~/.config/kitty/kitty.conf to inject an
# `include doorway.conf` line. That line has been committed at the top of
# kitty.conf since the DOORway rewrite, so the injection was already redundant —
# and actively harmful: kitty.conf is a Home Manager symlink into the Nix store,
# and GNU sed -i replaces a symlink with a regular file even when its pattern
# matches nothing. Every wallpaper change therefore clobbered the HM link, and
# the next activation backed the stray file up as kitty.conf.backup. Removed.

# Effective background opacity: what shows through decides what text is actually
# read against. kitty's own background_opacity composites the wallpaper into the
# terminal background, and Hyprland's active_opacity composites the whole window
# again on top — measured together they turned a nominal 5.2:1 into 2.8:1 on
# screen, so both factor in.
kitty_opacity() {
    local value
    value=$(grep -hs '^[[:space:]]*background_opacity' \
        "${confDir}/kitty/doorway.conf" "${confDir}/kitty/kitty.conf" 2> /dev/null |
        tail -1 | awk '{print $2}')
    [[ $value =~ ^[0-9]*\.?[0-9]+$ ]] && printf '%s' "$value" || printf '1.0'
}

hypr_opacity() {
    local value
    if command -v hyprctl > /dev/null 2>&1 && [[ -n ${HYPRLAND_INSTANCE_SIGNATURE:-} ]]; then
        value=$(timeout 2 hyprctl getoption decoration:active_opacity 2> /dev/null |
            awk '/^float:/ {print $2}')
        [[ $value =~ ^[0-9]*\.?[0-9]+$ ]] && printf '%s' "$value" && return
    fi
    printf '1.0'
}

# Locate the corrector. color.set.sh exports scrDir (the doorway lib dir); fall
# back to PATH so the hook still works when run by hand.
contrastBin="${scrDir:-}/wallbash-contrast.py"
[[ -x $contrastBin ]] || contrastBin="$(command -v wallbash-contrast.py 2> /dev/null || true)"

if [[ -f $kittyThemeConf && -n $contrastBin ]]; then
    # DOORWAY_TERMINAL_CONTRAST is set from doorway.theme.terminalContrast.
    # 0 (or anything <= 1) disables correction and leaves raw wallbash output.
    floor="${DOORWAY_TERMINAL_CONTRAST:-4.5}"
    opacity=$(awk -v a="$(kitty_opacity)" -v b="$(hypr_opacity)" 'BEGIN {printf "%.3f", a * b}')
    "$contrastBin" --floor "$floor" --opacity "$opacity" "$kittyThemeConf" ||
        echo "kitty.sh: contrast correction failed; leaving raw wallbash palette" >&2
fi

# No reload step: kitty 0.48 watches its own config and picks up theme.conf
# (an `include`d file) on write — verified 2026-08-06 by writing a garish
# background with no signal sent and screenshotting the result.
#
# The inherited `killall -SIGUSR1 kitty` here was dead twice over. killall is
# not in the DOORway closure at all, and even installed it matches on comm,
# which under Nix is `.kitty-wrapped`, not `kitty` — the same trap that makes
# `pkill -x qs` silently match nothing. (It would not have killed the terminal
# had it worked: kitty blocks SIGUSR1 and drains it through its event loop, so
# the default terminate action can never fire.)
