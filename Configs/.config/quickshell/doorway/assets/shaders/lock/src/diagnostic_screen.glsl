// "Diagnostic Screen" — ported from shader-hero.js SHADERS.toolbox.
// NES-era hardware test screen: grid of slowly cycling blocks.

const vec3 SKY_HINT       = vec3(0.435, 0.639, 0.851);
const vec3 HERO_BLUE      = vec3(0.122, 0.235, 0.533);
const vec3 POWER_GOLD     = vec3(1.000, 0.761, 0.055);
const vec3 POWER_RED      = vec3(0.902, 0.000, 0.071);
const vec3 KOHOLINT_GRASS = vec3(0.373, 0.686, 0.227);
const vec3 INK_BLACK      = vec3(0.110, 0.110, 0.110);

void main() {
  vec2 fragCoord = vec2(qt_TexCoord0.x, 1.0 - qt_TexCoord0.y) * iResolution;
  vec2 uv = fragCoord / iResolution.xy;
  uv.x += rfJitter(uv.y, iTime);

  float aspect = iResolution.x / iResolution.y;

  // 8x6 block grid
  vec2 blockCoord = floor(vec2(uv.x * 8.0 * aspect, uv.y * 6.0));
  vec2 blockUV = fract(vec2(uv.x * 8.0 * aspect, uv.y * 6.0));

  // cycle colors through blocks — VERY slow to avoid flashing
  float idx = hash(blockCoord) * 5.0;
  float phase = floor(iTime * 0.15 + idx);
  float selector = mod(phase, 5.0);

  vec3 col;
  if (selector < 1.0) col = SKY_HINT;
  else if (selector < 2.0) col = HERO_BLUE;
  else if (selector < 3.0) col = POWER_GOLD;
  else if (selector < 4.0) col = POWER_RED * 0.8;
  else col = KOHOLINT_GRASS;

  // mute 80% of blocks — keep colorful but subdued
  float isBright = step(0.80, hash(blockCoord + 7.0));
  col = mix(col * 0.22, col, isBright);

  // block border
  float borderX = step(blockUV.x, 0.08) + step(0.92, blockUV.x);
  float borderY = step(blockUV.y, 0.08) + step(0.92, blockUV.y);
  float border = min(1.0, borderX + borderY);
  col = mix(col, INK_BLACK, border * 0.7);

  // rare subtle pulse on some blocks (no blink/flash)
  float pulse = 0.9 + 0.1 * sin(iTime * 0.3 + idx * 6.0);
  col *= pulse;

  // CRT vignette
  float vig = 1.0 - 0.35 * pow(length(uv - 0.5) * 1.4, 2.0);
  col *= vig;

  float s = snow(uv, iTime);
  col = mix(col, vec3(s), 0.09);

  col *= scanline(uv, iResolution.y * 0.5, 0.25);

  col = quantize(col, 10.0);

  fragColor = vec4(col, 1.0) * qt_Opacity;
}
