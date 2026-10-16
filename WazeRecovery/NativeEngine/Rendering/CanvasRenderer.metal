#include <metal_stdlib>
using namespace metal;

struct VertexInput {
    float2 position [[attribute(0)]];
    float4 color    [[attribute(1)]];
    float2 texCoord [[attribute(2)]];
};

struct VertexOutput {
    float4 position [[position]];
    float4 color;
    float2 texCoord;
};

// Reconstructed from Waze default.metallib: SimpleTextureVertexShader & TileLineVertexShader
vertex VertexOutput SimpleTextureVertexShader(
    VertexInput in [[stage_in]])
{
    VertexOutput out;
    out.position = float4(in.position, 0.0, 1.0);
    out.color = in.color;
    out.texCoord = in.texCoord;
    return out;
}

// Reconstructed from Waze default.metallib: SimpleTextureFragmentShader
fragment float4 SimpleTextureFragmentShader(
    VertexOutput in [[stage_in]])
{
    return in.color;
}

// Blur Shaders from default.metallib
vertex VertexOutput BlurVertexShader(
    VertexInput in [[stage_in]])
{
    VertexOutput out;
    out.position = float4(in.position, 0.0, 1.0);
    out.color = in.color;
    out.texCoord = in.texCoord;
    return out;
}

fragment float4 BlurFragmentShader(
    VertexOutput in [[stage_in]],
    texture2d<float> texture [[texture(0)]],
    sampler textureSampler [[sampler(0)]])
{
    float4 color = texture.sample(textureSampler, in.texCoord);
    return color * in.color;
}
