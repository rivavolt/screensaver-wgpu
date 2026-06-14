// Nighttime OLED screensaver - deep blacks, gentle glowing elements
// Designed for leaving on overnight

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

fn hash(p: vec2<f32>) -> f32 {
    return fract(sin(dot(p, vec2<f32>(127.1, 311.7))) * 43758.5453);
}

fn hash2(p: vec2<f32>) -> vec2<f32> {
    return vec2<f32>(hash(p), hash(p + vec2<f32>(13.37, 7.89)));
}

fn noise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let u = f * f * (3.0 - 2.0 * f);

    let a = hash(i);
    let b = hash(i + vec2<f32>(1.0, 0.0));
    let c = hash(i + vec2<f32>(0.0, 1.0));
    let d = hash(i + vec2<f32>(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

fn fbm(p_in: vec2<f32>) -> f32 {
    var p = p_in;
    var value: f32 = 0.0;
    var amplitude: f32 = 0.5;

    for (var i: i32 = 0; i < 5; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// Soft nighttime palette - blues, teals, soft purples
fn night_palette(t: f32) -> vec3<f32> {
    let a = vec3<f32>(0.2, 0.3, 0.5);
    let b = vec3<f32>(0.3, 0.3, 0.3);
    let c = vec3<f32>(1.0, 0.7, 0.4);
    let d = vec3<f32>(0.0, 0.15, 0.3);
    return a + b * cos(6.28318 * (c * t + d));
}

// Warm accent palette for occasional highlights
fn ember_palette(t: f32) -> vec3<f32> {
    let a = vec3<f32>(0.5, 0.3, 0.2);
    let b = vec3<f32>(0.4, 0.3, 0.2);
    let c = vec3<f32>(0.8, 0.5, 0.3);
    let d = vec3<f32>(0.0, 0.1, 0.2);
    return a + b * cos(6.28318 * (c * t + d));
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.uv;
    var p = (uv * 2.0 - 1.0);
    p.x *= uniforms.resolution.x / uniforms.resolution.y;

    // Slower time for nighttime relaxation
    let t = uniforms.time * 0.08;

    var final_color = vec3<f32>(0.0);

    // === Very subtle dark nebula background ===
    let nebula_q = vec2<f32>(
        fbm(p * 0.5 + t * 0.1),
        fbm(p * 0.5 + vec2<f32>(5.2, 1.3) + t * 0.08)
    );
    let nebula = fbm(p * 0.7 + nebula_q * 1.5);

    // Very dark, barely visible nebula wisps
    let nebula_color = mix(
        vec3<f32>(0.0, 0.0, 0.0),
        vec3<f32>(0.02, 0.01, 0.04),
        nebula * nebula * 0.5
    );
    final_color += nebula_color;

    // === Floating orbs - fewer, softer, slower ===
    for (var i: f32 = 0.0; i < 4.0; i += 1.0) {
        // Slower, more graceful movement
        let phase = i * 1.57 + t * (0.15 + i * 0.03);
        let drift = vec2<f32>(
            sin(t * 0.1 + i * 2.0) * 0.2,
            cos(t * 0.08 + i * 1.5) * 0.15
        );
        let orb_pos = vec2<f32>(
            sin(phase) * (0.5 + sin(t * 0.12 + i) * 0.2),
            cos(phase * 0.7 + i * 0.8) * (0.35 + cos(t * 0.1 + i * 2.0) * 0.15)
        ) + drift;

        let dist = length(p - orb_pos);

        // Gentle breathing pulse
        let breath = sin(t * 0.8 + i * 1.2) * 0.3 + 0.7;
        let pulse_size = 0.08 + sin(t * 0.5 + i * 2.0) * 0.02;

        // Soft outer glow
        let glow = exp(-dist * 3.0) * 0.25 * breath;
        // Smaller, softer core
        let core = smoothstep(pulse_size, pulse_size * 0.2, dist) * 0.6;

        let orb_col = night_palette(i * 0.25 + t * 0.05);
        final_color += orb_col * glow;
        final_color += orb_col * core * breath;
    }

    // === Shooting stars / comets (occasional) ===
    for (var i: f32 = 0.0; i < 3.0; i += 1.0) {
        // Each comet has its own cycle
        let cycle_length = 8.0 + i * 3.0;
        let comet_t = (t * 0.5 + i * 2.5) % cycle_length;
        let comet_active = smoothstep(0.0, 0.3, comet_t) * smoothstep(cycle_length, cycle_length - 2.0, comet_t);

        if (comet_active > 0.01) {
            // Comet trajectory
            let start_pos = vec2<f32>(
                -1.2 + hash(vec2<f32>(i, 0.0)) * 0.8,
                0.8 - hash(vec2<f32>(i, 1.0)) * 0.4
            );
            let velocity = vec2<f32>(0.3 + hash(vec2<f32>(i, 2.0)) * 0.2, -0.15 - hash(vec2<f32>(i, 3.0)) * 0.1);
            let comet_pos = start_pos + velocity * comet_t * 1.5;

            // Comet head
            let comet_dist = length(p - comet_pos);
            let comet_glow = exp(-comet_dist * 15.0) * comet_active;

            // Tail
            let tail_dir = normalize(velocity);
            let to_point = p - comet_pos;
            let along_tail = -dot(to_point, tail_dir);
            let perp_dist = length(to_point + tail_dir * along_tail);
            let tail_fade = smoothstep(0.0, 0.4, along_tail) * smoothstep(0.8, 0.0, along_tail);
            let tail_glow = exp(-perp_dist * 20.0) * tail_fade * comet_active * 0.5;

            let comet_col = ember_palette(i * 0.3 + t * 0.1);
            final_color += comet_col * (comet_glow + tail_glow) * 0.7;
        }
    }

    // === Sparse twinkling stars ===
    let star_scale = 15.0;
    let star_uv = p * star_scale + vec2<f32>(t * 0.05, t * 0.03);
    let star_id = floor(star_uv);
    let star_pos = fract(star_uv) - 0.5;

    let star_rand = hash(star_id);
    // Much sparser stars
    if (star_rand > 0.96) {
        let star_offset = (hash2(star_id + vec2<f32>(42.0, 17.0)) - 0.5) * 0.6;
        let star_dist = length(star_pos - star_offset);

        // Slower, gentler twinkle
        let twinkle = sin(t * 2.0 + star_rand * 30.0) * 0.4 + 0.6;
        let star_brightness = exp(-star_dist * 40.0) * twinkle;

        // Vary star colors - mostly cool, occasional warm
        var star_col: vec3<f32>;
        if (star_rand > 0.99) {
            star_col = ember_palette(star_rand);  // Rare warm stars
        } else {
            star_col = night_palette(star_rand * 2.0);
        }
        final_color += star_col * star_brightness * 0.4;
    }

    // === Gentle aurora wisps at edges ===
    let aurora_y = p.y + 0.6;
    if (aurora_y > 0.0) {
        let aurora_wave = sin(p.x * 2.0 + t * 0.3) * 0.1 + sin(p.x * 3.5 + t * 0.2) * 0.05;
        let aurora_dist = abs(aurora_y - 0.3 - aurora_wave);
        let aurora_intensity = exp(-aurora_dist * 4.0) * smoothstep(0.0, 0.5, aurora_y) * 0.15;

        let aurora_col = night_palette(p.x * 0.3 + t * 0.1);
        final_color += aurora_col * aurora_intensity;
    }

    // === Strong vignette for lots of black around edges ===
    let center_dist = length(p);
    var vignette = 1.0 - smoothstep(0.2, 1.0, center_dist * 0.8);
    vignette = vignette * vignette;  // Stronger falloff
    final_color *= vignette;

    // === Additional edge darkening ===
    let edge_x = smoothstep(0.0, 0.3, abs(p.x) - 0.7);
    let edge_y = smoothstep(0.0, 0.3, abs(p.y) - 0.5);
    final_color *= 1.0 - max(edge_x, edge_y) * 0.8;

    // === Gentle overall breathing ===
    let global_breath = 0.7 + sin(t * 0.4) * 0.15;
    final_color *= global_breath;

    // === Final adjustments ===
    // Slight contrast boost for punchier colors against black
    final_color = pow(final_color, vec3<f32>(0.9));

    // Clamp very dim values to true black
    final_color = max(final_color - vec3<f32>(0.008), vec3<f32>(0.0));

    // Overall dimmer for nighttime
    final_color *= 0.8;

    return vec4<f32>(final_color, 1.0);
}
