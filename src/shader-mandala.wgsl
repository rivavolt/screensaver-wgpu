// Mandala - Sacred geometry, kaleidoscopic symmetry
// Meditative psychedelic patterns

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
const PHI: f32 = 1.618033988749;  // Golden ratio

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

fn fbm(p_in: vec2<f32>) -> f32 {
    var p = p_in;
    var v: f32 = 0.0;
    var a: f32 = 0.5;
    for (var i: i32 = 0; i < 5; i++) {
        v += a * noise(p);
        p = p * 2.1;
        a *= 0.5;
    }
    return v;
}

// Kaleidoscope fold
fn kaleido(p: vec2<f32>, segments: f32) -> vec2<f32> {
    var angle = atan2(p.y, p.x);
    let r = length(p);

    // Fold into segment
    let segment_angle = TAU / segments;
    angle = abs(((angle % segment_angle) + segment_angle) % segment_angle - segment_angle * 0.5);

    return vec2<f32>(cos(angle), sin(angle)) * r;
}

// Sacred palette - deep purples, golds, teals
fn sacred1(t: f32) -> vec3<f32> {
    let purple = vec3<f32>(0.6, 0.2, 0.8);
    let gold = vec3<f32>(1.0, 0.8, 0.3);
    let teal = vec3<f32>(0.2, 0.7, 0.7);
    return mix(mix(purple, gold, fract(t * 2.0)), teal, fract(t * 2.0 + 0.5)) * 0.9;
}

// Chakra palette
fn chakra(t: f32) -> vec3<f32> {
    return 0.5 + 0.5 * cos(TAU * (t * 1.5 + vec3<f32>(0.0, 0.25, 0.5)));
}

// Flower of life distance
fn flowerOfLife(p: vec2<f32>, scale: f32) -> f32 {
    var d = length(p) - scale;

    // Six surrounding circles
    for (var i: f32 = 0.0; i < 6.0; i += 1.0) {
        let angle = i * TAU / 6.0;
        let center = vec2<f32>(cos(angle), sin(angle)) * scale;
        d = min(d, abs(length(p - center) - scale));
    }

    return d;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.uv;
    var p = (uv * 2.0 - 1.0);
    p.x *= uniforms.resolution.x / uniforms.resolution.y;

    let t = uniforms.time * 0.08;
    var col = vec3<f32>(0.0);

    let r = length(p);
    let a = atan2(p.y, p.x);

    // === LAYER 1: Central mandala with varying symmetry ===
    let sym_base = 8.0;
    let sym_var = sin(t * 0.3) * 2.0;
    let symmetry = sym_base + floor(sym_var);

    var kp = kaleido(p, symmetry);

    // Multiple ring patterns
    for (var i: f32 = 0.0; i < 5.0; i += 1.0) {
        let ring_r = 0.15 + i * 0.12;
        let ring_width = 0.03 + sin(t + i) * 0.01;

        // Wavy ring
        let wave = sin(a * symmetry + t * 2.0 - i) * 0.02;
        let ring_d = abs(r - ring_r - wave);
        let ring = smoothstep(ring_width, 0.0, ring_d);

        col += sacred1(i * 0.2 + t * 0.1) * ring * 0.5;
    }

    // === LAYER 2: Flower of Life overlay ===
    let fol_scale = 0.15 + sin(t * 0.4) * 0.03;
    let fol_d = flowerOfLife(p, fol_scale);
    let fol = smoothstep(0.015, 0.0, abs(fol_d));

    // Rotate the flower
    let rot_t = t * 0.2;
    let rot_p = vec2<f32>(
        p.x * cos(rot_t) - p.y * sin(rot_t),
        p.x * sin(rot_t) + p.y * cos(rot_t)
    );
    let fol_d2 = flowerOfLife(rot_p * 0.8, fol_scale * 1.2);
    let fol2 = smoothstep(0.01, 0.0, abs(fol_d2));

    col += chakra(r + t * 0.15) * (fol + fol2 * 0.5) * 0.4;

    // === LAYER 3: Fibonacci spiral ===
    let spiral_a = a + r * 8.0 - t * 1.5;
    let spiral_pattern = sin(spiral_a * PHI * 3.0) * 0.5 + 0.5;
    let spiral_fade = exp(-r * 3.0);
    col += sacred1(spiral_a / TAU + t * 0.1) * spiral_pattern * spiral_fade * 0.25;

    // === LAYER 4: Petal layers ===
    for (var i: f32 = 0.0; i < 3.0; i += 1.0) {
        let petal_sym = 6.0 + i * 2.0;
        let petal_angle = a * petal_sym + t * (0.3 + i * 0.1);

        // Petal shape
        let petal_r = 0.25 + i * 0.1;
        let petal_shape = sin(petal_angle) * 0.5 + 0.5;
        let petal_d = abs(r - petal_r * petal_shape);
        let petal = smoothstep(0.04, 0.0, petal_d) * petal_shape;

        col += chakra(i * 0.3 + r + t * 0.12) * petal * 0.35;
    }

    // === LAYER 5: Sacred geometry - Sri Yantra inspired ===
    // Triangles pointing up and down
    for (var i: f32 = 0.0; i < 4.0; i += 1.0) {
        let tri_scale = 0.5 - i * 0.1;
        let rot = t * 0.15 * (1.0 - i * 0.2);

        // Upward triangle
        let up_p = vec2<f32>(
            p.x * cos(rot) - p.y * sin(rot),
            p.x * sin(rot) + p.y * cos(rot)
        );
        let up_d = max(
            abs(up_p.x) * 0.866 + up_p.y * 0.5,
            -up_p.y
        ) - tri_scale * 0.3;
        let up_tri = smoothstep(0.02, 0.0, abs(up_d));

        // Downward triangle
        let down_rot = rot + PI;
        let down_p = vec2<f32>(
            p.x * cos(down_rot) - p.y * sin(down_rot),
            p.x * sin(down_rot) + p.y * cos(down_rot)
        );
        let down_d = max(
            abs(down_p.x) * 0.866 + down_p.y * 0.5,
            -down_p.y
        ) - tri_scale * 0.3;
        let down_tri = smoothstep(0.02, 0.0, abs(down_d));

        col += sacred1(i * 0.25 + t * 0.08) * (up_tri + down_tri) * 0.25;
    }

    // === LAYER 6: Om symbol energy center ===
    let center_glow = exp(-r * 5.0);
    let center_pulse = 0.8 + sin(t * 2.0) * 0.2;
    col += chakra(t * 0.2) * center_glow * center_pulse * 0.4;

    // Inner rings
    for (var i: f32 = 1.0; i < 4.0; i += 1.0) {
        let inner_r = i * 0.05;
        let inner_d = abs(r - inner_r);
        let inner = smoothstep(0.01, 0.0, inner_d);
        col += vec3<f32>(1.0, 0.9, 0.7) * inner * 0.3;
    }

    // === LAYER 7: Floating seed particles ===
    let seed_uv = p * 30.0;
    let seed_id = floor(seed_uv);
    let seed_f = fract(seed_uv) - 0.5;

    let sr = hash(seed_id);
    if (sr > 0.96) {
        let soff = (vec2<f32>(hash(seed_id + 1.0), hash(seed_id + 2.0)) - 0.5) * 0.4;
        let sd = length(seed_f - soff);
        let drift = sin(t * 3.0 + sr * 20.0) * 0.5 + 0.5;
        let seed = exp(-sd * 35.0) * drift;
        col += vec3<f32>(1.0, 0.95, 0.8) * seed * 0.5;
    }

    // === OLED PROTECTION ===

    // Soft vignette - lighter for mandala
    let cd = length(p);
    var vig = 1.0 - smoothstep(0.3, 1.2, cd * 0.55);
    vig = pow(vig, 1.3);
    col *= vig;

    // Breathing shadows
    let shadow = fbm(p * 2.5 + t * 0.2);
    col *= 0.4 + shadow * 0.6;

    // Edge fade
    let ex = smoothstep(0.0, 0.4, 1.0 - abs(p.x) * 0.55);
    let ey = smoothstep(0.0, 0.4, 1.0 - abs(p.y) * 0.65);
    col *= ex * ey;

    // === FINAL ===
    // Saturation
    let lum = dot(col, vec3<f32>(0.299, 0.587, 0.114));
    col = mix(vec3<f32>(lum), col, 1.1);

    // Cap
    col = min(col, vec3<f32>(0.9));

    // True black
    col = max(col - 0.012, vec3<f32>(0.0));

    // Gentle breath
    col *= 0.8 + sin(t * 0.25) * 0.08;

    return vec4<f32>(col, 1.0);
}
