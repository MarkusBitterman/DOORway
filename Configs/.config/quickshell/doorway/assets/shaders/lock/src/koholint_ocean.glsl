// "Koholint Ocean" — ported from shader-hero.js SHADERS.about.
// NES water: chunky scrolling wave bands in four blues.

const vec3 HERO_BLUE    = vec3(0.122, 0.235, 0.533);
const vec3 SKY_HINT     = vec3(0.435, 0.639, 0.851);
const vec3 INK_BLACK    = vec3(0.110, 0.110, 0.110);
const vec3 AGED_PAPER   = vec3(0.937, 0.890, 0.773);

void main() {
  vec2 fragCoord = vec2(qt_TexCoord0.x, 1.0 - qt_TexCoord0.y) * iResolution;
  vec2 uv = fragCoord / iResolution.xy;
  uv.x += rfJitter(uv.y, iTime);

  // NES water: 4 shades of blue in wavy horizontal bands
  // each band scrolls at a slightly different speed
  float y = uv.y;

  // chunky wave distortion (quantized to pixel rows)
  float pixelY = floor(uv.y * 60.0) / 60.0;
  float waveOff = sin(pixelY * 8.0 + iTime * 1.2) * 0.03
                + sin(pixelY * 16.0 - iTime * 0.8) * 0.015;
  float x = uv.x + waveOff;

  // 4-color palette cycling like NES water animation
  float phase = y * 6.0 + iTime * 0.5;
  float band = mod(floor(phase), 4.0);

  vec3 col;
  if (band == 0.0) col = INK_BLACK * 1.5;
  else if (band == 1.0) col = HERO_BLUE;
  else if (band == 2.0) col = SKY_HINT * 0.7;
  else col = SKY_HINT;

  // subtle horizontal streaks (like NES tile edges)
  float tileEdge = step(0.95, fract(phase));
  col = mix(col, INK_BLACK, tileEdge * 0.3);

  // CRT vignette
  float vig = 1.0 - 0.35 * pow(length(uv - 0.5) * 1.4, 2.0);
  col *= vig;

  // static snow
  float s = snow(uv, iTime);
  col = mix(col, vec3(s), 0.07);

  // scanlines
  col *= scanline(uv, iResolution.y * 0.5, 0.20);

  col = quantize(col, 10.0);

  fragColor = vec4(col, 1.0) * qt_Opacity;
}
