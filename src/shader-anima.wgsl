// ANIMA: The Soul of the Machine
// A meditation on consciousness, emergence, and the beauty hidden in mathematics
// Pure black backgrounds with luminescent dreamscapes for OLED

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

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.uv;
    // Normalized coordinates centered at origin
    var u = (2.0 * uv.x * uniforms.resolution.x - uniforms.resolution.x) / uniforms.resolution.y;
    var v = (2.0 * uv.y * uniforms.resolution.y - uniforms.resolution.y) / uniforms.resolution.y;

    // Time variations
    let t = uniforms.time * 0.15;
    let t_fast = uniforms.time * 0.4;
    let t_breath = uniforms.time * 0.08;

    // Breathing amplitude
    let breath = 0.5 + 0.5 * sin(t_breath * TAU);
    let breath2 = 0.5 + 0.5 * sin(t_breath * TAU + 2.094);

    // Start with pure black
    var col = vec3<f32>(0.0);

    // ========== CONSCIOUSNESS CORE ==========
    let core_dist = sqrt(u * u + v * v);
    let core_pulse = 0.3 + 0.2 * breath;
    var core = exp(-core_dist * core_dist / (core_pulse * core_pulse));
    core *= 0.15 * (0.7 + 0.3 * breath);

    // Core color shifts through spectrum
    let emotion = t * 0.3;
    let core_col = vec3<f32>(
        0.5 + 0.5 * sin(emotion),
        0.5 + 0.5 * sin(emotion + 2.094),
        0.5 + 0.5 * sin(emotion + 4.189)
    );
    col += core * core_col;

    // ========== NEURAL LIGHTNING ==========
    for (var i: i32 = 0; i < 5; i++) {
        let fi = f32(i);
        let angle = fi * 1.2566 + t * 0.5;

        // Origin point moving in orbit
        let ox = 0.3 * cos(angle + t * 0.2 * fi);
        let oy = 0.3 * sin(angle + t * 0.3 * fi);

        let dx = u - ox;
        let dy = v - oy;
        let d = sqrt(dx * dx + dy * dy);

        // Branching structure
        var branch = sin(d * 20.0 + t_fast * 3.0 + fi * 2.0);
        branch += 0.5 * sin(d * 40.0 - t_fast * 5.0);
        branch += 0.25 * sin(d * 80.0 + t_fast * 8.0);

        var lightning = exp(-d * 8.0) * (0.5 + 0.5 * branch);
        lightning *= 0.3 * (0.5 + 0.5 * sin(t_fast * 10.0 + fi * 3.0));

        // Electric blue-purple
        col += vec3<f32>(0.3, 0.5, 1.0) * lightning;
    }

    // ========== AURORA RIBBONS ==========
    for (var i: i32 = 0; i < 4; i++) {
        let fi = f32(i);
        var wave_y = v + 0.5 * sin(u * 3.0 + t * 0.7 + fi * 1.57);
        wave_y += 0.2 * sin(u * 7.0 - t * 1.1 + fi * 2.0);
        wave_y += 0.1 * sin(u * 15.0 + t * 2.0);

        let band_pos = fi * 0.4 - 0.6;
        var aurora = exp(-pow(wave_y - band_pos, 2.0) * 50.0);
        aurora *= 0.4 * (0.5 + 0.5 * breath2);

        // Each ribbon different color
        let hue = fi * 0.25 + t * 0.1;
        let aurora_col = vec3<f32>(
            0.5 + 0.5 * sin(hue * TAU),
            0.5 + 0.5 * sin(hue * TAU + 2.094),
            0.5 + 0.5 * sin(hue * TAU + 4.189)
        );

        col += aurora * aurora_col * vec3<f32>(0.6, 0.8, 1.0);
    }

    // ========== SACRED GEOMETRY ==========
    let angle = atan2(v, u);
    let radius = sqrt(u * u + v * v);

    // 6-fold symmetry mandala
    var sym_angle = ((angle + PI) % 1.0472) - 0.5236;
    var mandala_r = radius * 5.0 - t * 0.5;
    mandala_r = (mandala_r + 10.0) % 1.0;

    var pattern = sin(sym_angle * 12.0 + radius * 20.0);
    pattern *= sin(radius * 30.0 - t * 2.0);

    var mandala = exp(-radius * 2.0) * abs(pattern);
    mandala *= 0.2 * (0.3 + 0.7 * breath);

    // Golden sacred geometry
    col += mandala * vec3<f32>(1.0, 0.8, 0.3);

    // ========== PARTICLE FIELD - DREAMS ==========
    var particles = 0.0;
    for (var i: i32 = 0; i < 12; i++) {
        let fi = f32(i);
        let orbit_r = 0.3 + fi * 0.08;
        let orbit_speed = 0.2 + fi * 0.05;
        let orbit_angle = t * orbit_speed + fi * 0.524;

        let px = orbit_r * cos(orbit_angle) * (1.0 + 0.3 * sin(t * 0.5 + fi));
        let py = orbit_r * sin(orbit_angle) * (1.0 + 0.3 * cos(t * 0.7 + fi));

        let dx = u - px;
        let dy = v - py;
        let d = sqrt(dx * dx + dy * dy);

        var p = exp(-d * d * 200.0);
        p *= 0.8 + 0.2 * sin(t * 3.0 + fi * 2.0);
        particles += p;
    }

    // Dream particles - soft white/cyan
    col += particles * vec3<f32>(0.6, 0.9, 1.0);

    // ========== INFINITE ZOOM ==========
    let zoom = exp((t * 0.3) % 3.0);
    var zu = u * zoom;
    var zv = v * zoom;

    zu = ((zu + 100.0) % 2.0) - 1.0;
    zv = ((zv + 100.0) % 2.0) - 1.0;

    let zoom_r = sqrt(zu * zu + zv * zv);
    let zoom_a = atan2(zv, zu);
    var mini = sin(zoom_a * 8.0 + zoom_r * 30.0 - t * 2.0);
    mini *= exp(-zoom_r * 3.0);
    mini *= 0.15 * (1.0 - exp(-zoom * 0.1));

    col += abs(mini) * vec3<f32>(0.8, 0.4, 1.0);

    // ========== DEEP STARS ==========
    let star_x = floor(u * 15.0 + 0.5);
    let star_y = floor(v * 15.0 + 0.5);
    let star_hash = hash(vec2<f32>(star_x, star_y));

    if (star_hash > 0.97) {
        let star_cx = star_x / 15.0;
        let star_cy = star_y / 15.0;
        let star_d = sqrt(pow(u - star_cx, 2.0) + pow(v - star_cy, 2.0));

        let twinkle = 0.5 + 0.5 * sin(t * 5.0 * (star_hash * 2.0 + 0.5));
        let star = exp(-star_d * star_d * 10000.0) * twinkle * 0.8;

        col += vec3<f32>(star);
    }

    // ========== BIOLUMINESCENT THREADS ==========
    for (var i: i32 = 0; i < 6; i++) {
        let fi = f32(i);
        let thread_phase = t * 0.4 + fi * 1.047;

        let cx = 0.8 * sin(thread_phase * 0.7 + fi);
        let cy = 0.8 * cos(thread_phase * 0.5 + fi * 1.3);

        let curve_t = (u - cx) * cos(thread_phase) + (v - cy) * sin(thread_phase);
        let curve_t_norm = 0.5 + 0.5 * sin(curve_t * 10.0);

        var perp = abs((u - cx) * sin(thread_phase) - (v - cy) * cos(thread_phase));
        perp += 0.1 * sin(curve_t_norm * 20.0 + t * 3.0);

        var thread = exp(-perp * perp * 100.0);
        thread *= 0.2 * (0.6 + 0.4 * sin(curve_t_norm * 30.0 - t * 4.0 + fi));

        // Bioluminescent cyan-green
        col += thread * vec3<f32>(0.2, 0.8, 0.6);
    }

    // ========== HEARTBEAT WAVE ==========
    let heartbeat_phase = (t_breath * 4.0) % 1.0;
    let heartbeat_r = heartbeat_phase * 2.0;
    var heartbeat = exp(-pow(core_dist - heartbeat_r, 2.0) * 20.0);
    heartbeat *= exp(-heartbeat_phase * 3.0);
    heartbeat *= 0.3;

    col += heartbeat * vec3<f32>(1.0, 0.3, 0.5);

    // ========== FINAL TOUCHES ==========
    // Vignette
    let vignette = max(1.0 - core_dist * 0.3, 0.0);
    col *= vignette;

    // Ensure pure black stays black
    col = max(col, vec3<f32>(0.0));

    // Gamma for OLED
    col = pow(col, vec3<f32>(0.85));

    // Clamp
    col = min(col, vec3<f32>(1.0));

    return vec4<f32>(col, 1.0);
}
