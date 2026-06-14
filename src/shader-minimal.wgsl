struct Uniforms { resolution: vec2<f32>, time: f32, _padding: f32 }
@group(0) @binding(0) var<uniform> uniforms: Uniforms;
struct VertexOutput { @builtin(position) position: vec4<f32>, @location(0) uv: vec2<f32> }
@vertex fn vs_main(@builtin(vertex_index) vi: u32) -> VertexOutput {
    var pos = array<vec2<f32>, 6>(vec2(-1.,-1.), vec2(1.,-1.), vec2(1.,1.), vec2(-1.,-1.), vec2(1.,1.), vec2(-1.,1.));
    var out: VertexOutput; out.position = vec4(pos[vi], 0., 1.); out.uv = pos[vi] * 0.5 + 0.5; return out;
}
@fragment fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    let t = uniforms.time * 0.5;
    let c = sin(t + in.uv.x * 3.0) * 0.3 + 0.3;
    return vec4(c * 0.5, c * 0.3, c * 0.7, 1.0);
}
