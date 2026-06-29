#version 300 es
precision highp float;

// DOORway subtle CRT screen shader.
// Ported from the RETRO_LIB on the user's website (MarkusBitterman.github.io): scanlines +
// vignette ONLY, deliberately gentle so text stays crisp (no snow/quantize/RF-jitter here).
// Hyprland decoration:screen_shader interface — same as services/hyprlandAntiFlashbangShader.

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

void main() {
    vec2 uv = v_texcoord;
    vec4 pix = texture(tex, uv);
    vec3 col = pix.rgb;

    // --- Scanlines: gentle periodic darkening between rows (resolution-independent) ---
    float line = sin(uv.y * 1080.0 * 3.14159265) * 0.5 + 0.5; // 0 in the trough, 1 on the line
    col *= 1.0 - 0.06 * (1.0 - line);                          // up to ~6% darkening — subtle

    // --- Vignette: subtle tube-curvature darkening toward the corners ---
    vec2 d = uv - vec2(0.5);
    float r = dot(d, d);                       // 0 at center → 0.5 at corners
    col *= 1.0 - 0.18 * smoothstep(0.10, 0.55, r);

    fragColor = vec4(col, pix.a);
}
