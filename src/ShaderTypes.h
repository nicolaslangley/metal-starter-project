// Shared includes between Metal shaders and C
#ifndef shader_types_h
#define shader_types_h

#import <simd/simd.h>

struct VertexUniforms
{
  matrix_float4x4 viewMatrix;
  matrix_float4x4 projectionMatrix;
};

struct FragmentUniforms
{
  simd_float3 lightPosition;
};

struct InstanceData
{
  matrix_float4x4 worldMatrix;
};

#endif /* shader_types_h */
