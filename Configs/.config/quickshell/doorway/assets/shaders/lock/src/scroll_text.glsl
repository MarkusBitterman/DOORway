// "Scroll Text" — ported from shader-hero.js SHADERS.blog.
// NES RPG text box: warm amber character blocks scrolling up,
// blinking cursor, occasional red/blue highlight groups.

const vec3 FEATHER_RUST   = vec3(0.769, 0.416, 0.176);
const vec3 OWL_UMBER      = vec3(0.541, 0.310, 0.165);
const vec3 SHADOW_BARK    = vec3(0.227, 0.165, 0.118);
const vec3 POWER_GOLD     = vec3(1.000, 0.761, 0.055);
const vec3 POWER_RED      = vec3(0.902, 0.000, 0.071);
const vec3 HERO_BLUE      = vec3(0.122, 0.235, 0.533);
const vec3 INK_BLACK      = vec3(0.110, 0.110, 0.110);
const vec3 AGED_PAPER     = vec3(0.937, 0.890, 0.773);

void main() {
  vec2 fragCoord = vec2(qt_TexCoord0.x, 1.0 - qt_TexCoord0.y) * iResolution;
  vec2 uv = fragCoord / iResolution.xy;
  uv.x += rfJitter(uv.y, iTime);

  // dark background like an NES text box
  vec3 col = mix(SHADOW_BARK, INK_BLACK, 0.6);

  // horizontal "text lines" — rows of blocky dashes
  float aspect = iResolution.x / iResolution.y;
  float rows = 10.0;
  float cols = 32.0;
  vec2 cell = floor(vec2(uv.x * cols * aspect, uv.y * rows));
  vec2 cellUV = fract(vec2(uv.x * cols * aspect, uv.y * rows));

  // "text" appears row by row, scrolling up slowly
  float rowIdx = cell.y + floor(iTime * 0.5);
  float charSeed = hash(vec2(cell.x, rowIdx));

  // only some cells have "characters" (simulated text density)
  float hasChar = step(0.25, charSeed) * step(charSeed, 0.88);

  // character block (inner rectangle of the cell)
  float charBlock = step(0.15, cellUV.x) * step(cellUV.x, 0.85)
                  * step(0.20, cellUV.y) * step(cellUV.y, 0.80);

  // text color — warm amber tones (default)
  vec3 textColor = mix(FEATHER_RUST, POWER_GOLD, charSeed);
  if (charSeed > 0.75) textColor = mix(textColor, OWL_UMBER, 0.4);

  // ── occasional red or blue highlight groups ──
  vec2 group = floor(vec2(cell.x / 4.0, rowIdx / 2.0));
  float groupSeed = hash(group + 31.0);
  float highlightPhase = floor(iTime * 0.25);  // change which groups glow
  float groupActive = hash(group + highlightPhase * 17.0);

  // ~8% of groups get a highlight at any time
  if (groupActive > 0.92) {
    // alternate red and blue based on group seed
    if (groupSeed > 0.5) {
      textColor = mix(textColor, POWER_RED * 1.2, 0.7);
    } else {
      textColor = mix(textColor, HERO_BLUE * 1.8, 0.7);
    }
  }

  col = mix(col, textColor, hasChar * charBlock * 0.8);

  // blinking cursor at bottom-right area
  float cursorX = step(0.85, uv.x) * step(uv.x, 0.90);
  float cursorY = step(0.08, uv.y) * step(uv.y, 0.16);
  float cursorBlink = step(0.5, fract(iTime * 0.6));
  col = mix(col, AGED_PAPER * 0.9, cursorX * cursorY * cursorBlink);

  // text box border (NES-style double border)
  float borderOuter = step(uv.x, 0.02) + step(0.98, uv.x)
                    + step(uv.y, 0.02) + step(0.98, uv.y);
  float borderInner = step(uv.x, 0.04) * step(0.02, uv.x)
                    + step(0.96, uv.x) * step(uv.x, 0.98)
                    + step(uv.y, 0.04) * step(0.02, uv.y)
                    + step(0.96, uv.y) * step(uv.y, 0.98);
  col = mix(col, AGED_PAPER * 0.7, min(1.0, borderOuter));
  col = mix(col, OWL_UMBER, min(1.0, borderInner) * 0.5);

  // CRT vignette
  float vig = 1.0 - 0.4 * pow(length(uv - 0.5) * 1.4, 2.0);
  col *= vig;

  float s = snow(uv, iTime);
  col = mix(col, vec3(s), 0.10);

  col *= scanline(uv, iResolution.y * 0.5, 0.28);

  col = quantize(col, 10.0);

  fragColor = vec4(col, 1.0) * qt_Opacity;
}
