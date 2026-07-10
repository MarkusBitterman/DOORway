#!/usr/bin/env bash
# Bakes the DOORway Lock GLSL sources into Qt6 .qsb bundles.
# Qt6 ShaderEffect cannot consume raw GLSL — shaders must be precompiled by
# qsb (qt6.qtshadertools, in the flake dev shell). The .qsb outputs are
# committed so the deployed shell never needs the toolchain.
#
# Usage: nix develop -c ./build.sh   (or just ./build.sh inside nix develop)
set -euo pipefail
cd "$(dirname "$0")"

SHADERS=(
  dungeon_entrance
  koholint_ocean
  lost_woods
  time_gate
  diagnostic_screen
  scroll_text
  castle_fireworks
  signal_cutout
)

# Vulkan-style GLSL header qsb expects; uniforms surface as QML properties
# of the same name on the ShaderEffect. signal_cutout gets an extra driver.
header() {
  cat <<EOF
#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float iTime;
    vec2 iResolution;
${1:-}};
EOF
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

for name in "${SHADERS[@]}"; do
  extra=""
  [[ $name == signal_cutout ]] && extra="    float progress;"$'\n'
  {
    header "$extra"
    cat src/retro_lib.glsl
    cat "src/$name.glsl"
  } >"$tmp/$name.frag"
  qsb --glsl "300 es,330" -o "$name.frag.qsb" "$tmp/$name.frag"
  echo "baked $name.frag.qsb"
done
