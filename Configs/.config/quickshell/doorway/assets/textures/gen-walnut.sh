#!/usr/bin/env bash
# gen-walnut.sh — procedurally generate the DOORway "Black Walnut" woodgrain textures.
#
# Modelled on the Atari VCS 800 "Black Walnut" faceplate: a cool, muted espresso-taupe
# faux woodgrain defined by fine, dense, CONTINUOUS grain lines running the length of the
# panel, with the tonal "wobble" carried along those lines (never across them, so the
# horizontal flow stays intact).
#
# make_walnut <width> <height> <h|v> <out.png>
#   Strong-line pipeline (grain lines colorized through a walnut CLUT):
#     1. A NARROW noise field stretched hugely ALONG the grain axis — each row becomes a
#        continuous line while the across-axis keeps full detail = crisp parallel lines.
#     2. A sinusoid sharpens the value field into defined, dense grain lines.
#     3. A displacement warp almost entirely ALONG the grain (tiny across) wobbles tone
#        down each line without bending it — the flow stays dead straight.
#     4. -clut maps luminance onto the cool espresso-taupe walnut ramp (sampled from the
#        real VCS 800 faceplate: dominant ~#50413C).
#   Everything runs with `-virtual-pixel tile` so the result tiles seamlessly; output is an
#   indexed (PNG8) image (walnut needs few colors — a big size win, no visible loss).
#
# Output (committed to the repo, deployed via Nix):
#   walnut-h.png  1920x96   horizontal grain — top bar (tiles L↔R on >1920 screens)
#   walnut-v.png  512x2160  vertical grain   — sidebars (tiles T↕B on >2160 screens)
#
# Deterministic (fixed -seed) so regeneration is reproducible.
set -euo pipefail
cd "$(dirname "$0")"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# --- Cool espresso-taupe walnut ramp (matched to the VCS 800 faceplate) ---
magick -size 1x256 gradient:"#1c1613-#6a574d" \
  \( -size 1x256 gradient:"#2a211c-#7a6558" \) -evaluate-sequence Mean "$work/ramp.png"

make_walnut() {
  local w="$1" h="$2" dir="$3" out="$4"
  local base disp
  if [[ "$dir" == "h" ]]; then
    base="24x200"   # narrow×tall -> stretched wide = continuous horizontal lines
    disp="24x2"     # wobble along the line (horizontal), barely across (keeps it straight)
  else
    base="1075x24"  # wide×short -> stretched tall = continuous vertical lines
    disp="2x24"     # wobble along the line (vertical), barely across
  fi

  # 1. Continuous grain lines from an anisotropically-stretched noise field.
  magick -size "$base" xc: -seed 4242 +noise Random -colorspace Gray \
    -channel R -separate +channel \
    -virtual-pixel tile -resize "${w}x${h}\!" -blur 0x0.5 "$work/base.png"

  # 2. Sharpen into dense, defined lines.
  magick "$work/base.png" -function Sinusoid 12,0,0.48,0.5 "$work/lines.png"

  # 3. Along-grain tonal wobble (does not bend the lines).
  magick -size "${w}x${h}" xc: -seed 99 +noise Random -colorspace Gray \
    -virtual-pixel tile -blur 0x20 -auto-level "$work/disp.png"
  magick "$work/lines.png" "$work/disp.png" \
    -virtual-pixel tile -compose displace -define compose:args="$disp" -composite +repage \
    -auto-level -sigmoidal-contrast 3.8x50% "$work/warp.png"

  # 4. Colorize + write indexed PNG8.
  magick "$work/warp.png" "$work/ramp.png" -clut \
    -dither None -colors 256 -depth 8 -define png:color-type=3 "$out"
}

make_walnut 1920 96   h walnut-h.png
make_walnut 512  2160 v walnut-v.png

for f in walnut-h.png walnut-v.png; do
  echo "$f: $(identify -format '%wx%h %B bytes' "$f")"
done
