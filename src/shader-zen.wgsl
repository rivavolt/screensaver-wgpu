// ZEN: Living Meditation
// Minimal yet alive - like a garden at dusk with fireflies
// Enhanced with more dynamic elements while keeping the calm aesthetic

struct Uniforms {
    resolution: vec2<f32>,
    time: f32,
    _padding: f32,
}

@group(0) @binding(0)
var<uniform> uniforms: Uniforms;

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
}

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOutput {
    var positions = array<vec2<f32>, 6>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>(1.0, -1.0),
        vec2<f32>(1.0, 1.0),
        vec2<f32>(-1.0, -1.0),
        vec2<f32>(1.0, 1.0),
        vec2<f32>(-1.0, 1.0),
    );

    var out: VertexOutput;
    out.position = vec4<f32>(positions[vertex_index], 0.0, 1.0);
    out.uv = positions[vertex_index] * 0.5 + 0.5;
    return out;
}

const PI: f32 = 3.14159265359;
const TAU: f32 = 6.28318530718;

fn hash(p: vec2<f32>) -> f32 {
    return fract(sin(dot(p, vec2<f32>(127.1, 311.7))) * 43758.5453);
}

fn noise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2<f32>(1.0, 0.0)), u.x),
               mix(hash(i + vec2<f32>(0.0, 1.0)), hash(i + vec2<f32>(1.0, 1.0)), u.x), u.y);
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.uv;
    var u = (2.0 * uv.x - 1.0) * uniforms.resolution.x / uniforms.resolution.y;
    var v = 2.0 * uv.y - 1.0;

    let t = uniforms.time * 0.1;
    var col = vec3<f32>(0.0);

    // ========== ENSO - The Living Circle ==========
    let angle = atan2(v, u);
    let radius = sqrt(u * u + v * v);

    // Circle breathes gently
    let breath = 0.4 + 0.06 * sin(t * 0.5) + 0.02 * sin(t * 0.7);

    // Organic wobble
    var wobble = 0.025 * sin(angle * 3.0 + t);
    wobble += 0.015 * sin(angle * 7.0 - t * 0.7);
    wobble += 0.008 * sin(angle * 11.0 + t * 1.3);

    // Brush stroke thickness varies
    let brush_width = 0.035 + 0.02 * sin(angle * 2.0 + t * 0.3);
    let dist_to_circle = abs(radius - breath - wobble);

    // Gap in circle that slowly moves
    let gap_pos = t * 0.03;
    let gap = smoothstep(0.0, 0.35, abs(angle - 2.5 + gap_pos));

    var enso = exp(-dist_to_circle * dist_to_circle / (brush_width * brush_width)) * gap;
    enso *= 0.75;

    // Ink color - warm cream/white
    col += enso * vec3<f32>(0.92, 0.88, 0.82);

    // ========== RIPPLES - Concentric waves ==========
    for (var i = 0; i < 3; i++) {
        let fi = f32(i);
        let ripple_center = vec2<f32>(
            sin(t * 0.2 + fi * 2.0) * 0.3,
            cos(t * 0.15 + fi * 1.7) * 0.2
        );
        let rd = length(vec2<f32>(u, v) - ripple_center);
        let ripple_phase = rd * 25.0 - t * 2.5 - fi * 1.5;
        var ripple = sin(ripple_phase) * 0.5 + 0.5;
        ripple *= exp(-rd * 5.0);
        ripple *= 0.04;

        col += ripple * vec3<f32>(0.5 + fi * 0.1, 0.6 + fi * 0.1, 0.75);
    }

    // ========== FIREFLIES - Living light particles ==========
    for (var i = 0; i < 15; i++) {
        let fi = f32(i);
        let seed1 = hash(vec2<f32>(fi, fi * 0.7));
        let seed2 = hash(vec2<f32>(fi * 1.3, fi * 0.3));

        // Complex floating motion
        let fx = (seed1 - 0.5) * 1.8 + 0.3 * sin(t * (0.2 + seed1 * 0.15) + fi * 2.1);
        let fy = (seed2 - 0.5) * 1.4 + 0.25 * sin(t * (0.15 + seed2 * 0.1) + fi * 1.3);

        let dx = u - fx;
        let dy = v - fy;
        let d = sqrt(dx * dx + dy * dy);

        // Glow pulse - each firefly has its own rhythm
        let pulse_speed = 1.5 + seed1 * 2.0;
        let pulse_phase = t * pulse_speed + fi * 1.7;
        let glow_intensity = pow(sin(pulse_phase) * 0.5 + 0.5, 3.0);

        var firefly = exp(-d * d * 400.0) * glow_intensity;
        firefly *= 0.6;

        // Warm golden-green color like real fireflies
        let hue = 0.15 + seed1 * 0.1;
        col += firefly * vec3<f32>(0.9, 0.85 - hue * 0.3, 0.3 + hue * 0.2);
    }

    // ========== FLOWING WAVES - Water surface ==========
    for (var i = 0; i < 3; i++) {
        let fi = f32(i);
        let wave_base = -0.5 + fi * 0.15;
        var wave_y = wave_base + 0.08 * sin(u * 2.5 + t * 0.8 + fi);
        wave_y += 0.04 * sin(u * 5.0 - t * 1.2 + fi * 2.0);
        wave_y += 0.02 * sin(u * 9.0 + t * 0.5 + fi * 3.0);

        let wave_dist = abs(v - wave_y);
        var wave = exp(-wave_dist * wave_dist * 80.0);
        wave *= smoothstep(-1.8, 0.8, -u) * smoothstep(-1.8, 0.8, u);
        wave *= 0.12 - fi * 0.02;

        // Blue-grey ink wash
        col += wave * vec3<f32>(0.35, 0.45, 0.55);
    }

    // ========== AURORA WISPS ==========
    for (var i = 0; i < 4; i++) {
        let fi = f32(i);
        let wisp_y = sin(t * 0.1 + fi * 1.5) * 0.4 + fi * 0.15 - 0.2;
        var wisp_wave = v - wisp_y;
        wisp_wave += 0.15 * sin(u * 3.0 + t * 0.5 + fi);
        wisp_wave += 0.08 * sin(u * 6.0 - t * 0.8 + fi * 2.0);

        var wisp = exp(-wisp_wave * wisp_wave * 20.0);
        wisp *= smoothstep(0.0, 0.5, 0.7 + 0.3 * sin(t * 0.2 + fi));
        wisp *= 0.06;

        // Soft color gradient
        let wisp_hue = fi * 0.2 + t * 0.05;
        col += wisp * vec3<f32>(
            0.3 + 0.2 * sin(wisp_hue * TAU),
            0.5 + 0.2 * sin(wisp_hue * TAU + 2.0),
            0.6 + 0.2 * sin(wisp_hue * TAU + 4.0)
        );
    }

    // ========== MOON ==========
    let moon_x = u - 0.65;
    let moon_y = v - 0.55;
    let moon_d = sqrt(moon_x * moon_x + moon_y * moon_y);

    // Glowing moon
    var moon = exp(-moon_d * moon_d * 25.0);
    moon *= 0.15 * (0.8 + 0.2 * sin(t * 0.08));

    // Moon halo
    let halo = exp(-moon_d * moon_d * 4.0) * 0.06;

    col += (moon + halo) * vec3<f32>(0.75, 0.85, 1.0);

    // ========== STARS - Twinkling ==========
    for (var i = 0; i < 20; i++) {
        let fi = f32(i);
        let star_x = hash(vec2<f32>(fi * 127.1, fi)) * 3.0 - 1.5;
        let star_y = hash(vec2<f32>(fi, fi * 311.7)) * 2.0 - 1.0;

        // Only show stars in upper portion and away from moon
        if (star_y > -0.2 && length(vec2<f32>(star_x - 0.65, star_y - 0.55)) > 0.3) {
            let dx = u - star_x;
            let dy = v - star_y;
            let d = sqrt(dx * dx + dy * dy);

            let twinkle_speed = 2.0 + hash(vec2<f32>(fi * 1.3, fi * 0.7)) * 3.0;
            let twinkle = 0.5 + 0.5 * sin(t * twinkle_speed + fi * 2.0);

            let star = exp(-d * d * 8000.0) * twinkle * 0.5;
            col += vec3<f32>(star);
        }
    }

    // ========== GRASS SILHOUETTES ==========
    for (var i = 0; i < 30; i++) {
        let fi = f32(i);
        let grass_x = (fi / 30.0) * 3.0 - 1.5;
        let grass_height = 0.1 + hash(vec2<f32>(fi, 0.0)) * 0.15;
        let sway = sin(t * 0.8 + fi * 0.3) * 0.02 * (v + 0.8);

        let grass_tip = vec2<f32>(grass_x + sway, -0.8 + grass_height);
        let grass_base = vec2<f32>(grass_x, -0.85);

        // Distance to line segment (blade of grass)
        let ba = grass_tip - grass_base;
        let pa = vec2<f32>(u, v) - grass_base;
        let h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
        let d = length(pa - ba * h);

        let grass = exp(-d * d * 5000.0) * 0.3;
        col += grass * vec3<f32>(0.15, 0.2, 0.15);
    }

    // ========== PAPER TEXTURE ==========
    let tex_x = floor(u * 80.0);
    let tex_y = floor(v * 80.0);
    let paper = hash(vec2<f32>(tex_x, tex_y));
    let texture_strength = (col.r + col.g + col.b) * 0.015;
    col += vec3<f32>(paper * texture_strength);

    // ========== FINAL ==========
    // Subtle overall breathing
    col *= 0.9 + 0.1 * sin(t * 0.3);

    // Gamma for OLED
    col = pow(max(col, vec3<f32>(0.0)), vec3<f32>(0.92));

    // Clamp
    col = min(col, vec3<f32>(0.9));

    // True black threshold
    col = max(col - 0.015, vec3<f32>(0.0));

    return vec4<f32>(col, 1.0);
}
