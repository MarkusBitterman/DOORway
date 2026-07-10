// --- RETRO CRT TOOLKIT ---
// Ported from MarkusBitterman.github.io src/js/shader-hero.js (RETRO_LIB).
// Concatenated into every lock shader by build.sh — qsb has no #include.

// fast hash noise (0..1)
float hash(vec2 p) {
  p = fract(p * vec2(443.897, 441.423));
  p += dot(p, p + 19.19);
  return fract(p.x * p.y);
}

// CRT scanlines: darkens every other pixel row
float scanline(vec2 uv, float resolution, float intensity) {
  float line = sin(uv.y * resolution * 3.14159) * 0.5 + 0.5;
  return 1.0 - (1.0 - line) * intensity;
}

// analog snow / static
float snow(vec2 uv, float t) {
  return hash(uv * 800.0 + t * 137.0) * hash(uv * 400.0 - t * 91.0);
}

// NES-style color quantization (reduces to ~4 bit per channel)
vec3 quantize(vec3 col, float levels) {
  return floor(col * levels + 0.5) / levels;
}

// horizontal jitter — bad RF cable / composite wobble
float rfJitter(float y, float t) {
  float wobble = sin(y * 90.0 + t * 3.0) * 0.001;
  wobble += sin(y * 250.0 - t * 7.0) * 0.0004;
  // occasional glitch band
  float glitch = step(0.992, hash(vec2(floor(y * 20.0), floor(t * 4.0))));
  wobble += glitch * 0.008 * sin(t * 50.0);
  return wobble;
}
