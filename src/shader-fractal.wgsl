// Fractal Cosmos - Deep flowing fractals
// Rich visual complexity with organic motion

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
    let u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    return mix(mix(hash(i), hash(i + vec2<f32>(1.0, 0.0)), u.x),
               mix(hash(i + vec2<f32>(0.0, 1.0)), hash(i + vec2<f32>(1.0, 1.0)), u.x), u.y);
}

fn fbm(p_in: vec2<f32>) -> f32 {
    var p = p_in;
    var v: f32 = 0.0;
    var a: f32 = 0.5;
    let rot = mat2x2<f32>(0.8, 0.6, -0.6, 0.8);
    for (var i: i32 = 0; i < 5; i++) {
        v += a * noise(p);
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

fn rainbow(t: f32) -> vec3<f32> {
    return 0.5 + 0.5 * cos(TAU * (t + vec3<f32>(0.0, 0.33, 0.67)));
}

fn neon(t: f32) -> vec3<f32> {
    return 0.5 + 0.5 * cos(TAU * (t * 1.5 + vec3<f32>(0.0, 0.2, 0.5)));
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.uv;
    var p = (uv * 2.0 - 1.0);
    p.x *= uniforms.resolution.x / uniforms.resolution.y;

    let t = uniforms.time * 0.12;
    var col = vec3<f32>(0.0);

    // === LAYER 1: Deep warped fractal ===
    let warp = vec2<f32>(
        fbm(p * 2.0 + t * 0.3) * 0.2,
        fbm(p * 2.0 + vec2<f32>(5.0, 3.0) + t * 0.25) * 0.2
    );
    var z = p + warp;
    z *= 1.0 + sin(t * 0.5) * 0.25;

    // 5 iterations for rich detail
    for (var i: f32 = 0.0; i < 5.0; i += 1.0) {
        z = abs(z) - 0.5 - sin(t * 0.3 + i) * 0.06;
        let a = t * 0.4 + i * 0.65;
        z = vec2<f32>(z.x * cos(a) - z.y * sin(a), z.x * sin(a) + z.y * cos(a));
        z *= 1.18;

        let d = length(z);
        let wave = sin(d * 5.0 - t * 3.0) * 0.5 + 0.5;
        let glow = exp(-d * 2.5) * wave;
        col += rainbow(i * 0.2 + t * 0.2 + d * 0.4) * glow * 0.28;
    }

    // === LAYER 2: Breathing rings ===
    let r = length(p);
    let a = atan2(p.y, p.x);

    for (var i: f32 = 0.0; i < 5.0; i += 1.0) {
        let ring_r = 0.12 + i * 0.13 + sin(t * 0.6 + i * 0.9) * 0.035;
        let warp_r = sin(a * 6.0 + t * 2.5 - i * 0.6) * 0.03;
        let ring_d = abs(r - ring_r - warp_r);
        let ring = smoothstep(0.02, 0.0, ring_d);
        col += rainbow(a / TAU + i * 0.18 + t * 0.15) * ring * 0.32;
    }

    // === LAYER 3: Dancing wisps with trails ===
    for (var i: f32 = 0.0; i < 7.0; i += 1.0) {
        let phase1 = t * 0.5 + i * 1.2;
        let phase2 = t * 0.4 + i * 0.9;
        let wisp_pos = vec2<f32>(
            sin(phase1) * 0.45 + sin(phase2 * 1.7) * 0.18,
            cos(phase1 * 0.8) * 0.38 + cos(phase2 * 1.4) * 0.12
        );

        let d = length(p - wisp_pos);
        let pulse = 0.65 + 0.35 * sin(t * 3.0 + i * 1.8);
        let wisp = exp(-d * 6.5) * pulse;
        col += neon(i * 0.14 + t) * wisp * 0.38;

        // Trail with 2 points
        for (var j: f32 = 1.0; j < 3.0; j += 1.0) {
            let trail_phase1 = phase1 - j * 0.1;
            let trail_phase2 = phase2 - j * 0.1;
            let trail_pos = vec2<f32>(
                sin(trail_phase1) * 0.45 + sin(trail_phase2 * 1.7) * 0.18,
                cos(trail_phase1 * 0.8) * 0.38 + cos(trail_phase2 * 1.4) * 0.12
            );
            col += neon(i * 0.14 + t) * exp(-length(p - trail_pos) * 9.0) * (0.15 / j);
        }
    }

    // === LAYER 4: Nebula clouds ===
    let neb1 = noise(p * 3.5 + t * 0.35);
    let neb2 = noise(p * 5.0 - t * 0.25 + 3.0);
    let neb = neb1 * neb2;
    col += rainbow(neb + t * 0.12) * neb * 0.25;

    // === OLED PROTECTION ===
    let cd = length(p);
    var vig = 1.0 - smoothstep(0.2, 1.1, cd * 0.65);
    vig = vig * vig;
    col *= vig;

    let shadow = fbm(p * 2.0 + t * 0.2);
    col *= 0.35 + shadow * 0.65;

    let ex = smoothstep(0.0, 0.35, 1.0 - abs(p.x) * 0.6);
    let ey = smoothstep(0.0, 0.35, 1.0 - abs(p.y) * 0.7);
    col *= ex * ey;

    // === FINAL ===
    let lum = dot(col, vec3<f32>(0.299, 0.587, 0.114));
    col = mix(vec3<f32>(lum), col, 1.18);
    col = min(col, vec3<f32>(0.9));
    col = max(col - 0.015, vec3<f32>(0.0));
    col *= 0.82 + sin(t * 0.4) * 0.1;

    return vec4<f32>(col, 1.0);
}
