#include <metal_stdlib>
#include "ShaderTypes.h"

using namespace metal;

struct VertexOut
{
  float4 position [[position]];
  float4 color;
};

vertex VertexOut vertexFunction(uint vertexID [[vertex_id]],
                                constant VertexIn *vertices [[buffer(InputIndexVertices)]],
                                constant vector_uint2 *viewportSizePointer [[buffer(InputIndexViewportSize)]])
{
  VertexOut out;
  float2 pixelSpacePosition = vertices[vertexID].position.xy;
  vector_float2 viewportSize = vector_float2(*viewportSizePointer);
  out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
  out.position.xy = pixelSpacePosition / (viewportSize / 2.0);
  out.color = vertices[vertexID].color;
  return out;
}

fragment float4 fragmentFunction(VertexOut in [[stage_in]])
{
    return in.color;
}
