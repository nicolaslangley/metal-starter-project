#ifndef Renderer_h
#define Renderer_h

#import <MetalKit/MetalKit.h>

class Renderer
{
public:
  Renderer(MTKView* view);
  ~Renderer() = default;

  void UpdateViewport(double width, double height);
  void Render(MTKView* view);

private:
  id<MTLDevice> m_Device;
  id<MTLCommandQueue> m_Queue;
  id<MTLRenderPipelineState> m_PipelineState;
  vector_uint2 m_ViewportSize;
};

#endif /* Renderer_h */
