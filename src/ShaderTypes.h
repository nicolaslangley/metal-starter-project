#ifndef ShaderTypes_h
#define ShaderTypes_h

#import <simd/simd.h>

enum BufferIndexValue
{
  InputIndexVertices = 0,
  InputIndexViewportSize = 1,
};

struct VertexIn
{
  vector_float2 position;
  vector_float4 color;
};

#endif /* ShaderTypes_h */
