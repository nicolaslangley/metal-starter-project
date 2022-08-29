#import <Metal/Metal.h>

#include "Renderer.h"
#include "ShaderTypes.h"

Renderer::Renderer(MTKView* view)
{
  m_Device = view.device;
  m_Queue = [m_Device newCommandQueue];
  id<MTLLibrary> defaultLibrary = [m_Device newDefaultLibrary];

  id<MTLFunction> vertexFunction = [defaultLibrary newFunctionWithName:@"vertexFunction"];
  id<MTLFunction> fragmentFunction = [defaultLibrary newFunctionWithName:@"fragmentFunction"];

  MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
  pipelineStateDescriptor.label = @"Simple Pipeline";
  pipelineStateDescriptor.vertexFunction = vertexFunction;
  pipelineStateDescriptor.fragmentFunction = fragmentFunction;
  pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat;
  pipelineStateDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat;
  pipelineStateDescriptor.stencilAttachmentPixelFormat = view.depthStencilPixelFormat;

  NSError *error;
  m_PipelineState = [m_Device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                           error:&error];
}

void Renderer::UpdateViewport(double width, double height)
{
  m_ViewportSize.x = width;
  m_ViewportSize.y = height;
}

void Renderer::Render(MTKView* view)
{
  static const VertexIn triangleVertices[] =
  {
      // 2D positions,    RGBA colors
      { {  250,  -250 }, { 1, 0, 0, 1 } },
      { { -250,  -250 }, { 0, 1, 0, 1 } },
      { {    0,   250 }, { 0, 0, 1, 1 } },
  };
  
  id<MTLCommandBuffer> commandBuffer = [m_Queue commandBuffer];
  MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
  
  if (renderPassDescriptor != nil)
  {
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [renderEncoder setViewport:(MTLViewport){0.0, 0.0, static_cast<double>(m_ViewportSize.x), static_cast<double>(m_ViewportSize.y), 0.0, 1.0 }];
    [renderEncoder setRenderPipelineState:m_PipelineState];
    [renderEncoder setVertexBytes:triangleVertices
                           length:sizeof(triangleVertices)
                          atIndex:InputIndexVertices];
    [renderEncoder setVertexBytes:&m_ViewportSize
                           length:sizeof(m_ViewportSize)
                          atIndex:InputIndexViewportSize];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:3];
    [renderEncoder endEncoding];
  }
  
  [commandBuffer presentDrawable:view.currentDrawable];
  [commandBuffer commit];
}
