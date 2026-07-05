#!/usr/bin/env bash
# gen-paper.sh — procedurally generate the DOORway magazine-page fibre grain.
#
# The left sidebar's MagazinePaper surface is warm uncoated cream. Uncoated stock
# reads as matte because of fine, random paper fibre catching the light — this
# texture supplies that fibre as a subtle overlay (MagazinePaper draws it at ~0.35
# opacity over the cream gradient).
#
# Design constraints:
#   - Mean must stay LIGHT (values compressed into ~0.80–1.0) so the overlay only
#     adds faint fibre highlights and never grey-washes the cream base tone.
#   - Seamlessly tileable (`-virtual-pixel tile`) — the sidebar is taller than the
#     tile, so it repeats.
#   - Deterministic (fixed -seed) so regeneration is reproducible.
#   - Small indexed PNG (few greys) — a tiny file, no visible loss.
#
# Output (committed to the repo, deployed via Nix — the read-only store can't
# generate it at runtime):
#   paper-grain.png  512x512  fine isotropic fibre
set -euo pipefail

out="$(dirname "$0")/paper-grain.png"

magick -size 512x512 xc:gray50 \
    -seed 42 -attenuate 0.9 +noise Gaussian \
    -colorspace Gray \
    -virtual-pixel tile -blur 0x0.35 \
    -auto-level \
    +level 80%,100% \
    -depth 8 "PNG8:${out}"

echo "wrote ${out}"
