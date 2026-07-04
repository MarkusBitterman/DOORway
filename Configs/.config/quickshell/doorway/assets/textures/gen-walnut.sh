#!/usr/bin/env bash
# gen-walnut.sh — procedurally generate the DOORway "Black Walnut" woodgrain textures.
#
# Inspired by the Atari VCS 800 "Black Walnut" computer system: a dark chocolate
# flat-sawn walnut veneer with organically-flowing grain lines and muted caramel figure.
#
# make_walnut <width> <height> <blur-angle> <out.png>
#   Pipeline (per-axis grain, colorized through a hand-built walnut CLUT):
#     1. Seeded random noise, smeared along the grain axis with a motion blur.
#     2. A low-frequency sinusoid turns the smear into defined grain "ring" lines.
#     3. A gently-blurred noise displacement map warps those lines into flowing figure.
#     4. -clut maps luminance onto the black-walnut color ramp.
#   Everything runs with `-virtual-pixel tile` so the result tiles seamlessly, and the
#   output is written as an indexed (PNG8) image — walnut needs few colors, so this is
#   a big size win at full resolution with no visible loss.
#
# Output (committed to the repo, deployed via Nix):
#   walnut-h.png  1920x96   horizontal grain — top bar (tiles L↔R on >1920 screens)
#   walnut-v.png  512x2160  vertical grain   — sidebars (tiles T↕B on >2160 screens)
#
# blur-angle: 0 = horizontal grain, 90 = vertical grain.
# Deterministic (fixed -seed) so regeneration is reproducible.
set -euo pipefail
cd "$(dirname "$0")"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# --- Black-walnut color ramp: darkest grain -> warm mid -> muted caramel figure ---
magick -size 1x256 gradient:"#0c0602-#6f4623" \
  \( -size 1x256 gradient:"#1a0f07-#845632" \) -evaluate-sequence Mean "$work/ramp.png"

make_walnut() {
  local w="$1" h="$2" angle="$3" out="$4"
  # Grain scale is tied to the smear length and line frequency. We author at a fixed
  # "grain resolution" (streak length ~55px, ~9 grain lines) and render at target size:
  #   - streaks run along the grain axis (motion blur at `angle`)
  #   - the sinusoid frequency is chosen for a natural line count across the short axis
  local shortaxis; shortaxis=$(( w < h ? w : h ))
  # ~1 grain line per 7px of the short axis, but keep it in a tasteful range.
  local freq; freq=$(awk -v s="$shortaxis" 'BEGIN{f=s/7.0; if(f<4)f=4; if(f>13)f=13; printf "%.2f", f}')

  # 1. Streaks: tileable noise smeared along the grain axis.
  magick -size "${w}x${h}" xc: -seed 4242 +noise Random -colorspace Gray \
    -channel R -separate +channel \
    -virtual-pixel tile -motion-blur "0x55+${angle}" \
    -blur 0x0.8 "$work/base.png"

  # 2. Defined grain lines.
  magick "$work/base.png" -function Sinusoid "${freq},0,0.44,0.5" "$work/grain.png"

  # 3. Organic displacement warp (tileable low-freq noise; small amplitude keeps lines).
  magick -size "${w}x${h}" xc: -seed 99 +noise Random -colorspace Gray \
    -virtual-pixel tile -blur 0x20 -auto-level "$work/disp.png"
  magick "$work/grain.png" "$work/disp.png" \
    -virtual-pixel tile -compose displace -define compose:args=6x16 -composite +repage \
    -auto-level -sigmoidal-contrast 5x48% "$work/grain-warped.png"

  # 4. Colorize + write indexed PNG8.
  magick "$work/grain-warped.png" "$work/ramp.png" -clut \
    -dither None -colors 256 -depth 8 -define png:color-type=3 "$out"
}

make_walnut 1920 96   0  walnut-h.png
make_walnut 512  2160 90 walnut-v.png

for f in walnut-h.png walnut-v.png; do
  echo "$f: $(identify -format '%wx%h %[channels] %B bytes' "$f")"
done
