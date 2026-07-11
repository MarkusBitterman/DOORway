// "ENCOM Boardroom — Data Flow" — the DOORway right-sidebar backdrop.
// Spiritual port of the ENCOM Boardroom (TRON: Legacy) recolored to DOORway:
// a faint blue grid, vertical signal lanes carrying sharp gold ping-packets,
// and pulsing data-nodes at grid intersections, all on ink black. uActivity
// (0..1, from live net/CPU load) surges the flow so the surface reads as a
// boardroom screen monitoring live data.
//
// Self-contained: the hash it needs is inlined so this shader dir does not
// depend on the lock shaders' retro_lib.glsl.

// DOORway palette (matches modules/common/DoorwayPalette.qml)
const vec3 INK  = vec3(0.110, 0.110, 0.110); // #1C1C1C inkBlack
const vec3 HERO = vec3(0.122, 0.235, 0.533); // #1F3C88 heroBlue
const vec3 SKY  = vec3(0.435, 0.639, 0.851); // #6FA3D9 skyHint
const vec3 GOLD = vec3(1.000, 0.761, 0.055); // #FFC20E powerGold

float hash11(float n) { return fract(sin(n * 127.1) * 43758.5453); }

void main() {
    // 0..1 with y pointing up; qt_TexCoord0 has y flipped vs. our convention.
    vec2 uv = vec2(qt_TexCoord0.x, 1.0 - qt_TexCoord0.y);
    float aspect = iResolution.x / iResolution.y;
    float act = clamp(uActivity, 0.0, 1.0);

    vec3 col = INK;

    // --- boardroom grid ---
    const float LANES = 13.0;
    float lx = uv.x * LANES;
    float laneId = floor(lx);
    float laneFrac = fract(lx);

    // crisp vertical lane rails
    float rail = smoothstep(0.045, 0.012, abs(laneFrac - 0.5));
    col += HERO * rail * (0.10 + act * 0.10);

    // faint horizontal grid rows
    const float ROWS = 20.0;
    float rowFrac = fract(uv.y * ROWS);
    float rowLine = smoothstep(0.06, 0.0, abs(rowFrac - 0.5));
    col += HERO * rowLine * 0.05;

    // soft column envelope so packets hug their lane centre
    float column = smoothstep(0.30, 0.02, abs(laneFrac - 0.5));

    // --- traveling comet-packets ---
    float blue = 0.0;   // soft halo + trailing tail (hero→sky)
    float gold = 0.0;   // sharp ping core

    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float seed = laneId * 7.13 + fi * 31.7;
        float speed = 0.14 + hash11(seed) * 0.30 + act * 0.40;
        float phase = hash11(seed + 3.0);
        float bright = 0.45 + hash11(seed + 7.0) * 0.55; // some lanes dimmer

        float q = uv.y - iTime * speed - phase;
        float t = fract(q);

        float core = exp(-t * 150.0);        // near-point ping (the pop)
        float halo = exp(-t * 22.0);         // glow around the head
        float tail = exp(-(1.0 - t) * 13.0); // short trail behind — no smear

        blue += (halo + tail * 0.5) * column * bright;
        gold += core * column * bright;
    }

    vec3 flowCol = mix(HERO, SKY, uv.y);
    col += flowCol * blue * (0.60 + act * 0.90);
    col += GOLD * gold * (1.20 + act * 1.30);   // pings pop against the blue

    // --- pulsing data-nodes at grid intersections ---
    // rail*rowLine is only non-zero where a lane crosses a row; a per-node hash
    // keeps most dark and lets a sparse few pulse.
    float nodeSeed = hash11(laneId * 3.1 + floor(uv.y * ROWS) * 5.7);
    float nodePulse = step(0.90, nodeSeed) * (0.5 + 0.5 * sin(iTime * 3.0 + nodeSeed * 30.0));
    col += GOLD * (rail * rowLine) * nodePulse * (0.6 + act * 0.6);

    // --- horizontal scan sweep crossing the screen ---
    float sweepPos = fract(iTime * 0.07);
    float sweep = exp(-abs(uv.y - sweepPos) * 70.0);
    col += SKY * sweep * (0.06 + act * 0.18);

    // --- screen finish: scanlines + vignette ---
    float scan = 0.92 + 0.08 * sin(uv.y * iResolution.y * 3.14159);
    col *= scan;

    vec2 vc = (uv - 0.5) * vec2(aspect, 1.0);
    col *= 0.80 + 0.20 * smoothstep(1.25, 0.35, length(vc));

    fragColor = vec4(col, 1.0);
}
