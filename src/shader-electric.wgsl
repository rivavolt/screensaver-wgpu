// Electric Dreams - Living neon (optimized)
// Smooth organic plasma and arcs

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

fn fbm3(p: vec2<f32>) -> f32 {
    return noise(p) * 0.5 + noise(p * 2.0) * 0.25 + noise(p * 4.0) * 0.125;
}

fn neon1(t: f32) -> vec3<f32> {
    return vec3<f32>(
        0.5 + 0.5 * sin(t * TAU),
        0.3 + 0.3 * sin(t * TAU + 2.0),
        0.5 + 0.5 * sin(t * TAU + 4.0)
    );
}

fn neon2(t: f32) -> vec3<f32> {
    let pink = vec3<f32>(1.0, 0.2, 0.6);
    let blue = vec3<f32>(0.2, 0.5, 1.0);
    return mix(pink, blue, sin(t * TAU) * 0.5 + 0.5);
}

fn neon3(t: f32) -> vec3<f32> {
    return vec3<f32>(
        0.2 + 0.3 * sin(t * TAU),
        0.7 + 0.3 * sin(t * TAU + 1.0),
        0.5 + 0.5 * sin(t * TAU + 2.0)
    );
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.uv;
    var p = (uv * 2.0 - 1.0);
    p.x *= uniforms.resolution.x / uniforms.resolution.y;

    let t = uniforms.time * 0.12;
    var col = vec3<f32>(0.0);

    // === LAYER 1: Plasma field (simplified) ===
    var plasma = 0.0;
    plasma += sin(p.x * 4.0 + t * 2.5 + sin(p.y * 2.0 + t) * 0.5);
    plasma += sin(p.y * 3.5 - t * 2.0 + cos(p.x * 1.5) * 0.6);
    plasma += sin((p.x + p.y) * 2.5 + t * 1.5);
    plasma += sin(length(p) * 5.0 - t * 3.0);
    plasma *= 0.25;

    col += neon1(plasma * 0.5 + t * 0.15) * (plasma * 0.5 + 0.5) * 0.25;

    // === LAYER 2: Organic arcs (simplified - no nested loops) ===
    for (var i: f32 = 0.0; i < 4.0; i += 1.0) {
        let arc_phase = t * 0.5 + i * 1.5;
        let arc_start = vec2<f32>(
            sin(arc_phase) * 0.5,
            cos(arc_phase * 0.8) * 0.4
        );
        let arc_end = vec2<f32>(
            sin(arc_phase + 2.0) * 0.4,
            cos(arc_phase * 0.9 + 2.0) * 0.5
        );

        // Simple arc as curved line
        let arc_mid = (arc_start + arc_end) * 0.5 + vec2<f32>(
            sin(t * 2.0 + i) * 0.15,
            cos(t * 1.8 + i) * 0.12
        );

        // Distance to quadratic bezier approximation
        let t_param = clamp(dot(p - arc_start, arc_end - arc_start) / dot(arc_end - arc_start, arc_end - arc_start), 0.0, 1.0);
        let on_curve = mix(mix(arc_start, arc_mid, t_param), mix(arc_mid, arc_end, t_param), t_param);
        let arc_d = length(p - on_curve);

        let pulse = 0.6 + 0.4 * sin(t * 6.0 + i * 3.0);
        let arc_glow = exp(-arc_d * 15.0) * pulse;
        col += neon3(i * 0.25 + t * 0.3) * arc_glow * 0.4;
    }

    // === LAYER 3: Breathing rings ===
    let r = length(p);
    let a = atan2(p.y, p.x);

    for (var i: f32 = 0.0; i < 4.0; i += 1.0) {
        let ring_r = 0.18 + i * 0.14 + sin(t * 0.7 + i * 0.8) * 0.04;
        let warp = sin(a * (4.0 + i) + t * 2.0) * 0.025;
        let ring_d = abs(r - ring_r - warp);

        let intensity = 0.7 + 0.3 * sin(a * 3.0 + t * 1.5 + i);
        let ring = smoothstep(0.025, 0.0, ring_d) * intensity;

        col += neon2(a / TAU + i * 0.2 + t * 0.12) * ring * 0.4;
    }

    // === LAYER 4: Dancing orbs ===
    for (var i: f32 = 0.0; i < 6.0; i += 1.0) {
        let phase1 = t * 0.5 + i * 1.1;
        let phase2 = t * 0.4 + i * 0.8;
        let orb_pos = vec2<f32>(
            sin(phase1) * 0.45 + sin(phase2 * 1.6) * 0.15,
            cos(phase1 * 0.7) * 0.4 + cos(phase2 * 1.4) * 0.12
        );

        let d = length(p - orb_pos);
        let pulse = 0.7 + 0.3 * sin(t * 3.0 + i * 2.0);
        let orb = exp(-d * 8.0) * pulse;

        col += neon2(i * 0.15 + t) * orb * 0.35;

        // Single trail point
        let trail_pos = vec2<f32>(
            sin(phase1 - 0.12) * 0.45 + sin((phase2 - 0.12) * 1.6) * 0.15,
            cos((phase1 - 0.12) * 0.7) * 0.4 + cos((phase2 - 0.12) * 1.4) * 0.12
        );
        col += neon2(i * 0.15 + t) * exp(-length(p - trail_pos) * 12.0) * 0.15;
    }

    // === LAYER 5: Energy streams ===
    for (var i: f32 = 0.0; i < 4.0; i += 1.0) {
        let base_y = -0.35 + i * 0.18;
        let wave = sin(p.x * 5.0 + t * 3.0 + i * 1.2) * 0.1;
        let stream_y = base_y + wave;
        let stream_d = abs(p.y - stream_y);

        let flow = 0.6 + 0.4 * sin(p.x * 8.0 - t * 4.0 + i * 2.0);
        let stream = exp(-stream_d * 12.0) * flow;

        col += neon1(p.x * 0.5 + i * 0.15 + t * 0.2) * stream * 0.2;
    }

    // === OLED PROTECTION ===
    let cd = length(p);
    var vig = 1.0 - smoothstep(0.25, 1.15, cd * 0.6);
    vig = vig * vig;
    col *= vig;

    let shadow = fbm3(p * 2.0 + t * 0.25);
    col *= 0.4 + shadow * 0.6;

    let ex = smoothstep(0.0, 0.3, 1.0 - abs(p.x) * 0.6);
    let ey = smoothstep(0.0, 0.3, 1.0 - abs(p.y) * 0.7);
    col *= ex * ey;

    // === FINAL ===
    let lum = dot(col, vec3<f32>(0.299, 0.587, 0.114));
    col = mix(vec3<f32>(lum), col, 1.2);
    col = min(col, vec3<f32>(0.9));
    col = max(col - 0.015, vec3<f32>(0.0));
    col *= 0.75 + sin(t * 0.4) * 0.12;

    return vec4<f32>(col, 1.0);
}
