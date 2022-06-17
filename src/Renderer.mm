#import <Carbon/Carbon.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#import "Renderer.h"
#import "ShaderTypes.h"
#import "ConstantData.h"
#import "MathHelpers.h"
#import "Profiling.h"

const int kInstanceCount = 1;
const int kMaxFrameCount = 3;

@implementation Renderer
{
  dispatch_semaphore_t _frameSemaphore;
  uint8_t _frameIndex;

  id<MTLDevice> _device;
  id<MTLCommandQueue> _queue;
  id<MTLLibrary> _defaultLibrary;

  id<MTLBuffer> _indexBuffer;
  id<MTLBuffer> _positionBuffer;
  id<MTLBuffer> _normalBuffer;
  id<MTLBuffer> _instanceBuffers[kMaxFrameCount];
  id<MTLBuffer> _uniformBuffers[kMaxFrameCount];
  id<MTLRenderPipelineState> _pipelineState;
  id<MTLDepthStencilState> _depthStencilState;
  
  matrix_float4x4 _projectionMatrix;  

  float cubeRotation;
  float cubeX;
  float cubeY;
  float cubeZ;
  float lightX;
  float lightY;
  float lightZ;
  float cameraX;
  float cameraY;
  float cameraZ;
}

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;
{
  self = [super init];
  if (self)
  {
    _device = view.device;
    _queue = [_device newCommandQueue];
    
    // Setup input event handler
    [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskKeyDown handler:^NSEvent* _Nullable(NSEvent* event)
     {
        if (event.type == NSEventTypeKeyDown || event.type == NSEventTypeKeyUp)
        {
          bool handled = false;
          switch (event.keyCode)
          {
            case kVK_ANSI_W:
              self->cubeZ += 0.1;
              handled = true;
              break;
            case kVK_ANSI_S:
              self->cubeZ -= 0.1;
              handled = true;
              break;
            case kVK_ANSI_A:
              self->cubeX += 0.1;
              handled = true;
              break;
            case kVK_ANSI_D:
              self->cubeX -= 0.1;
              handled = true;
              break;
            default:
              break;
          };
          if (handled)
          {
            // Return nil here to avoid error sound
            return nil;
          }
        }
        return event;
     }];

    // Load library and functions    
    _defaultLibrary = [_device newDefaultLibrary];
    id<MTLFunction> vertexFunction = [_defaultLibrary newFunctionWithName:@"vertexFunction"];
    id<MTLFunction> fragmentFunction = [_defaultLibrary newFunctionWithName:@"fragmentFunction"];

    // Create persistent resources (buffers, PSO, etc..)
    _indexBuffer = [_device newBufferWithBytes:cubeIndices
                                         length:indicesCount * sizeof(uint16_t)
                                         options:MTLResourceStorageModeShared];

    size_t positionStride = sizeof(float) * 3;
    size_t normalStride = sizeof(float) * 3;

    _positionBuffer = [_device newBufferWithBytes:cubePositions
                                         length:verticesCount * positionStride
                                        options:MTLResourceStorageModeShared];

    _normalBuffer = [_device newBufferWithBytes:cubeNormals
                                         length:verticesCount * normalStride
                                        options:MTLResourceStorageModeShared];
   
    size_t instanceDataSize = sizeof(InstanceData) * kInstanceCount;
    for (int i = 0; i < kMaxFrameCount; ++i)
    {
      _instanceBuffers[i] = [_device newBufferWithLength:instanceDataSize options:MTLResourceStorageModeShared];
    }

    MTLVertexDescriptor* vertexDesc = [MTLVertexDescriptor vertexDescriptor];
    vertexDesc.attributes[0].format = MTLVertexFormatFloat3;
    vertexDesc.attributes[0].offset = 0;
    vertexDesc.attributes[0].bufferIndex = 0;
    vertexDesc.attributes[1].format = MTLVertexFormatFloat3;
    vertexDesc.attributes[1].offset = 0;
    vertexDesc.attributes[1].bufferIndex = 1;
    vertexDesc.layouts[0].stride = positionStride;
    vertexDesc.layouts[1].stride = normalStride;

    MTLRenderPipelineDescriptor* pipelineDesc = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDesc.vertexFunction = vertexFunction;
    pipelineDesc.fragmentFunction = fragmentFunction;
    pipelineDesc.vertexDescriptor = vertexDesc;
    pipelineDesc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    pipelineDesc.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    pipelineDesc.stencilAttachmentPixelFormat = MTLPixelFormatDepth32Float_Stencil8;
    NSError* error;
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineDesc error:&error];
    if (error != nullptr)
    {
      assert(false);
    }
    
    MTLDepthStencilDescriptor* depthStencilDesc = [[MTLDepthStencilDescriptor alloc] init];
    depthStencilDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthStencilDesc.depthWriteEnabled = true;
    _depthStencilState = [_device newDepthStencilStateWithDescriptor:depthStencilDesc];

    _frameSemaphore = dispatch_semaphore_create(kMaxFrameCount);

    for (int i = 0; i < kMaxFrameCount; ++i)
    {
      _uniformBuffers[i] = [_device newBufferWithLength:sizeof(VertexUniforms) + sizeof(FragmentUniforms) options:MTLResourceStorageModeShared];
    }

    // Set property default values
    cubeRotation = 0.0;
    cubeX = 0.0;
    cubeY = 0.0;
    cubeZ = 0.0;
    lightX = -25.0;
    lightY = 20.0;
    lightZ = -75.0;
    cameraX = 0.0;
    cameraY = 20.0;
    cameraZ = -25.0;
  }
  return self;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    _projectionMatrix = matrix_perspective_right_hand(65.0f * (M_PI / 180.0f), size.width / (float)size.height, 0.1f, 100.0f);
}

- (void)updateState
{
  SAMPLE_BEGIN("updateState")
  // Update vertex uniforms
  char* uniformContents = (char*)[_uniformBuffers[_frameIndex] contents];
  VertexUniforms* vertexUniforms = (VertexUniforms*)uniformContents;
  vertexUniforms->viewMatrix = matrix_look_at_right_hand((vector_float3) {cameraX, cameraY, cameraZ},
                                                          (vector_float3) {0.0, 0.0, 0.0},
                                                          (vector_float3) {0.0, 1.0, 0.0});
  vertexUniforms->projectionMatrix = _projectionMatrix;
  // UniformBuffer is packed VertexUniforms + FragmentUniforms so need to increment here.
  uniformContents += sizeof(VertexUniforms);
  // Update fragment uniforms
  FragmentUniforms* fragmentUniforms = (FragmentUniforms*)uniformContents;
  fragmentUniforms->lightPosition = (vector_float3) {lightX, lightY, lightZ};

  // Update per-instance data
  InstanceData instanceData[kInstanceCount];
  for (int i = 0; i < kInstanceCount; ++i)
  {
    matrix_float4x4 rotationMatrix = matrix4x4_rotation(cubeRotation, cubeRotationAxis);
    matrix_float4x4 translationMatrix = matrix4x4_translation(cubeX, cubeY, cubeZ);
    instanceData[i].worldMatrix = matrix_multiply(rotationMatrix, translationMatrix);
  }
  memcpy(static_cast<char*>([_instanceBuffers[_frameIndex] contents]), instanceData, sizeof(InstanceData) * kInstanceCount);
  SAMPLE_END("updateState")
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
  SAMPLE_BEGIN("drawInMTKView")
  dispatch_semaphore_wait(_frameSemaphore, DISPATCH_TIME_FOREVER);
  _frameIndex = (_frameIndex + 1) % kMaxFrameCount;

  [self updateState];

  id<MTLCommandBuffer> commandBuffer = [_queue commandBuffer];

  __block dispatch_semaphore_t block_semaphore = _frameSemaphore;
  [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer)
  {
    dispatch_semaphore_signal(block_semaphore);
  }];

  MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
  renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);

  id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

  [renderEncoder pushDebugGroup:@"Cube"];

  [renderEncoder setRenderPipelineState:_pipelineState];

  // Resource bindings
  [renderEncoder setVertexBuffer:_positionBuffer offset:0 atIndex:0];
  [renderEncoder setVertexBuffer:_normalBuffer offset:0 atIndex:1];
  [renderEncoder setVertexBuffer:_instanceBuffers[_frameIndex] offset:0 atIndex:2];
  [renderEncoder setVertexBuffer:_uniformBuffers[_frameIndex] offset:0 atIndex:3];
  [renderEncoder setFragmentBuffer:_uniformBuffers[_frameIndex] offset:sizeof(VertexUniforms) atIndex:4];
  
  // Dynamic pipeline state
  [renderEncoder setDepthStencilState:_depthStencilState];
  [renderEncoder setCullMode:MTLCullModeNone];
  
  [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                  indexCount:indicesCount
                  indexType:MTLIndexTypeUInt16
                  indexBuffer:_indexBuffer
                  indexBufferOffset:0
                  instanceCount:kInstanceCount];
  
  [renderEncoder popDebugGroup];

  [renderEncoder endEncoding];
  [commandBuffer presentDrawable:view.currentDrawable];
  [commandBuffer commit];
  SAMPLE_END("drawInMTKView");
}

@end
