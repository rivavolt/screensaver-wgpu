// Prism - Living rainbow light, dancing refractions (optimized)
// Fast-moving spectral energy

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

fn spectrum(t: f32) -> vec3<f32> {
    return 0.5 + 0.5 * cos(TAU * (t + vec3<f32>(0.0, 0.33, 0.67)));
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.uv;
    var p = (uv * 2.0 - 1.0);
    p.x *= uniforms.resolution.x / uniforms.resolution.y;

    let t = uniforms.time * 0.15;
    var col = vec3<f32>(0.0);

    // === LAYER 1: Swirling light beams (simplified - no nested loop) ===
    for (var i: f32 = 0.0; i < 5.0; i += 1.0) {
        let beam_angle = t * 0.5 + i * TAU / 5.0 + sin(t * 0.3 + i) * 0.3;
        let beam_dir = vec2<f32>(cos(beam_angle), sin(beam_angle));

        let proj = dot(p, beam_dir);
        let perp = length(p - beam_dir * proj);

        let pulse = 0.6 + 0.4 * sin(t * 3.0 + i * 2.0);
        let beam = exp(-perp * 10.0) * pulse;
        let fade = exp(-abs(proj) * 1.5);

        // Rainbow spread without inner loop
        col += spectrum(i / 5.0 + t * 0.3 + perp * 0.5) * beam * fade * 0.15;
    }

    // === LAYER 2: Dancing orbs (simplified from shards) ===
    for (var i: f32 = 0.0; i < 6.0; i += 1.0) {
        let phase1 = t * 0.6 + i * 1.3;
        let phase2 = t * 0.5 + i * 0.9;
        let orb_pos = vec2<f32>(
            sin(phase1) * 0.4 + sin(phase2 * 1.6) * 0.15,
            cos(phase1 * 0.8) * 0.35 + cos(phase2 * 1.4) * 0.12
        );

        let d = length(p - orb_pos);
        let pulse = 0.7 + 0.3 * sin(t * 2.5 + i * 1.5);
        let orb = exp(-d * 7.0) * pulse;

        // Rainbow based on angle
        let angle = atan2(p.y - orb_pos.y, p.x - orb_pos.x);
        col += spectrum(angle / TAU + t * 0.5 + i * 0.15) * orb * 0.4;

        // Single trail point
        let trail_pos = vec2<f32>(
            sin(phase1 - 0.12) * 0.4 + sin((phase2 - 0.12) * 1.6) * 0.15,
            cos((phase1 - 0.12) * 0.8) * 0.35 + cos((phase2 - 0.12) * 1.4) * 0.12
        );
        col += spectrum(i / 6.0 + t * 0.2) * exp(-length(p - trail_pos) * 10.0) * 0.15;
    }

    // === LAYER 3: Breathing spectral rings ===
    let r = length(p);
    let a = atan2(p.y, p.x);

    for (var i: f32 = 0.0; i < 4.0; i += 1.0) {
        let base_r = 0.15 + i * 0.14;
        let breath = sin(t * 0.8 + i * 0.6) * 0.04;
        let wobble = sin(a * (4.0 + i) + t * 2.5 - i * 0.7) * 0.03;
        let ring_r = base_r + breath + wobble;

        let ring_d = abs(r - ring_r);
        let flow = 0.6 + 0.4 * sin(a * 5.0 - t * 3.0 + i);
        let ring = smoothstep(0.025, 0.0, ring_d) * flow;

        col += spectrum(a / TAU + i * 0.2 + t * 0.25) * ring * 0.35;
    }

    // === LAYER 4: Aurora waves (simplified) ===
    for (var i: f32 = 0.0; i < 4.0; i += 1.0) {
        let wave_y = sin(p.x * 5.0 + t * 3.5 + i * 1.5) * 0.1;
        let wave_base = -0.2 + i * 0.13;

        let wave_d = abs(p.y - wave_base - wave_y);
        let flow = 0.5 + 0.5 * sin(p.x * 8.0 - t * 4.0 + i * 2.0);
        let wave = exp(-wave_d * 12.0) * flow;

        col += spectrum(p.x * 0.3 + i * 0.2 + t * 0.2) * wave * 0.2;
    }

    // === LAYER 5: Pulsing center prism ===
    let center_d = length(p);
    let center_a = atan2(p.y, p.x);

    // Hexagonal prism
    let hex_a = ((center_a / TAU * 6.0 + 0.5) % 1.0) * TAU / 6.0 - TAU / 12.0;
    let hex_r = cos(hex_a) * 0.15;

    let prism_d = center_d - hex_r * (1.0 + sin(t * 1.5) * 0.2);
    let prism_edge = smoothstep(0.025, 0.0, abs(prism_d));

    col += spectrum(center_a / TAU + center_d * 3.0 + t * 0.4) * prism_edge * 0.4;

    // Inner glow
    let inner = exp(-center_d * 4.0) * (0.7 + 0.3 * sin(t * 2.0));
    col += spectrum(t * 0.3) * inner * 0.3;

    // === OLED PROTECTION ===
    let cd = length(p);
    var vig = 1.0 - smoothstep(0.25, 1.15, cd * 0.6);
    vig = vig * vig;
    col *= vig;

    let shadow = fbm3(p * 2.5 + t * 0.3);
    col *= 0.35 + shadow * 0.65;

    let ex = smoothstep(0.0, 0.35, 1.0 - abs(p.x) * 0.6);
    let ey = smoothstep(0.0, 0.35, 1.0 - abs(p.y) * 0.7);
    col *= ex * ey;

    // === FINAL ===
    let lum = dot(col, vec3<f32>(0.299, 0.587, 0.114));
    col = mix(vec3<f32>(lum), col, 1.2);
    col = min(col, vec3<f32>(0.9));
    col = max(col - 0.015, vec3<f32>(0.0));
    col *= 0.78 + sin(t * 0.5) * 0.1;

    return vec4<f32>(col, 1.0);
}
