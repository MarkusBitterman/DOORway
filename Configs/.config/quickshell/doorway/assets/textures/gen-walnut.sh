#!/usr/bin/env bash
# gen-walnut.sh — procedurally generate the DOORway "Black Walnut" woodgrain textures.
#
# Inspired by the Atari VCS 800 "Black Walnut" computer system: a dark chocolate
# flat-sawn walnut veneer with organically-flowing grain lines and muted caramel figure.
#
# Pipeline (per-axis grain, colorized through a hand-built walnut CLUT):
#   1. Seeded random noise, smeared along the grain axis with a mirrored motion blur
#      (mirror + oversize-then-crop avoids the frayed "comb" the blur leaves at the ends).
#   2. A low-frequency sinusoid turns the smear into defined grain "ring" lines.
#   3. A gently-blurred noise displacement map warps those lines into flowing figure.
#   4. -clut maps luminance onto the black-walnut color ramp.
#
# Output (8-bit PNG, committed to the repo, deployed via Nix):
#   walnut-v.png  — vertical grain   (sidebars, portrait surfaces)
#   walnut-h.png  — horizontal grain (top bar, landscape surfaces)
#
# Re-run to retune. Deterministic (fixed -seed values) so regeneration is reproducible.
set -euo pipefail
cd "$(dirname "$0")"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# --- Black-walnut color ramp: darkest grain -> warm mid -> muted caramel figure ---
magick -size 1x256 gradient:"#0c0602-#6f4623" \
  \( -size 1x256 gradient:"#1a0f07-#845632" \) -evaluate-sequence Mean "$work/ramp.png"

# --- 1. Vertical grain streaks (mirror + oversize-crop kills frayed motion-blur ends) ---
magick -size 180x1200 xc: -seed 4242 +noise Random -colorspace Gray \
  -channel R -separate +channel \
  -virtual-pixel Mirror -motion-blur 0x55+90 \
  -gravity center -crop 180x1024+0+0 +repage \
  -resize 512x1024\! -blur 0x0.8 "$work/base.png"

# --- 2. Defined grain lines (moderate frequency) ---
magick "$work/base.png" -function Sinusoid 5,0,0.44,0.5 "$work/grain.png"

# --- 3. Organic displacement warp (small amplitude keeps lines legible) ---
magick -size 128x256 xc: -seed 99 +noise Random -colorspace Gray -blur 0x20 -auto-level \
  -resize 512x1024\! "$work/disp.png"
magick "$work/grain.png" "$work/disp.png" \
  -compose displace -define compose:args=6x16 -composite +repage \
  -auto-level -sigmoidal-contrast 5x48% "$work/grain-warped.png"

# --- 4. Colorize + emit both orientations as 8-bit ---
magick "$work/grain-warped.png" "$work/ramp.png" -clut -depth 8 walnut-v.png
magick walnut-v.png -rotate 90 -depth 8 walnut-h.png

echo "wrote walnut-v.png ($(identify -format '%wx%h' walnut-v.png)) and walnut-h.png ($(identify -format '%wx%h' walnut-h.png))"
