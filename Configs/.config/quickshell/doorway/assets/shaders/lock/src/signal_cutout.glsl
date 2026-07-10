// "Signal Cutout" — DOORway Lock original (not from the website).
// The analog signal dies: a CRT losing its feed. Driven by an external
// `progress` uniform 0→1 (QML NumberAnimation), so the choreography is
// scrubbed by the intro animation rather than free-running on iTime:
//   0.00–0.35  static burst — the channel drops to full-field RF snow
//   0.35–0.75  vertical collapse — the raster squeezes to a hot white line
//   0.75–1.00  phosphor dot — the line pinches to a center dot and decays
// Also reused as the between-shader "channel change" flicker at a fixed
// low progress (~0.15), where it renders as pure snow.

const vec3 INK_BLACK  = vec3(0.110, 0.110, 0.110);
const vec3 AGED_PAPER = vec3(0.937, 0.890, 0.773);

void main() {
  vec2 fragCoord = vec2(qt_TexCoord0.x, 1.0 - qt_TexCoord0.y) * iResolution;
  vec2 uv = fragCoord / iResolution.xy;

  vec3 col = vec3(0.0);

  if (progress < 0.35) {
    // ── Phase 1: static burst ──
    // Snow ramps in fast, with rolling horizontal tear bands.
    float t = progress / 0.35;
    float burst = smoothstep(0.0, 0.25, t);

    vec2 suv = uv;
    suv.x += rfJitter(uv.y, iTime) * 6.0;

    // rolling tear band (vertical hold slipping)
    float band = fract(uv.y * 1.5 - iTime * 0.7);
    float tear = smoothstep(0.0, 0.06, band) * smoothstep(0.14, 0.06, band);
    suv.x += tear * 0.05;

    float s = snow(suv, iTime * 3.0);
    // boost contrast — hot white sparks over gray hiss
    float hiss = s * 1.6;
    float spark = step(0.985, hash(suv * 640.0 + iTime * 53.0)) * 1.2;
    col = vec3(hiss + spark) * burst;

    // ghost of a picture failing — dim aged-paper wash flickering out
    float ghost = (1.0 - t) * 0.20 * (0.5 + 0.5 * sin(iTime * 37.0));
    col += AGED_PAPER * ghost;

    col *= scanline(uv, iResolution.y * 0.5, 0.30);
  } else if (progress < 0.75) {
    // ── Phase 2: vertical collapse ──
    // The visible raster squeezes toward the center line; the static
    // inside compresses and overexposes as the beam concentrates.
    float t = (progress - 0.35) / 0.40;
    float halfHeight = mix(0.5, 0.004, pow(t, 1.6));
    float dy = abs(uv.y - 0.5);

    if (dy < halfHeight) {
      // remap into the compressed band and keep the snow playing
      vec2 cuv = vec2(uv.x, 0.5 + (uv.y - 0.5) / max(halfHeight * 2.0, 0.01));
      cuv.x += rfJitter(cuv.y, iTime) * 3.0;
      float s = snow(cuv, iTime * 3.0);

      // beam concentration: brightness climbs as the band thins
      float concentration = mix(1.0, 6.0, t);
      col = vec3(s * concentration);

      // white-hot core at the center line
      float core = smoothstep(halfHeight, 0.0, dy) * t;
      col += vec3(core * 2.5);
    }

    // faint vertical afterglow above/below the band
    float after = exp(-dy * 30.0) * 0.08 * (1.0 - t);
    col += AGED_PAPER * after;
  } else {
    // ── Phase 3: phosphor dot ──
    // The line pinches horizontally into a center dot, then decays.
    float t = (progress - 0.75) / 0.25;

    // line remnant shrinking from full width to a point
    float halfWidth = mix(0.5, 0.0, smoothstep(0.0, 0.55, t));
    float dx = abs(uv.x - 0.5);
    float dy = abs(uv.y - 0.5);

    float line = step(dx, halfWidth) * exp(-dy * iResolution.y * 0.9);
    col += vec3(line * (1.0 - t) * 2.0);

    // the dot: bright, then phosphor-decays through gold to black
    float d = length((uv - 0.5) * vec2(iResolution.x / iResolution.y, 1.0));
    float dot_ = exp(-d * mix(60.0, 220.0, t));
    float decay = 1.0 - smoothstep(0.35, 1.0, t);
    vec3 dotCol = mix(vec3(1.0), vec3(1.000, 0.761, 0.055) * 0.6, t); // white → power-gold
    col += dotCol * dot_ * decay * 3.0;
  }

  // trace of vignette so the tube feels curved even in death
  float vig = 1.0 - 0.35 * pow(length(uv - 0.5) * 1.4, 2.0);
  col *= vig;

  col = quantize(col, 12.0);

  fragColor = vec4(col, 1.0) * qt_Opacity;
}
