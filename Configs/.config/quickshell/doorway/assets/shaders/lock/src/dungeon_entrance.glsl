// "Dungeon Entrance" — ported from shader-hero.js SHADERS.home.
// Dark brick walls, stone floor tiles, torch flicker, door hint.

const vec3 SHADOW_BARK    = vec3(0.227, 0.165, 0.118);
const vec3 HERO_BLUE      = vec3(0.122, 0.235, 0.533);
const vec3 OWL_UMBER      = vec3(0.541, 0.310, 0.165);
const vec3 POWER_GOLD     = vec3(1.000, 0.761, 0.055);
const vec3 FEATHER_RUST   = vec3(0.769, 0.416, 0.176);
const vec3 INK_BLACK      = vec3(0.110, 0.110, 0.110);
const vec3 KOHOLINT_GRASS = vec3(0.373, 0.686, 0.227);

void main() {
  // Y-flip so the original gl_FragCoord math ports verbatim
  vec2 fragCoord = vec2(qt_TexCoord0.x, 1.0 - qt_TexCoord0.y) * iResolution;
  vec2 uv = fragCoord / iResolution.xy;
  uv.x += rfJitter(uv.y, iTime);

  float aspect = iResolution.x / iResolution.y;

  // dungeon floor — 12x8 tile grid, stone pattern
  float gridX = 12.0 * aspect;
  float gridY = 8.0;
  vec2 tile = floor(vec2(uv.x * gridX, uv.y * gridY));
  vec2 tileUV = fract(vec2(uv.x * gridX, uv.y * gridY));

  // base stone floor — dark blue-brown dungeon color
  float tileSeed = hash(tile);
  vec3 col = mix(SHADOW_BARK, HERO_BLUE * 0.4, 0.3);

  // vary each tile slightly for a hand-placed stone look
  col *= 0.7 + 0.3 * tileSeed;

  // top and bottom wall rows — darker brick
  float isWall = step(gridY - 1.5, tile.y) + step(tile.y, 0.5);
  vec3 wallCol = mix(INK_BLACK, SHADOW_BARK * 0.6, tileSeed * 0.5);
  col = mix(col, wallCol, min(1.0, isWall));

  // brick pattern on walls (offset every other row)
  float brickOff = mod(tile.y, 2.0) * 0.5;
  float brickEdgeX = step(fract(tileUV.x + brickOff), 0.06);
  float brickEdgeY = step(tileUV.y, 0.08);
  float brickEdge = min(1.0, brickEdgeX + brickEdgeY);
  col = mix(col, INK_BLACK, brickEdge * isWall * 0.5);

  // floor tile edges (mortar lines)
  float mortarX = step(tileUV.x, 0.05) + step(0.95, tileUV.x);
  float mortarY = step(tileUV.y, 0.05) + step(0.95, tileUV.y);
  float mortar = min(1.0, mortarX + mortarY);
  col = mix(col, INK_BLACK * 1.2, mortar * 0.3 * (1.0 - isWall));

  // two torch positions (upper corners of the room)
  vec2 torchL = vec2(0.15, 0.75);
  vec2 torchR = vec2(0.85, 0.75);

  // flickering glow — each torch has independent flicker
  float flickerL = 0.7 + 0.3 * sin(iTime * 2.1 + 0.0)
                 * sin(iTime * 3.7 + 1.0);
  float flickerR = 0.7 + 0.3 * sin(iTime * 2.5 + 3.0)
                 * sin(iTime * 3.3 + 2.0);

  // warm light radius from each torch
  float dL = length(uv - torchL);
  float dR = length(uv - torchR);
  float glowL = smoothstep(0.55, 0.0, dL) * flickerL;
  float glowR = smoothstep(0.55, 0.0, dR) * flickerR;

  // torch light color — gold to rust gradient
  vec3 torchLight = mix(POWER_GOLD * 0.6, FEATHER_RUST * 0.5, 0.4);
  col += torchLight * glowL;
  col += torchLight * glowR;

  // center door — a darker rectangle hinting at the next room
  float doorX = step(0.40, uv.x) * step(uv.x, 0.60);
  float doorY = step(0.55, uv.y) * step(uv.y, 0.88);
  col = mix(col, INK_BLACK * 0.7, doorX * doorY * 0.6);

  // door frame highlight — faint gold edge
  float frameX = step(0.39, uv.x) * step(uv.x, 0.61);
  float frameY = step(0.54, uv.y) * step(uv.y, 0.89);
  float frame = (frameX * frameY) - (doorX * doorY);
  col = mix(col, OWL_UMBER * 0.6, max(0.0, frame) * 0.5);

  // tiny green glint — like a rupee or key catch
  float glintPhase = floor(iTime * 0.4);
  vec2 glintPos = vec2(
    0.3 + hash(vec2(glintPhase, 1.0)) * 0.4,
    0.2 + hash(vec2(glintPhase, 2.0)) * 0.3
  );
  float glintD = length(uv - glintPos);
  float glint = smoothstep(0.02, 0.0, glintD)
              * step(0.5, fract(iTime * 0.8));
  col += KOHOLINT_GRASS * 0.5 * glint;

  // CRT vignette — heavier for dungeon darkness
  float vig = 1.0 - 0.5 * pow(length(uv - 0.5) * 1.4, 2.0);
  col *= vig;

  // static snow
  float s = snow(uv, iTime);
  col = mix(col, vec3(s), 0.08);

  // scanlines
  col *= scanline(uv, iResolution.y * 0.5, 0.28);

  // quantize to NES levels
  col = quantize(col, 10.0);

  fragColor = vec4(col, 1.0) * qt_Opacity;
}
