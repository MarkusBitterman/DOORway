// "Overworld — Lost Woods" — ported from shader-hero.js SHADERS.portfolio.
// Top-down tile scroll following the Lost Woods solution (N,W,S,W),
// camera-inverted so tiles scroll Down, Right, Up, Right.

const vec3 KOHOLINT_GRASS = vec3(0.373, 0.686, 0.227);
const vec3 POWER_GOLD     = vec3(1.000, 0.761, 0.055);
const vec3 OWL_UMBER      = vec3(0.541, 0.310, 0.165);
const vec3 SHADOW_BARK    = vec3(0.227, 0.165, 0.118);
const vec3 AGED_PAPER     = vec3(0.937, 0.890, 0.773);

void main() {
  vec2 fragCoord = vec2(qt_TexCoord0.x, 1.0 - qt_TexCoord0.y) * iResolution;
  vec2 uv = fragCoord / iResolution.xy;
  uv.x += rfJitter(uv.y, iTime);

  // tile grid — 16x12 tiles like NES resolution
  float gridSize = 16.0;
  float aspect = iResolution.x / iResolution.y;
  vec2 tile = floor(vec2(uv.x * gridSize * aspect, uv.y * gridSize));

  // ── Lost Woods scroll pattern (N,W,S,W) ──
  float legDuration = 4.0;              // seconds per direction
  float cycleDuration = legDuration * 4.0;  // full loop = 16s
  float cycleTime = mod(iTime, cycleDuration);

  // accumulate tile offset through each completed leg
  vec2 offset = vec2(0.0);
  float speed = 0.5;  // tiles per second

  // leg 0: Down (0, -1)
  float t0 = clamp(cycleTime, 0.0, legDuration);
  offset += vec2(0.0, -1.0) * t0 * speed;

  // leg 1: Right (+1, 0)
  float t1 = clamp(cycleTime - legDuration, 0.0, legDuration);
  offset += vec2(1.0, 0.0) * t1 * speed;

  // leg 2: Up (0, +1)
  float t2 = clamp(cycleTime - legDuration * 2.0, 0.0, legDuration);
  offset += vec2(0.0, 1.0) * t2 * speed;

  // leg 3: Right (+1, 0)
  float t3 = clamp(cycleTime - legDuration * 3.0, 0.0, legDuration);
  offset += vec2(1.0, 0.0) * t3 * speed;

  tile += floor(offset);

  // pseudo-random tile type from hash
  float tileType = hash(tile);

  vec3 col;
  if (tileType < 0.45) {
    // grass tile — two shades
    col = mix(KOHOLINT_GRASS * 0.7, KOHOLINT_GRASS, step(0.25, tileType));
  } else if (tileType < 0.65) {
    // path / dirt tile
    col = mix(OWL_UMBER, POWER_GOLD * 0.5, step(0.55, tileType));
  } else if (tileType < 0.80) {
    // dark grass / bush
    col = KOHOLINT_GRASS * 0.45;
  } else if (tileType < 0.92) {
    // earth / rock
    col = SHADOW_BARK;
  } else {
    // flower / highlight
    col = mix(POWER_GOLD * 0.8, AGED_PAPER * 0.6, hash(tile + 99.0));
  }

  // tile edge darkening (grid lines)
  vec2 tileUV = fract(vec2(uv.x * gridSize * aspect, uv.y * gridSize));
  float edge = step(tileUV.x, 0.06) + step(tileUV.y, 0.06);
  col *= 1.0 - edge * 0.2;

  // CRT vignette
  float vig = 1.0 - 0.35 * pow(length(uv - 0.5) * 1.4, 2.0);
  col *= vig;

  float s = snow(uv, iTime);
  col = mix(col, vec3(s), 0.08);

  col *= scanline(uv, iResolution.y * 0.5, 0.22);

  col = quantize(col, 10.0);

  fragColor = vec4(col, 1.0) * qt_Opacity;
}
