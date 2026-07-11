#!/usr/bin/env bash
# Bakes the DOORway right-sidebar GLSL sources into Qt6 .qsb bundles.
# Same pipeline as assets/shaders/lock/build.sh — Qt6 ShaderEffect cannot
# consume raw GLSL, so shaders are precompiled by qsb (qt6.qtshadertools, in
# the flake dev shell) and the .qsb outputs are committed. Kept separate from
# the lock shaders because these declare an extra `uActivity` uniform (fed live
# ResourceUsage data) and share none of the lock's shader list.
#
# Usage: nix develop -c ./build.sh   (or just ./build.sh inside nix develop)
set -euo pipefail
cd "$(dirname "$0")"

SHADERS=(
  encom_dataflow
)

# Vulkan-style GLSL header qsb expects. Uniforms surface as QML properties of
# the same name on the ShaderEffect. uActivity (0..1) is driven by the sidebar
# from max(net%, cpu%) so the traces surge under real system load.
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
    float uActivity;
};
EOF
}

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

for name in "${SHADERS[@]}"; do
  {
    header
    cat "src/$name.glsl"
  } >"$tmp/$name.frag"
  qsb --glsl "300 es,330" -o "$name.frag.qsb" "$tmp/$name.frag"
  echo "baked $name.frag.qsb"
done
