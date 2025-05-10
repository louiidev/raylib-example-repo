#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

uniform sampler2D texture0;
uniform float time;

out vec4 finalColor;

// === Adjustable CRT Parameters (INLINE) ===
#define CURVE_AMOUNT       0.02    // 0.0 = off, 0.2 = curved
#define SCANLINE_INTENSITY 0.05    // 0.0 to 1.0
#define SCANLINE_DENSITY   1.0    // 1.0 = every line, 2.0 = every 2nd line
#define VIGNETTE_AMOUNT    0.01     // 0.0 = none, 1.0 = strong

#define RGB_SHIFT          (1.0 / 1280) // Horizontal pixel offset (based on screen width)
#define FLICKER_STRENGTH   0.03    // 0.0 = none, 0.03 = subtle
#define RENDER_WIDTH       640.0
#define RENDER_HEIGHT      320.0

// === Barrel distortion ===
vec2 curveUV(vec2 uv) {
    uv = uv * 2.0 - 1.0;
    float radius = length(uv);
    uv *= 1.0 + CURVE_AMOUNT * radius * radius;
    return uv * 0.5 + 0.5;
}

// === Vignette ===
float vignette(vec2 uv) {
    float d = distance(uv, vec2(0.5));
    return mix(1.0, smoothstep(0.8, 0.5, d), VIGNETTE_AMOUNT);
}

// === Scanlines ===
float scanline(vec2 uv) {
    return 1.0 - SCANLINE_INTENSITY * (0.5 + 0.5 * sin(uv.y * RENDER_HEIGHT * 3.14159 * SCANLINE_DENSITY));
}

// === Chromatic aberration ===
vec3 chromaticAberration(vec2 uv) {
    vec2 offset = vec2(RGB_SHIFT, 0.0);
    float r = texture(texture0, uv + offset).r;
    float g = texture(texture0, uv).g;
    float b = texture(texture0, uv - offset).b;
    return vec3(r, g, b);
}

void main() {
    vec2 uv = fragTexCoord;

    // Apply screen curvature
    uv = curveUV(uv);
    if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
        finalColor = vec4(0.0); // Outside screen
        return;
    }

    // Color with RGB shift
    vec3 color = chromaticAberration(uv);

    // Apply scanlines
    color *= scanline(uv);

    // Apply vignette
    color *= vignette(uv);

    // Flicker effect
    color *= 1.0 - FLICKER_STRENGTH + FLICKER_STRENGTH * sin(time * 60.0);

    finalColor = vec4(color, 1.0);
}
