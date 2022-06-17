#include <metal_stdlib>
#import "ShaderTypes.h"

using namespace metal;

struct VertexIn
{
  float3 position [[attribute(0)]];
  float3 normal [[attribute(1)]];
};

struct VertexOut
{
  float4 position [[position]];
  float3 normal;
  float3 fragPos;
};

vertex VertexOut vertexFunction(VertexIn vIn [[stage_in]],
                               constant InstanceData* instanceData [[buffer(2)]],
                               constant VertexUniforms& uniforms [[buffer(3)]],
                               ushort iid [[instance_id]])
{
  VertexOut out;
  out.position = uniforms.projectionMatrix * uniforms.viewMatrix * instanceData[iid].worldMatrix * float4(vIn.position, 1.0);
  out.fragPos = (uniforms.viewMatrix * instanceData[iid].worldMatrix * float4(vIn.position, 1.0)).xyz;
  out.normal = vIn.normal;
  return out;
}

fragment float4 fragmentFunction(VertexOut fIn [[stage_in]],
                                constant FragmentUniforms& uniforms [[buffer(4)]])
{
  float3 norm = normalize(fIn.normal);
  float3 lightDir = normalize(uniforms.lightPosition - fIn.fragPos);
  float3 diff = max(dot(norm, lightDir), 0.0);
  const float3 color = float3(0.5, 0.5, 0.0);
  const float3 ambient = float3(0.6, 0.6, 0.6);
  float3 diffuse = diff * color + ambient * color;
  return float4(diffuse, 1.0);
}
