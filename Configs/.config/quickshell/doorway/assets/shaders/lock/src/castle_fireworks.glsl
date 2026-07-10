// "Castle Fireworks" — ported from shader-hero.js SHADERS["thank-you"].
// SMB end-of-level celebration: shaped rainbow bursts (mushroom/star/tulip)
// over the Old Iowa Capitol, stars twinkling in the night sky.

const vec3 NIGHT_SKY      = vec3(0.051, 0.047, 0.180);
const vec3 CASTLE_SHADOW  = vec3(0.090, 0.082, 0.137);
const vec3 POWER_GOLD     = vec3(1.000, 0.761, 0.055);
const vec3 STAR_WHITE     = vec3(0.980, 0.980, 0.980);

// Rainbow colors for fireworks
const vec3 FW_RED         = vec3(0.902, 0.000, 0.071);
const vec3 FW_ORANGE      = vec3(1.000, 0.600, 0.000);
const vec3 FW_YELLOW      = vec3(1.000, 0.900, 0.000);
const vec3 FW_GREEN       = vec3(0.000, 0.800, 0.200);
const vec3 FW_BLUE        = vec3(0.122, 0.400, 0.900);
const vec3 FW_INDIGO      = vec3(0.294, 0.000, 0.510);
const vec3 FW_VIOLET      = vec3(0.580, 0.000, 0.827);
const vec3 FW_WHITE       = vec3(0.980, 0.980, 0.980);

// Burst shape positions: dots arranged in mushroom/star/tulip outlines

// Mushroom outline: cap arc + stem sides
vec2 mushroomPoint(float i, float count) {
  float t = i / count;
  if (t < 0.6) {
    float a = 3.14159 * (t / 0.6);
    return vec2(cos(a) * 1.0, sin(a) * 0.8 + 0.2);
  } else if (t < 0.8) {
    float s = (t - 0.6) / 0.2;
    return vec2(0.4, 0.2 - s * 1.0);
  } else {
    float s = (t - 0.8) / 0.2;
    return vec2(-0.4, -0.8 + s * 1.0);
  }
}

// Star outline: 5-pointed star vertices connected
vec2 starPoint(float i, float count) {
  float t = i / count;
  float totalAngle = t * 6.283;
  float pointIndex = t * 10.0;
  float r = (fract(pointIndex * 0.5) < 0.25) ? 1.0 : 0.45;
  float a = totalAngle - 1.5708; // start from top
  return vec2(cos(a) * r, sin(a) * r);
}

// Tulip outline: three petals + stem
vec2 tulipPoint(float i, float count) {
  float t = i / count;
  if (t < 0.25) {
    float a = 3.14159 * (t / 0.25);
    return vec2(cos(a) * 0.5 - 0.55, sin(a) * 0.6 + 0.3);
  } else if (t < 0.5) {
    float a = 3.14159 * ((t - 0.25) / 0.25);
    return vec2(cos(a) * 0.5, sin(a) * 0.7 + 0.5);
  } else if (t < 0.75) {
    float a = 3.14159 * ((t - 0.5) / 0.25);
    return vec2(cos(a) * 0.5 + 0.55, sin(a) * 0.6 + 0.3);
  } else {
    float s = (t - 0.75) / 0.25;
    return vec2(0.0, 0.3 - s * 1.3);
  }
}

// pick shape point based on seed
vec2 shapePoint(float i, float count, float shapeId) {
  if (shapeId < 0.33) return mushroomPoint(i, count);
  if (shapeId < 0.66) return starPoint(i, count);
  return tulipPoint(i, count);
}

// Enhanced firework with launch, burst, and falling particles
float firework(vec2 p, float t, float seed) {
  float cycle = fract(t * 0.15 + seed); // slower cycle
  float shapeId = fract(seed * 7.13); // pick shape per firework
  float result = 0.0;

  // Phase 1: Launch (0.0 - 0.25) - spiraling rocket trail
  if (cycle < 0.25) {
    float launchPhase = cycle / 0.25;
    float launchHeight = launchPhase;

    float spiralAngle = launchPhase * 12.0;
    vec2 spiralOffset = vec2(cos(spiralAngle), sin(spiralAngle)) * 0.03 * (1.0 - launchPhase);
    vec2 launchPos = vec2(spiralOffset.x, -0.8 + launchHeight * 1.2);

    float launchDist = length(p - launchPos);
    float trail = exp(-launchDist * 80.0) * (0.5 + 0.5 * hash(vec2(launchPhase * 10.0)));

    for (float i = 0.0; i < 5.0; i++) {
      float trailT = launchPhase - i * 0.05;
      if (trailT > 0.0) {
        float trailSpiral = trailT * 12.0;
        vec2 trailSpiralOffset = vec2(cos(trailSpiral), sin(trailSpiral)) * 0.03 * (1.0 - trailT);
        vec2 trailPos = vec2(trailSpiralOffset.x, -0.8 + trailT * 1.2);
        float trailSegDist = length(p - trailPos);
        trail += exp(-trailSegDist * 60.0) * 0.3 * (1.0 - i / 5.0);
      }
    }

    result = trail;
  }
  // Phase 2: Burst (0.25 - 0.45) - dots arranged in shape
  else if (cycle < 0.45) {
    float burstPhase = (cycle - 0.25) / 0.2;
    float radius = burstPhase * 0.3;

    float dist = length(p);

    float particleCount = 24.0;
    for (float i = 0.0; i < 24.0; i++) {
      vec2 shapePos = shapePoint(i, particleCount, shapeId) * radius;
      float d = length(p - shapePos);
      result += exp(-d * 100.0) * (1.0 - burstPhase * 0.7);
    }

    // central flash
    float flash = exp(-dist * 30.0) * smoothstep(0.2, 0.0, burstPhase);
    result += flash * 2.0;
  }
  // Phase 3: Fall (0.45 - 1.0) - dots fall DOWN AND AWAY from shape
  else if (cycle < 1.0) {
    float fallPhase = (cycle - 0.45) / 0.55;
    float burstRadius = 0.3;

    float particleCount = 24.0;
    for (float i = 0.0; i < 24.0; i++) {
      vec2 shapePos = shapePoint(i, particleCount, shapeId) * burstRadius;

      vec2 dir = normalize(shapePos + vec2(0.0, 0.001));
      vec2 momentum = dir * fallPhase * 0.2;
      vec2 gravity = vec2(0.0, -fallPhase * fallPhase * 0.5);
      vec2 particlePos = shapePos + momentum + gravity;

      float particleDist = length(p - particlePos);
      float particle = exp(-particleDist * 80.0) * (1.0 - fallPhase * 0.8);

      // decay trail — longer arc behind each falling dot
      for (float j = 1.0; j < 8.0; j++) {
        float trailT = max(fallPhase - j * 0.03, 0.0);
        vec2 trailMomentum = dir * trailT * 0.2;
        vec2 trailGravity = vec2(0.0, -trailT * trailT * 0.5);
        vec2 trailPos = shapePos + trailMomentum + trailGravity;
        float trailDist = length(p - trailPos);
        float trailFade = (1.0 - j / 8.0) * (1.0 - j / 8.0);
        particle += exp(-trailDist * 50.0) * 0.25 * (1.0 - fallPhase * 0.6) * trailFade;
      }

      result += particle;
    }
  }

  return result * 1.2;
}

// Old Iowa Capitol building — neoclassical with gold dome
float capitolShape(vec2 uv, out float goldDome, out float windowMask, out float stairMask, out float columnMask) {
  float y = uv.y;
  float x = uv.x - 0.5;
  float ax = abs(x);

  goldDome = 0.0;
  windowMask = 0.0;
  stairMask = 0.0;
  columnMask = 0.0;
  float doorMask = 0.0;

  // ── FRONT STAIRS (wide at bottom, narrow at top) ──
  float s1 = step(y, 0.02) * step(ax, 0.38);
  float s2 = step(0.02, y) * step(y, 0.04) * step(ax, 0.34);
  float s3 = step(0.04, y) * step(y, 0.06) * step(ax, 0.30);
  float s4 = step(0.06, y) * step(y, 0.08) * step(ax, 0.26);
  float s5 = step(0.08, y) * step(y, 0.10) * step(ax, 0.22);
  stairMask = max(s1, max(s2, max(s3, max(s4, s5))));

  // ── MAIN BUILDING BODY (wide, 2 stories) ──
  float body = step(0.10, y) * step(y, 0.32) * step(ax, 0.44);

  // ── WINDOWS (two rows across body, evenly spaced) ──
  float winRow = step(0.22, y) * step(y, 0.30) * step(ax, 0.42);
  float winPattern = step(0.3, fract(ax * 12.0)) * step(fract(ax * 12.0), 0.7);
  windowMask = winRow * winPattern;

  // ── CENTRAL PORTICO (narrower, with 4 tall columns) ──
  float portico = step(0.10, y) * step(y, 0.34) * step(ax, 0.18);

  float col1 = step(0.10, y) * step(y, 0.34) * step(abs(ax - 0.04), 0.008);
  float col2 = step(0.10, y) * step(y, 0.34) * step(abs(ax - 0.10), 0.008);
  float col3 = step(0.10, y) * step(y, 0.34) * step(abs(ax - 0.16), 0.008);
  columnMask = max(col1, max(col2, col3));

  // ── FRONT DOOR (centered in portico, below columns) ──
  float doorW = 0.025;
  float doorH1 = step(0.10, y) * step(y, 0.19) * step(ax, doorW);
  float doorH2 = step(0.19, y) * step(y, 0.22) * step(ax, doorW * 0.7); // arched top
  doorMask = max(doorH1, doorH2);

  // ── PEDIMENT (triangle above portico) ──
  float pedimentTop = 0.34 + (0.20 - ax) * 0.3;
  float pediment = step(0.34, y) * step(y, pedimentTop) * step(ax, 0.20);

  // ── CORNICE / ROOFLINE (thin line across full body width) ──
  float cornice = step(0.32, y) * step(y, 0.34) * step(ax, 0.44);

  // ── DRUM (octagonal base for dome, narrower) ──
  float drum = step(0.40, y) * step(y, 0.44) * step(ax, 0.10);

  // ── DOME BASE (flattened top under gold cap) ──
  float domeBase = step(0.44, y) * step(y, 0.48) * step(ax, 0.09) * step(y, 0.46 + 0.02 * (1.0 - ax / 0.09));

  // ── GOLD DOME (cap, sits on flattened dome base) ──
  float gd1 = step(0.48, y) * step(y, 0.52) * step(ax, 0.07);
  float gd2 = step(0.52, y) * step(y, 0.55) * step(ax, 0.04);
  goldDome = max(gd1, gd2);

  // ── CUPOLA (small lantern on top of dome) ──
  float cupola = step(0.55, y) * step(y, 0.58) * step(ax, 0.015);

  // ── FLAGPOLE ──
  float flagPole = step(0.58, y) * step(y, 0.64) * step(ax, 0.004);

  // ── FLAG ──
  float flag = step(0.62, y) * step(y, 0.64) * step(x, 0.02) * step(-0.004, x);

  // combine stone parts (add domeBase, cut out door)
  float stone = max(stairMask, max(body, max(portico, max(pediment, max(cornice, max(drum, max(domeBase, max(cupola, max(flagPole, flag)))))))));

  // cut out windows and door
  stone *= (1.0 - windowMask * 0.7);
  stone *= (1.0 - doorMask * 0.95);

  return stone;
}

void main() {
  vec2 fragCoord = vec2(qt_TexCoord0.x, 1.0 - qt_TexCoord0.y) * iResolution;
  vec2 uv = fragCoord / iResolution.xy;
  vec2 p = (fragCoord * 2.0 - iResolution.xy) / iResolution.y;

  // jitter from RETRO_LIB
  p.x += rfJitter(uv.y, iTime);

  // night sky base (dark)
  vec3 col = NIGHT_SKY;

  // compute building masks first
  float goldDomeMask, windowMask, stairMask, columnMask;
  float capitol = capitolShape(uv, goldDomeMask, windowMask, stairMask, columnMask);

  // twinkling stars (only in sky, not behind building)
  float starField = hash(floor(uv * 40.0));
  float starTwinkle = step(0.96, starField) * (0.5 + 0.5 * sin(iTime * 3.0 + starField * 100.0));
  float buildingBlock = max(capitol, goldDomeMask);
  col = mix(col, STAR_WHITE, starTwinkle * 0.6 * (1.0 - buildingBlock));

  // 8 fireworks spread wide across the sky (rainbow)
  vec3 fireworkCol = vec3(0.0);

  fireworkCol += FW_RED    * firework(p - vec2(-0.9, 0.3),  iTime, 0.0);
  fireworkCol += FW_ORANGE * firework(p - vec2(0.9, 0.4),   iTime, 0.14);
  fireworkCol += FW_YELLOW * firework(p - vec2(-0.6, 0.6),  iTime, 0.28);
  fireworkCol += FW_GREEN  * firework(p - vec2(0.7, 0.2),   iTime, 0.42);
  fireworkCol += FW_BLUE   * firework(p - vec2(-0.2, 0.7),  iTime, 0.56);
  fireworkCol += FW_INDIGO * firework(p - vec2(0.85, 0.5),  iTime, 0.70);
  fireworkCol += FW_VIOLET * firework(p - vec2(-0.8, 0.15), iTime, 0.84);
  fireworkCol += FW_WHITE  * firework(p - vec2(0.3, 0.55),  iTime, 0.07);

  // add fireworks with bloom
  col += fireworkCol;
  col += fireworkCol * 0.3; // bloom glow

  // ── GROUND PLANE: green grass over brown dirt, with magenta wash ──
  float groundY = 0.10; // base of lowest step
  float grassY = 0.06;  // top of grass, just below steps
  float dirtY = 0.0;    // bottom of dirt
  float magentaWash = smoothstep(0.6, 0.0, uv.y);
  float dirtMask = smoothstep(grassY, dirtY, uv.y);
  float grassMask = smoothstep(groundY, grassY, uv.y);
  vec3 grassCol = vec3(0.373, 0.686, 0.227); // koholint-grass
  vec3 dirtCol = vec3(0.541, 0.310, 0.165);  // owl-umber
  col = mix(col, dirtCol, dirtMask);
  col = mix(col, grassCol, grassMask);
  col += vec3(0.6, 0.0, 0.4) * magentaWash;

  // Draw building: stone body
  col = mix(col, CASTLE_SHADOW, capitol);

  // Stairs: slightly lighter stone
  col = mix(col, CASTLE_SHADOW * 1.4, stairMask);

  // Columns: bright highlight lines
  col = mix(col, CASTLE_SHADOW * 2.0, columnMask);

  // Front door: deep shadow (almost black)
  float doorW = 0.025;
  float doorH1 = step(0.10, uv.y) * step(uv.y, 0.19) * step(abs(uv.x - 0.5), doorW);
  float doorH2 = step(0.19, uv.y) * step(uv.y, 0.22) * step(abs(uv.x - 0.5), doorW * 0.7);
  float doorMask = max(doorH1, doorH2);
  col = mix(col, vec3(0.08, 0.07, 0.13), doorMask);

  // Draw gold dome on top
  col = mix(col, POWER_GOLD * 0.85, goldDomeMask);

  // Lit windows: warm gold glow
  col = mix(col, POWER_GOLD * 0.7, windowMask * 0.6);

  // CRT vignette
  float vig = 1.0 - 0.3 * pow(length(uv - 0.5) * 1.2, 2.0);
  col *= vig;

  // subtle snow
  float s = snow(uv, iTime);
  col = mix(col, vec3(s), 0.06);

  // scanlines
  col *= scanline(uv, iResolution.y * 0.5, 0.25);

  // NES color quantization
  col = quantize(col, 12.0);

  fragColor = vec4(col, 1.0) * qt_Opacity;
}
