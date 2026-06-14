// Bioluminescent Ocean - Deep sea dreamscape for OLED
// Floating jellyfish, glowing particles, gentle waves of light

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
    for (var i: i32 = 0; i < 5; i++) {
        v += a * noise(p);
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

// Bioluminescent colors - cyan, magenta, deep blue
fn bioColor(t: f32) -> vec3<f32> {
    let c1 = vec3<f32>(0.0, 0.8, 1.0);   // Cyan
    let c2 = vec3<f32>(0.8, 0.2, 0.9);   // Magenta
    let c3 = vec3<f32>(0.2, 0.4, 1.0);   // Blue
    let c4 = vec3<f32>(0.0, 1.0, 0.6);   // Teal

    let tt = fract(t) * 4.0;
    if (tt < 1.0) { return mix(c1, c2, tt); }
    if (tt < 2.0) { return mix(c2, c3, tt - 1.0); }
    if (tt < 3.0) { return mix(c3, c4, tt - 2.0); }
    return mix(c4, c1, tt - 3.0);
}

// Warm accent colors
fn warmColor(t: f32) -> vec3<f32> {
    return vec3<f32>(
        0.5 + 0.5 * sin(t * TAU),
        0.3 + 0.3 * sin(t * TAU + 1.0),
        0.2 + 0.2 * sin(t * TAU + 2.0)
    );
}

// Jellyfish bell shape
fn jellyfish(p: vec2<f32>, center: vec2<f32>, size: f32, phase: f32) -> f32 {
    let q = p - center;

    // Pulsing bell
    let pulse = 1.0 + sin(phase * 2.0) * 0.15;
    let bell_w = size * pulse;
    let bell_h = size * 0.7 * (1.0 + sin(phase * 2.0 + 0.5) * 0.1);

    // Bell shape - squashed circle with flat bottom
    let bell_p = vec2<f32>(q.x / bell_w, (q.y + size * 0.3) / bell_h);
    var bell = length(bell_p);
    bell = smoothstep(1.0, 0.7, bell) * step(q.y, size * 0.2);

    // Inner glow
    let inner = exp(-length(q) * 8.0 / size) * 0.5;

    return bell + inner;
}

// Tentacle
fn tentacle(p: vec2<f32>, start: vec2<f32>, t: f32, seed: f32) -> f32 {
    var acc: f32 = 0.0;
    var pos = start;

    for (var i: f32 = 0.0; i < 12.0; i += 1.0) {
        let wave = sin(t * 1.5 + i * 0.5 + seed * 10.0) * 0.03 * (1.0 + i * 0.1);
        pos.x += wave;
        pos.y -= 0.025;

        let d = length(p - pos);
        let thickness = 0.008 * (1.0 - i / 15.0);
        acc += smoothstep(thickness * 2.0, 0.0, d) * (1.0 - i / 12.0);
    }

    return acc;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.uv;
    var p = (uv * 2.0 - 1.0);
    p.x *= uniforms.resolution.x / uniforms.resolution.y;

    let t = uniforms.time * 0.08; // Very slow
    var col = vec3<f32>(0.0);

    // === LAYER 1: Deep water caustics ===
    let caustic1 = fbm(p * 3.0 + vec2<f32>(t * 0.3, t * 0.2));
    let caustic2 = fbm(p * 4.0 - vec2<f32>(t * 0.2, t * 0.3) + 5.0);
    let caustics = caustic1 * caustic2;
    let deep_blue = vec3<f32>(0.0, 0.02, 0.08);
    col += deep_blue * (1.0 + caustics * 2.0);

    // === LAYER 2: Floating jellyfish ===
    for (var i: f32 = 0.0; i < 5.0; i += 1.0) {
        let seed = hash(vec2<f32>(i * 127.1, i * 311.7));
        let speed = 0.15 + seed * 0.1;

        // Gentle floating motion
        let jelly_x = sin(t * speed + i * 2.0) * 0.6;
        let jelly_y = cos(t * speed * 0.7 + i * 1.5) * 0.4 + sin(t * 0.1 + i) * 0.1;
        let jelly_center = vec2<f32>(jelly_x, jelly_y);
        let jelly_size = 0.12 + seed * 0.08;

        let phase = t * 1.5 + i * 1.3;

        // Bell
        let bell = jellyfish(p, jelly_center, jelly_size, phase);
        let jelly_col = bioColor(seed + t * 0.1);
        col += jelly_col * bell * 0.6;

        // Tentacles
        for (var j: f32 = 0.0; j < 5.0; j += 1.0) {
            let tent_start = jelly_center + vec2<f32>((j - 2.0) * 0.02, -jelly_size * 0.5);
            let tent = tentacle(p, tent_start, t + i, seed + j * 0.1);
            col += jelly_col * tent * 0.3;
        }
    }

    // === LAYER 3: Bioluminescent particles rising ===
    for (var i: f32 = 0.0; i < 40.0; i += 1.0) {
        let seed = hash(vec2<f32>(i, i * 0.7));
        let seed2 = hash(vec2<f32>(i * 1.3, i * 0.3));

        // Rising motion with drift
        var particle_y = fract(seed + t * (0.05 + seed2 * 0.03)) * 2.4 - 1.2;
        let particle_x = (seed2 - 0.5) * 2.0 + sin(t * 0.5 + seed * 10.0) * 0.1;
        let particle_pos = vec2<f32>(particle_x, particle_y);

        let d = length(p - particle_pos);
        let size = 0.003 + seed * 0.004;
        let brightness = 0.5 + seed2 * 0.5;

        // Soft glow
        let glow = exp(-d * 150.0 * (1.0 / size)) * brightness;
        let twinkle = 0.7 + sin(t * 3.0 + seed * 20.0) * 0.3;
        col += bioColor(seed * 2.0 + t * 0.2) * glow * twinkle;
    }

    // === LAYER 4: Gentle light rays from above ===
    for (var i: f32 = 0.0; i < 3.0; i += 1.0) {
        let ray_x = sin(t * 0.1 + i * 2.0) * 0.5;
        let ray_angle = 0.1 + sin(t * 0.05 + i) * 0.05;

        let ray_p = p - vec2<f32>(ray_x, 1.0);
        let rotated = vec2<f32>(
            ray_p.x * cos(ray_angle) - ray_p.y * sin(ray_angle),
            ray_p.x * sin(ray_angle) + ray_p.y * cos(ray_angle)
        );

        let ray = exp(-abs(rotated.x) * 8.0) * smoothstep(0.0, -1.5, rotated.y);
        let ray_col = vec3<f32>(0.1, 0.3, 0.5);
        col += ray_col * ray * 0.15;
    }

    // === LAYER 5: Ambient plankton glow clouds ===
    let glow1 = fbm(p * 2.0 + t * 0.1);
    let glow2 = fbm(p * 1.5 - t * 0.08 + 3.0);
    let ambient = glow1 * glow2;
    let ambient_thresh = 0.3 + sin(t * 0.2) * 0.1;
    let ambient_glow = smoothstep(ambient_thresh, ambient_thresh + 0.2, ambient);
    col += bioColor(ambient + t * 0.05) * ambient_glow * 0.08;

    // === LAYER 6: Occasional bright flash (rare bioluminescence) ===
    let flash_time = floor(t * 0.3);
    let flash_seed = hash(vec2<f32>(flash_time, flash_time * 0.7));
    if (flash_seed > 0.85) {
        let flash_pos = vec2<f32>(
            (hash(vec2<f32>(flash_time * 1.1, 0.0)) - 0.5) * 1.5,
            (hash(vec2<f32>(flash_time * 1.3, 1.0)) - 0.5) * 1.0
        );
        let flash_phase = fract(t * 0.3);
        let flash_intensity = sin(flash_phase * PI) * (1.0 - flash_phase);
        let flash_d = length(p - flash_pos);
        col += bioColor(flash_seed * 3.0) * exp(-flash_d * 5.0) * flash_intensity * 0.5;
    }

    // === OLED PROTECTION ===

    // Vignette - darker at edges
    let vd = length(p * vec2<f32>(0.7, 0.9));
    let vig = 1.0 - smoothstep(0.3, 1.2, vd);
    col *= vig * vig;

    // Depth fade - darker at bottom (deep water)
    let depth = smoothstep(-1.0, 0.5, p.y);
    col *= 0.4 + depth * 0.6;

    // Moving shadow patches
    let shadow = fbm(p * 1.5 + t * 0.15);
    col *= 0.5 + shadow * 0.5;

    // === FINAL ===

    // Slight blue tint to blacks
    col += vec3<f32>(0.0, 0.005, 0.015) * (1.0 - length(col));

    // Brightness limit
    col = min(col, vec3<f32>(0.85));

    // True black threshold
    col = max(col - 0.01, vec3<f32>(0.0));

    // Gentle breathing
    col *= 0.85 + sin(t * 0.4) * 0.1;

    return vec4<f32>(col, 1.0);
}
