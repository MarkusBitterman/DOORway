// "Time Gate" — ported from shader-hero.js SHADERS.now.
// Mirrored ceiling/floor planes with sine-bent rails toward a hungry
// vanishing point. Chrono Trigger time-warp energy.

const vec3 GATE_BLUE   = vec3(0.15, 0.25, 1.00);
const vec3 GATE_PURPLE = vec3(0.60, 0.10, 0.90);
const vec3 INK_BLACK   = vec3(0.110, 0.110, 0.110);
const vec3 AGED_PAPER  = vec3(0.937, 0.890, 0.773);

void main() {
  vec2 fragCoord = vec2(qt_TexCoord0.x, 1.0 - qt_TexCoord0.y) * iResolution;
  vec2 rawUV = fragCoord / iResolution.xy;
  vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;

  // ── LAYER 0: the void ──
  // circular static noise beneath everything — the gate's mouth
  float r = length(uv * vec2(1.2, 1.0));
  float voidRing = smoothstep(0.35, 0.10, r);
  float voidHole = smoothstep(0.18, 0.03, abs(r - 0.10));
  float voidNoise = hash(uv * 120.0 + iTime * 0.5);
  float voidStatic = (voidNoise - 0.5) * 0.35;
  float voidMask = clamp(voidRing * (0.6 + voidStatic) + voidHole * 0.4, 0.0, 1.0);

  // dark base with faint purple-blue wash from the void
  vec3 col = vec3(0.02, 0.01, 0.04);
  col += mix(GATE_BLUE, GATE_PURPLE, 0.5) * 0.08 * voidMask;

  // ── LAYER 1: two-plane fold ──
  // mirror y so top and bottom share one set of math
  vec2 p = uv;
  p.y = abs(p.y);

  // perspective depth — infinity at y=0, near at screen edges
  float depth = 1.0 / (0.12 + p.y);

  // perspective-correct x coordinate
  float x = p.x * depth;

  // forward motion — the world conveyor-belts past you
  float t = iTime * 0.8;

  // ── parallel rails with sine-bend ──
  float bend = 0.25 * sin(3.0 * p.y * depth - t * 3.0);
  float bentX = x + bend;

  // repeating line pattern — sharp bright rails
  float stripes = abs(fract(bentX * 5.0) - 0.5);
  float rails = smoothstep(0.12, 0.02, stripes);

  // ── energy pulse (blue-purple breathing) ──
  float pulse = 0.6 + 0.4 * sin(t * 4.0 - p.y * 18.0);
  float glow = rails * 1.5 * pulse;

  // color shifts between blue and purple with depth and time
  float colorMix = 0.5 + 0.5 * sin(t * 1.5 + p.y * 6.0);
  vec3 railCol = mix(GATE_BLUE, GATE_PURPLE, colorMix) * glow;

  // depth fade — rails dim toward the vanishing point & screen edge
  float depthFade = smoothstep(0.0, 0.15, p.y) * smoothstep(0.5, 0.2, p.y);
  railCol *= depthFade;

  // composite rails over void base
  col += railCol;

  // ── center convergence glow ──
  float centerPinch = smoothstep(0.9, 0.0, abs(uv.x));
  col += vec3(0.03, 0.01, 0.05) * centerPinch;

  // ── void undertow ──
  col *= 0.55 + 0.45 * voidMask;

  // RF jitter — the signal isn't clean
  float jit = rfJitter(rawUV.y, iTime);
  col = mix(col, col * 0.85, abs(jit) * 40.0);

  // CRT vignette
  float vig = 1.0 - 0.35 * pow(length(rawUV - 0.5) * 1.4, 2.0);
  col *= vig;

  // static snow — light
  float s = snow(rawUV, iTime);
  col = mix(col, vec3(s), 0.06);

  // scanlines
  col *= scanline(rawUV, iResolution.y * 0.5, 0.25);

  // quantize to NES palette
  col = quantize(col, 12.0);

  fragColor = vec4(col, 1.0) * qt_Opacity;
}
