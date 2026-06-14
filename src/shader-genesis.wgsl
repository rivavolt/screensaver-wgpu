// "Genesis" - A universe dreaming itself into existence
// For the moment between waking and sleep

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
        vec2<f32>(-1.0, -1.0), vec2<f32>(1.0, -1.0), vec2<f32>(1.0, 1.0),
        vec2<f32>(-1.0, -1.0), vec2<f32>(1.0, 1.0), vec2<f32>(-1.0, 1.0),
    );
    var out: VertexOutput;
    out.position = vec4<f32>(positions[vertex_index], 0.0, 1.0);
    out.uv = positions[vertex_index] * 0.5 + 0.5;
    return out;
}

const PI: f32 = 3.14159265359;
const TAU: f32 = 6.28318530718;
const PHI: f32 = 1.61803398875; // Golden ratio

fn hash(p: vec2<f32>) -> f32 {
    return fract(sin(dot(p, vec2<f32>(127.1, 311.7))) * 43758.5453);
}

fn hash3(p: vec2<f32>) -> vec3<f32> {
    return vec3<f32>(hash(p), hash(p + 37.0), hash(p + 71.0));
}

fn noise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2<f32>(1.0, 0.0)), u.x),
               mix(hash(i + vec2<f32>(0.0, 1.0)), hash(i + vec2<f32>(1.0, 1.0)), u.x), u.y);
}

fn fbm(p_in: vec2<f32>, octaves: i32) -> f32 {
    var p = p_in;
    var v = 0.0;
    var a = 0.5;
    let rot = mat2x2<f32>(0.8, 0.6, -0.6, 0.8);
    for (var i = 0; i < octaves; i++) {
        v += a * noise(p);
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

// Smooth minimum for organic blending
fn smin(a: f32, b: f32, k: f32) -> f32 {
    let h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

// The color of dreams
fn dream_color(t: f32, mood: f32) -> vec3<f32> {
    let c1 = vec3<f32>(0.1, 0.0, 0.2);   // Deep violet void
    let c2 = vec3<f32>(0.0, 0.3, 0.4);   // Ocean depths
    let c3 = vec3<f32>(0.4, 0.1, 0.3);   // Nebula pink
    let c4 = vec3<f32>(0.1, 0.4, 0.3);   // Bioluminescent
    let c5 = vec3<f32>(0.5, 0.3, 0.1);   // Ember warmth

    var col = mix(c1, c2, sin(t * TAU) * 0.5 + 0.5);
    col = mix(col, c3, sin(t * TAU * PHI) * 0.5 + 0.5);
    col = mix(col, c4, sin(t * TAU / PHI + mood) * 0.5 + 0.5);
    col = mix(col, c5, sin(t * TAU * 0.5 + mood * 2.0) * 0.3 + 0.2);

    return col;
}

// Soul palette - colors that feel alive
fn soul(t: f32) -> vec3<f32> {
    return 0.5 + 0.5 * cos(TAU * (t + vec3<f32>(0.0, 0.1, 0.2)));
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.uv;
    var p = (uv * 2.0 - 1.0);
    p.x *= uniforms.resolution.x / uniforms.resolution.y;

    let t = uniforms.time * 0.08;
    var col = vec3<f32>(0.0);

    // === THE BREATHING VOID ===
    // The universe inhales and exhales
    let breath = sin(t * 0.5) * 0.5 + 0.5;
    let heartbeat = pow(sin(t * 1.2) * 0.5 + 0.5, 8.0);

    // Void texture - like looking into deep water
    let void_noise = fbm(p * 3.0 + t * 0.1, 5);
    let void_col = dream_color(void_noise, t);
    col += void_col * void_noise * void_noise * 0.1 * (0.7 + breath * 0.3);

    // === THE COSMIC JELLYFISH ===
    // Bioluminescent beings drifting through the void
    for (var i = 0.0; i < 4.0; i += 1.0) {
        let jelly_t = t * 0.3 + i * PHI;
        let jelly_center = vec2<f32>(
            sin(jelly_t) * 0.5 + sin(jelly_t * PHI) * 0.2,
            cos(jelly_t * 0.7) * 0.4 + cos(jelly_t * PHI * 0.5) * 0.15
        );

        // Bell of the jellyfish - pulsing dome
        let to_jelly = p - jelly_center;
        let jelly_dist = length(to_jelly);
        let pulse = sin(t * 2.0 + i * 1.5) * 0.3 + 0.7;
        let bell_size = 0.15 * pulse;
        let bell = smoothstep(bell_size, bell_size * 0.3, jelly_dist);

        // Tentacles - flowing curves beneath
        var tentacle_glow = 0.0;
        for (var j = 0.0; j < 5.0; j += 1.0) {
            let tent_angle = j * TAU / 5.0 + sin(t + i) * 0.5;
            let tent_len = 0.3 + sin(t * 0.5 + j) * 0.1;

            for (var k = 0.0; k < 10.0; k += 1.0) {
                let seg = k / 10.0;
                let wave = sin(seg * 8.0 + t * 3.0 + j) * 0.05 * seg;
                let tent_pos = jelly_center + vec2<f32>(
                    sin(tent_angle + wave) * seg * tent_len,
                    -seg * tent_len * 0.8 - 0.05
                );
                let td = length(p - tent_pos);
                tentacle_glow += exp(-td * 40.0) * (1.0 - seg * 0.8) * 0.15;
            }
        }

        let jelly_col = soul(i * 0.25 + t * 0.1);
        let inner_glow = exp(-jelly_dist * 4.0) * 0.5;
        col += jelly_col * (bell * 0.6 + inner_glow + tentacle_glow) * (0.4 + heartbeat * 0.2);
    }

    // === THE THREADS OF FATE ===
    // Cosmic strings connecting everything
    for (var i = 0.0; i < 7.0; i += 1.0) {
        let string_phase = t * 0.15 + i * TAU / 7.0;
        let string_y = sin(string_phase) * 0.6;

        // The string undulates
        var string_intensity = 0.0;
        for (var x = -1.5; x < 1.5; x += 0.05) {
            let wave1 = sin(x * 5.0 + t * 2.0 + i) * 0.1;
            let wave2 = sin(x * 8.0 - t * 1.5 + i * PHI) * 0.05;
            let string_pos = vec2<f32>(x, string_y + wave1 + wave2);
            let d = length(p - string_pos);
            string_intensity += exp(-d * 30.0) * 0.03;
        }

        let string_col = dream_color(i * 0.14 + t * 0.05, sin(i));
        col += string_col * string_intensity * 1.5;
    }

    // === THE IMPOSSIBLE GEOMETRY ===
    // Recursive shapes that shouldn't exist
    var geo = p;
    var geo_col = vec3<f32>(0.0);

    for (var i = 0.0; i < 5.0; i += 1.0) {
        // Fold space
        geo = abs(geo) - 0.4 + sin(t * 0.3 + i) * 0.1;
        geo = geo * mat2x2<f32>(cos(t * 0.1 + i), sin(t * 0.1 + i),
                                -sin(t * 0.1 + i), cos(t * 0.1 + i));

        let d = length(geo) - 0.1;
        let shape = exp(-abs(d) * 20.0);
        geo_col += soul(length(p) + i * 0.2 + t * 0.3) * shape * 0.15;
    }
    col += geo_col;

    // === THE BIRTH OF STARS ===
    // Points of light emerging from nothing
    let star_field = p * 20.0 + vec2<f32>(t * 0.2, t * 0.15);
    let star_id = floor(star_field);
    let star_f = fract(star_field) - 0.5;

    let star_rand = hash(star_id);
    if (star_rand > 0.9) {
        let star_offset = (hash3(star_id).xy - 0.5) * 0.7;
        let star_d = length(star_f - star_offset);

        // Stars are born, live, and fade
        let star_life = sin(t * 0.5 + star_rand * 100.0) * 0.5 + 0.5;
        let star_brightness = exp(-star_d * 50.0) * star_life;

        // Some stars are special - they pulse with color
        var star_col = vec3<f32>(1.0);
        if (star_rand > 0.97) {
            star_col = soul(star_rand * 5.0 + t * 0.2);
            let pulse_bright = pow(sin(t * 3.0 + star_rand * 50.0) * 0.5 + 0.5, 2.0);
            col += star_col * star_brightness * (1.0 + pulse_bright * 2.0) * 0.8;
        } else {
            col += star_col * star_brightness * 0.4;
        }
    }

    // === THE RIVER OF LIGHT ===
    // A flowing stream of luminescence
    let river_y = sin(p.x * 2.0 + t) * 0.3 + sin(p.x * 3.0 - t * 0.7) * 0.15;
    let river_dist = abs(p.y - river_y);
    let river_width = 0.08 + sin(p.x * 5.0 + t * 2.0) * 0.03;
    let river = smoothstep(river_width, 0.0, river_dist);

    // The river carries particles
    let particle_uv = vec2<f32>(p.x * 10.0 + t * 3.0, p.y * 10.0);
    let particle_noise = noise(particle_uv);
    let particles = river * particle_noise * particle_noise;

    col += dream_color(p.x + t * 0.2, t) * (river * 0.3 + particles * 0.4);

    // === THE CENTRAL EYE ===
    // The universe looking back at you
    let eye_pulse = sin(t * 0.7) * 0.1;
    let eye_dist = length(p);

    // Iris rings
    for (var i = 0.0; i < 4.0; i += 1.0) {
        let ring_r = 0.15 + i * 0.08 + eye_pulse;
        let ring = smoothstep(0.02, 0.0, abs(eye_dist - ring_r));
        let ring_col = soul(i * 0.25 + t * 0.15);
        col += ring_col * ring * 0.4;
    }

    // Pupil - the void at the center
    let pupil = smoothstep(0.08, 0.02, eye_dist);
    col = mix(col, vec3<f32>(0.0), pupil * 0.8);

    // Highlight - the spark of consciousness
    let highlight_pos = vec2<f32>(-0.03, 0.03);
    let highlight = exp(-length(p - highlight_pos) * 80.0);
    col += vec3<f32>(0.8, 0.9, 1.0) * highlight * 0.6;

    // === THE FIBONACCI SPIRAL ===
    // Golden ratio made visible
    let spiral_angle = atan2(p.y, p.x);
    let spiral_r = length(p);
    let golden_spiral = abs(fract(log(spiral_r) / log(PHI) - spiral_angle / TAU + t * 0.1) - 0.5);
    let spiral_line = exp(-golden_spiral * 30.0) * smoothstep(0.8, 0.2, spiral_r);
    col += soul(spiral_r + t * 0.2) * spiral_line * 0.25;

    // === OLED SANCTUARY ===

    // The void breathes
    let void_breath = fbm(p * 1.5 + t * 0.15, 4);
    let darkness = smoothstep(0.3, 0.6, void_breath);
    col *= 0.4 + darkness * 0.6;

    // Vignette - the edges dissolve into nothing
    let vd = length(p);
    var vig = 1.0 - smoothstep(0.3, 1.1, vd * 0.7);
    vig = pow(vig, 1.5);
    col *= vig;

    // Edge absorption
    let edge = smoothstep(0.0, 0.35, 1.0 - max(abs(p.x) * 0.6, abs(p.y) * 0.7));
    col *= edge;

    // === FINAL MEDITATION ===

    // Everything breathes together
    col *= 0.7 + breath * 0.2 + heartbeat * 0.1;

    // Gentle color shift over time - the mood evolves
    let mood_shift = sin(t * 0.1) * 0.1;
    col.r *= 1.0 + mood_shift;
    col.b *= 1.0 - mood_shift * 0.5;

    // Soft glow
    col = pow(col, vec3<f32>(0.95));

    // Cap brightness
    col = min(col, vec3<f32>(0.85));

    // True black threshold
    col = max(col - 0.02, vec3<f32>(0.0));

    return vec4<f32>(col, 1.0);
}
