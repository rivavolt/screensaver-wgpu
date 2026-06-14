// Plasma shader - Aurora borealis inspired, OLED optimized

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
    var positions = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -1.0),
        vec2<f32>(3.0, -1.0),
        vec2<f32>(-1.0, 3.0),
    );
    var out: VertexOutput;
    out.position = vec4<f32>(positions[vertex_index], 0.0, 1.0);
    out.uv = (positions[vertex_index] + 1.0) * 0.5;
    return out;
}

// Smooth noise function for organic movement
fn noise(p: vec2<f32>) -> f32 {
    return fract(sin(dot(p, vec2<f32>(12.9898, 78.233))) * 43758.5453);
}

fn smoothNoise(p: vec2<f32>) -> f32 {
    let i = floor(p);
    let f = fract(p);
    let u = f * f * (3.0 - 2.0 * f);

    return mix(
        mix(noise(i), noise(i + vec2<f32>(1.0, 0.0)), u.x),
        mix(noise(i + vec2<f32>(0.0, 1.0)), noise(i + vec2<f32>(1.0, 1.0)), u.x),
        u.y
    );
}

fn fbm(p: vec2<f32>) -> f32 {
    var value = 0.0;
    var amplitude = 0.5;
    var frequency = 1.0;
    var pp = p;

    for (var i = 0; i < 5; i++) {
        value += amplitude * smoothNoise(pp * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return value;
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let uv = in.uv;
    let t = uniforms.time * 0.15;  // Slower for more ambient feel

    // Transform coordinates for more interesting patterns
    var p = (uv - 0.5) * 2.0;
    p.x *= 1.6;  // Aspect ratio compensation

    // Multiple layers of flowing plasma
    var flow1 = sin(p.x * 2.0 + t) * cos(p.y * 1.5 + t * 0.7);
    var flow2 = sin(p.y * 2.5 - t * 0.8) * cos(p.x * 1.8 + t * 0.5);
    var flow3 = sin(length(p) * 3.0 - t * 1.2);

    // Organic distortion using fbm
    let distort = fbm(p * 2.0 + t * 0.3) * 0.3;
    let organic = fbm(p * 3.0 + vec2<f32>(flow1, flow2) * 0.5 + t * 0.2);

    // Combine layers
    var plasma = flow1 + flow2 * 0.7 + flow3 * 0.5;
    plasma += organic * 0.8;
    plasma += distort;
    plasma = plasma * 0.3 + 0.5;  // Normalize to 0-1

    // Aurora-like curtain effect - vertical waves
    let curtain = sin(p.x * 4.0 + t + sin(p.y * 2.0 + t * 0.5) * 2.0) * 0.5 + 0.5;
    let curtainMask = smoothstep(0.3, 0.7, curtain);

    // OLED color palette - deep blacks with ember/aurora accents
    var col = vec3<f32>(0.0);

    // Layer 1: Deep warm glow (ember core)
    let ember = smoothstep(0.4, 0.8, plasma) * curtainMask;
    col += vec3<f32>(0.15, 0.04, 0.02) * ember;

    // Layer 2: Aurora greens and teals (rare highlights)
    let aurora = smoothstep(0.6, 0.9, plasma + organic * 0.3);
    col += vec3<f32>(0.02, 0.08, 0.06) * aurora * (1.0 - curtainMask * 0.5);

    // Layer 3: Subtle purple/magenta wisps
    let wisp = smoothstep(0.5, 0.85, plasma * (1.0 + sin(t * 0.5) * 0.2));
    col += vec3<f32>(0.06, 0.02, 0.08) * wisp * curtainMask;

    // Breathing intensity modulation
    let breath = sin(t * 0.3) * 0.15 + 0.85;
    col *= breath;

    // Strong vignette - black edges for OLED
    let dist = length(uv - 0.5);
    let vig = 1.0 - smoothstep(0.25, 0.55, dist);
    col *= vig;

    // Ensure pure blacks stay black (OLED optimization)
    col = max(col - 0.01, vec3<f32>(0.0));

    return vec4<f32>(col, 1.0);
}
