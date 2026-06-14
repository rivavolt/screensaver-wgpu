// Liquid Crystal - Living fluid, breathing iridescence
// Organic flow patterns and morphing cells

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
    let u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
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

// Deep domain warping for fluid feel
fn warp(p: vec2<f32>, t: f32) -> vec2<f32> {
    let q = vec2<f32>(
        fbm(p + t * 0.1),
        fbm(p + vec2<f32>(5.2, 1.3) + t * 0.12)
    );
    let r = vec2<f32>(
        fbm(p + 4.0 * q + vec2<f32>(1.7, 9.2) + t * 0.15),
        fbm(p + 4.0 * q + vec2<f32>(8.3, 2.8) + t * 0.12)
    );
    return r;
}

fn iridescent(t: f32, angle: f32) -> vec3<f32> {
    let shifted = t + angle * 0.2 + sin(t * TAU) * 0.1;
    return vec3<f32>(
        0.5 + 0.5 * cos(TAU * (shifted + 0.0)),
        0.5 + 0.5 * cos(TAU * (shifted + 0.33)),
        0.5 + 0.5 * cos(TAU * (shifted + 0.67))
    );
}

fn oil_color(t: f32) -> vec3<f32> {
    let c1 = vec3<f32>(0.8, 0.2, 0.5);
    let c2 = vec3<f32>(0.2, 0.8, 0.6);
    let c3 = vec3<f32>(0.9, 0.7, 0.2);
    let c4 = vec3<f32>(0.3, 0.3, 0.9);
    let s = sin(t * TAU) * 0.5 + 0.5;
    let s2 = sin(t * TAU * 0.7 + 1.0) * 0.5 + 0.5;
    return mix(mix(c1, c2, s), mix(c3, c4, s), s2);
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.uv;
    var p = (uv * 2.0 - 1.0);
    p.x *= uniforms.resolution.x / uniforms.resolution.y;

    let t = uniforms.time * 0.13;  // Faster animation
    var col = vec3<f32>(0.0);

    // === LAYER 1: Deep fluid warping ===
    let w1 = warp(p * 1.5, t);
    let w2 = warp(p * 2.0 + w1 * 0.5, t * 1.3);

    let fluid1 = fbm(p * 3.0 + w2 * 2.0 + t * 0.2);
    let fluid2 = fbm(p * 2.5 - w1 * 1.5 + t * 0.15 + 5.0);
    col += oil_color(fluid1 * fluid2 + t * 0.1) * fluid1 * 0.35;

    // === LAYER 2: Breathing ripples ===
    for (var i: f32 = 0.0; i < 6.0; i += 1.0) {
        // Ripple centers drift organically
        let center = vec2<f32>(
            sin(t * 0.25 + i * 1.8) * 0.4 + sin(t * 0.15 + i * 2.3) * 0.15,
            cos(t * 0.2 + i * 2.1) * 0.35 + cos(t * 0.18 + i * 1.7) * 0.12
        );

        let d = length(p - center);

        // Multiple expanding rings per center
        for (var j: f32 = 0.0; j < 3.0; j += 1.0) {
            let ring_phase = t * 2.0 + i * 0.5 + j * 0.8;
            let ring_r = (sin(ring_phase) * 0.5 + 0.5) * 0.4;
            let ring_d = abs(d - ring_r);
            let ring = smoothstep(0.03, 0.0, ring_d) * exp(-d * 2.0);

            col += iridescent(d + i * 0.15 + t * 0.1, ring_phase) * ring * 0.2;
        }
    }

    // === LAYER 3: Living voronoi cells ===
    let cell_scale = 3.5;
    // Cells drift over time
    let cell_drift = vec2<f32>(t * 0.3, t * 0.2);
    let cell_uv = p * cell_scale + cell_drift;
    let cell_id = floor(cell_uv);

    var min_d = 1.0;
    var second_d = 1.0;
    var closest_id = vec2<f32>(0.0);

    for (var y: f32 = -1.0; y <= 1.0; y += 1.0) {
        for (var x: f32 = -1.0; x <= 1.0; x += 1.0) {
            let neighbor = cell_id + vec2<f32>(x, y);
            // Cell centers move organically
            let base_point = neighbor + hash3(neighbor).xy * 0.7;
            let point_drift = vec2<f32>(
                sin(t * 0.5 + hash(neighbor) * 10.0) * 0.15,
                cos(t * 0.4 + hash(neighbor + 1.0) * 10.0) * 0.15
            );
            let point = base_point + point_drift;

            let d = length(cell_uv - point);

            if (d < min_d) {
                second_d = min_d;
                min_d = d;
                closest_id = neighbor;
            } else if (d < second_d) {
                second_d = d;
            }
        }
    }

    // Soft cell edges
    let edge = second_d - min_d;
    let edge_glow = smoothstep(0.15, 0.0, edge);

    // Cell color shifts over time
    let cell_hue = hash(closest_id) + t * 0.1;
    col += iridescent(cell_hue, edge) * edge_glow * 0.35;

    // Cell interior glow
    let interior = exp(-min_d * 3.0);
    col += oil_color(cell_hue + t * 0.05) * interior * 0.2;

    // === LAYER 4: Flowing streams ===
    for (var i: f32 = 0.0; i < 5.0; i += 1.0) {
        // Stream paths warp with noise
        let base_y = -0.3 + i * 0.15;
        let stream_warp = fbm(vec2<f32>(p.x * 4.0 + t * 1.5, i * 3.0 + t * 0.5)) * 0.2;
        let stream_wave = sin(p.x * 6.0 + t * 2.5 + i * 1.3) * 0.06;

        let stream_y = base_y + stream_warp + stream_wave;
        let stream_d = abs(p.y - stream_y);

        // Flowing color along stream
        let flow_color = oil_color(p.x * 0.5 + i * 0.2 + t * 0.15);
        let flow_bright = 0.6 + 0.4 * sin(p.x * 10.0 - t * 3.0 + i * 2.0);
        let stream = exp(-stream_d * 10.0) * flow_bright;

        col += flow_color * stream * 0.2;
    }

    // === LAYER 5: Floating droplets ===
    for (var i: f32 = 0.0; i < 8.0; i += 1.0) {
        let phase1 = t * 0.3 + i * 1.2;
        let phase2 = t * 0.25 + i * 0.9;
        let drop_pos = vec2<f32>(
            sin(phase1) * 0.5 + sin(phase2 * 1.5) * 0.15,
            cos(phase1 * 0.7) * 0.4 + cos(phase2 * 1.3) * 0.1
        );

        let d = length(p - drop_pos);

        // Droplet with internal gradient
        let drop_size = 0.07 + sin(t * 0.8 + i) * 0.015;
        let inner = smoothstep(drop_size, drop_size * 0.3, d);
        let glow = exp(-d * 7.0) * 0.4;

        // Iridescent based on viewing angle
        let angle = atan2(p.y - drop_pos.y, p.x - drop_pos.x);
        col += iridescent(i * 0.12 + d * 2.0 + t * 0.1, angle) * (glow + inner * 0.5);

        // Trail
        for (var j: f32 = 1.0; j < 4.0; j += 1.0) {
            let trail_phase1 = phase1 - j * 0.1;
            let trail_phase2 = phase2 - j * 0.1;
            let trail_pos = vec2<f32>(
                sin(trail_phase1) * 0.5 + sin(trail_phase2 * 1.5) * 0.15,
                cos(trail_phase1 * 0.7) * 0.4 + cos(trail_phase2 * 1.3) * 0.1
            );
            let trail_d = length(p - trail_pos);
            col += oil_color(i * 0.12 + t) * exp(-trail_d * 10.0) * (0.15 / j);
        }
    }

    // === LAYER 6: Caustic shimmer ===
    let caustic_warp = warp(p * 3.0, t * 2.0);
    let caustic1 = fbm(p * 8.0 + caustic_warp + t * 0.8);
    let caustic2 = fbm(p * 7.0 - t * 0.6 + 5.0);
    let caustics = pow(caustic1 * caustic2, 1.8);
    col += vec3<f32>(0.95, 0.98, 1.0) * caustics * 0.2;

    // === OLED PROTECTION ===
    let cd = length(p);
    var vig = 1.0 - smoothstep(0.25, 1.1, cd * 0.6);
    vig = pow(vig, 1.5);
    col *= vig;

    let shadow = fbm(p * 2.0 + t * 0.15);
    let shadow2 = fbm(p * 3.0 - t * 0.1 + 10.0);
    col *= 0.3 + shadow * shadow2 * 0.7;

    let ex = smoothstep(0.0, 0.35, 1.0 - abs(p.x) * 0.6);
    let ey = smoothstep(0.0, 0.35, 1.0 - abs(p.y) * 0.7);
    col *= ex * ey;

    // === FINAL ===
    let lum = dot(col, vec3<f32>(0.299, 0.587, 0.114));
    col = mix(vec3<f32>(lum), col, 1.15);
    col = min(col, vec3<f32>(0.88));
    col = max(col - 0.012, vec3<f32>(0.0));
    col *= 0.78 + sin(t * 0.3) * 0.1;

    return vec4<f32>(col, 1.0);
}
