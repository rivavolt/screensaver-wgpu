// OLED Dreamscape - vibrant kaleidoscope with guaranteed darkness
// Go wild but protect the screen

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

fn hash3(p: vec2<f32>) -> vec3<f32> {
    return vec3<f32>(
        hash(p),
        hash(p + vec2<f32>(37.0, 17.0)),
        hash(p + vec2<f32>(59.0, 83.0))
    );
}

fn noise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2<f32>(1.0, 0.0)), u.x),
               mix(hash(i + vec2<f32>(0.0, 1.0)), hash(i + vec2<f32>(1.0, 1.0)), u.x), u.y);
}

fn fbm(p_in: vec2<f32>) -> f32 {
    var p = p_in;
    var v: f32 = 0.0;
    var a: f32 = 0.5;
    let rot = mat2x2<f32>(0.8, 0.6, -0.6, 0.8);
    for (var i: i32 = 0; i < 6; i++) {
        v += a * noise(p);
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

// Rich color palettes
fn palette1(t: f32) -> vec3<f32> {
    return 0.5 + 0.5 * cos(TAU * (t + vec3<f32>(0.0, 0.33, 0.67)));
}

fn palette2(t: f32) -> vec3<f32> {
    return 0.5 + 0.5 * cos(TAU * (t * vec3<f32>(1.0, 0.8, 0.6) + vec3<f32>(0.0, 0.1, 0.2)));
}

fn palette3(t: f32) -> vec3<f32> {
    return 0.5 + 0.45 * cos(TAU * (t + vec3<f32>(0.1, 0.4, 0.7)));
}

// Signed distance to a line segment
fn sdSegment(p: vec2<f32>, a: vec2<f32>, b: vec2<f32>) -> f32 {
    let pa = p - a;
    let ba = b - a;
    let h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    return length(pa - ba * h);
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.uv;
    var p = (uv * 2.0 - 1.0);
    p.x *= uniforms.resolution.x / uniforms.resolution.y;

    let t = uniforms.time * 0.12;
    var col = vec3<f32>(0.0);

    // === LAYER 1: Deep space nebula wisps ===
    let neb1 = fbm(p * 1.5 + t * 0.15);
    let neb2 = fbm(p * 2.0 - t * 0.1 + vec2<f32>(5.0, 3.0));
    let nebula = neb1 * neb2;
    col += palette3(nebula + t * 0.1) * nebula * nebula * 0.15;

    // === LAYER 2: The legendary fractal kaleidoscope ===
    var z = p;
    let p0 = p;

    for (var i: f32 = 0.0; i < 4.0; i += 1.0) {
        z = fract(z * 1.5) - 0.5;

        var d = length(z) * exp(-length(p0));
        d = sin(d * 8.0 + t * 2.5) / 8.0;
        d = abs(d);
        d = pow(0.01 / d, 1.2);

        col += palette1(length(p0) + i * 0.4 + t * 0.4) * d * 0.35;
    }

    // === LAYER 3: Morphing geometric rings ===
    for (var i: f32 = 0.0; i < 3.0; i += 1.0) {
        let ring_center = vec2<f32>(
            sin(t * 0.3 + i * 2.0) * 0.3,
            cos(t * 0.25 + i * 2.5) * 0.25
        );
        let ring_dist = length(p - ring_center);
        let ring_radius = 0.3 + sin(t * 0.5 + i) * 0.1;
        let ring_thick = 0.02 + sin(t + i * 1.5) * 0.01;

        let ring = smoothstep(ring_thick, 0.0, abs(ring_dist - ring_radius));
        col += palette2(i * 0.3 + t * 0.2) * ring * 0.5;
    }

    // === LAYER 4: Flowing light tendrils ===
    for (var i: f32 = 0.0; i < 5.0; i += 1.0) {
        let angle = t * 0.2 + i * TAU / 5.0;
        let tendril_start = vec2<f32>(cos(angle), sin(angle)) * 0.1;
        let curve = sin(t * 0.4 + i * 1.3) * 0.5;

        for (var j: f32 = 0.0; j < 8.0; j += 1.0) {
            let seg_t = j / 8.0;
            let seg_angle = angle + seg_t * curve * 3.0;
            let seg_pos = vec2<f32>(cos(seg_angle), sin(seg_angle)) * (0.1 + seg_t * 0.6);

            let d = length(p - seg_pos);
            let glow = exp(-d * 15.0) * (1.0 - seg_t * 0.7);
            col += palette1(i * 0.2 + seg_t + t * 0.3) * glow * 0.08;
        }
    }

    // === LAYER 5: Dancing orbs with trails ===
    for (var i: f32 = 0.0; i < 6.0; i += 1.0) {
        let phase = i * 1.047 + t * (0.25 + i * 0.05);
        let orb_pos = vec2<f32>(
            sin(phase) * (0.45 + sin(t * 0.2 + i * 2.0) * 0.15),
            cos(phase * 0.7 + i) * (0.35 + cos(t * 0.15 + i) * 0.12)
        );

        // Main orb
        let d = length(p - orb_pos);
        let pulse = 0.08 + sin(t * 1.5 + i * 1.2) * 0.02;
        let core = smoothstep(pulse, pulse * 0.2, d);
        let glow = exp(-d * 6.0) * 0.4;

        let orb_col = palette2(i * 0.16 + t * 0.1);
        col += orb_col * (core * 0.6 + glow);

        // Trail
        for (var j: f32 = 1.0; j < 5.0; j += 1.0) {
            let trail_phase = phase - j * 0.15;
            let trail_pos = vec2<f32>(
                sin(trail_phase) * (0.45 + sin(t * 0.2 + i * 2.0) * 0.15),
                cos(trail_phase * 0.7 + i) * (0.35 + cos(t * 0.15 + i) * 0.12)
            );
            let trail_d = length(p - trail_pos);
            let trail_glow = exp(-trail_d * 10.0) * (0.2 / j);
            col += orb_col * trail_glow * 0.5;
        }
    }

    // === LAYER 6: Electric aurora waves ===
    for (var i: f32 = 0.0; i < 4.0; i += 1.0) {
        let wave_x = p.x + sin(p.y * 3.0 + t + i) * 0.2;
        let wave_y = sin(wave_x * 4.0 + t * (0.8 + i * 0.2) + i * 1.5) * 0.2;
        let wave_dist = abs(p.y - wave_y - 0.3 + i * 0.15);
        let wave = exp(-wave_dist * 10.0) * 0.2;

        col += palette3(p.x + t * 0.15 + i * 0.25) * wave;
    }

    // === LAYER 7: Particle field / stars ===
    let star_uv = p * 15.0 + vec2<f32>(t * 0.3, t * 0.2);
    let star_id = floor(star_uv);
    let star_f = fract(star_uv) - 0.5;

    let star_r = hash(star_id);
    if (star_r > 0.93) {
        let star_off = (hash3(star_id).xy - 0.5) * 0.6;
        let star_d = length(star_f - star_off);
        let twinkle = sin(t * 4.0 + star_r * 25.0) * 0.5 + 0.5;
        let star = exp(-star_d * 40.0) * twinkle;
        col += palette1(star_r * 3.0) * star * 0.6;
    }

    // === OLED PROTECTION ===

    // Strong center-focused vignette
    let cd = length(p);
    var vig = 1.0 - smoothstep(0.25, 1.0, cd * 0.7);
    vig = vig * vig;
    col *= vig;

    // Roaming shadow zones - organic dark patches
    let shadow_noise = fbm(p * 2.0 + t * 0.2);
    let shadow_thresh = 0.45 + sin(t * 0.3) * 0.1;
    let shadow = smoothstep(shadow_thresh - 0.15, shadow_thresh + 0.15, shadow_noise);
    col *= 0.3 + shadow * 0.7;

    // Edge fade to pure black
    let ex = smoothstep(0.0, 0.3, 1.0 - abs(p.x) * 0.65);
    let ey = smoothstep(0.0, 0.3, 1.0 - abs(p.y) * 0.75);
    col *= ex * ey;

    // === FINAL TOUCHES ===
    // Slight saturation boost
    let lum = dot(col, vec3<f32>(0.299, 0.587, 0.114));
    col = mix(vec3<f32>(lum), col, 1.15);

    // Brightness cap
    col = min(col, vec3<f32>(0.9));

    // Cut to true black
    col = max(col - 0.015, vec3<f32>(0.0));

    // Gentle overall pulse
    col *= 0.75 + sin(t * 0.35) * 0.12;

    return vec4<f32>(col, 1.0);
}
