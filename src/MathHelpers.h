#ifndef MathHelpers_h
#define MathHelpers_h

#import <simd/simd.h>

inline matrix_float4x4 matrix4x4_translation(float tx, float ty, float tz)
{
    return (matrix_float4x4) {{
        { 1,   0,  0,  0 },
        { 0,   1,  0,  0 },
        { 0,   0,  1,  0 },
        { tx, ty, tz,  1 }
    }};
}

inline static matrix_float4x4 matrix4x4_rotation(float radians, vector_float3 axis)
{
    axis = vector_normalize(axis);
    float ct = cosf(radians);
    float st = sinf(radians);
    float ci = 1 - ct;
    float x = axis.x, y = axis.y, z = axis.z;

    return (matrix_float4x4) {{
        { ct + x * x * ci,     y * x * ci + z * st, z * x * ci - y * st, 0},
        { x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0},
        { x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0},
        {                   0,                   0,                   0, 1}
    }};
}

inline matrix_float4x4 matrix_perspective_right_hand(float fovyRadians, float aspect, float nearZ, float farZ)
{
    float ys = 1 / tanf(fovyRadians * 0.5);
    float xs = ys / aspect;
    float zs = farZ / (nearZ - farZ);

    return (matrix_float4x4) {{
        { xs,   0,          0,  0 },
        {  0,  ys,          0,  0 },
        {  0,   0,         zs, -1 },
        {  0,   0, nearZ * zs,  0 }
    }};
}

// https://www.3dgep.com/understanding-the-view-matrix/#The_Camera_Transformation
inline matrix_float4x4 matrix_look_at_right_hand(vector_float3 eye, vector_float3 target, vector_float3 up)
{
  vector_float3 z_axis = vector_normalize(eye - target);
  vector_float3 x_axis = vector_normalize(vector_cross(up, z_axis));
  vector_float3 y_axis = vector_cross(z_axis, x_axis);
  return (matrix_float4x4) {{
      { x_axis.x, y_axis.x, z_axis.x,  0 },
      { x_axis.y, y_axis.y, z_axis.y,  0 },
      { x_axis.z, y_axis.z, z_axis.z, 0 },
      { -vector_dot(x_axis, eye), -vector_dot(y_axis, eye), -vector_dot(z_axis, eye),  1 }
  }};
}

#endif /* MathHelpers_h */