#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#include "ShaderTypes.h"

@interface MTKViewDelegate: NSObject<MTKViewDelegate>
-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;
@end

@implementation MTKViewDelegate
{
  id<MTLDevice> _device;
  id<MTLCommandQueue> _queue;
  id<MTLRenderPipelineState> _pipelineState;
  vector_uint2 _viewportSize;
}

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;
{
  self = [super init];
  if (self)
  {
    _device = view.device;
    _queue = [_device newCommandQueue];
    id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

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
    _pipelineState = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor
                                                             error:&error];
  }
  return self;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
  _viewportSize.x = size.width;
  _viewportSize.y = size.height;
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
  static const VertexIn triangleVertices[] =
  {
      // 2D positions,    RGBA colors
      { {  250,  -250 }, { 1, 0, 0, 1 } },
      { { -250,  -250 }, { 0, 1, 0, 1 } },
      { {    0,   250 }, { 0, 0, 1, 1 } },
  };
  
  id<MTLCommandBuffer> commandBuffer = [_queue commandBuffer];
  MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;
  
  if (renderPassDescriptor != nil)
  {
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [renderEncoder setViewport:(MTLViewport){0.0, 0.0, static_cast<double>(_viewportSize.x), static_cast<double>(_viewportSize.y), 0.0, 1.0 }];
    [renderEncoder setRenderPipelineState:_pipelineState];
    [renderEncoder setVertexBytes:triangleVertices
                           length:sizeof(triangleVertices)
                          atIndex:InputIndexVertices];
    [renderEncoder setVertexBytes:&_viewportSize
                           length:sizeof(_viewportSize)
                          atIndex:InputIndexViewportSize];
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:3];
    [renderEncoder endEncoding];
  }
  
  [commandBuffer presentDrawable:view.currentDrawable];
  [commandBuffer commit];
}
@end

@interface NSWindowDelegate : NSObject<NSWindowDelegate>
@end

@implementation NSWindowDelegate
- (BOOL)windowShouldClose:(id)sender {
  return YES;
}

- (void)windowDidResize:(NSNotification*)notification {
}
@end

@interface AppDelegate : NSObject<NSApplicationDelegate>
@end

@implementation AppDelegate
{
  NSWindow* _window;
  MTKView* _view;
  MTKViewDelegate* _viewDelegate;
  NSWindowDelegate* _windowDelegate;
}

- (void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
  NSRect screen_rect = NSScreen.mainScreen.frame;
  const NSUInteger style =
          NSWindowStyleMaskTitled |
          NSWindowStyleMaskClosable |
          NSWindowStyleMaskMiniaturizable |
          NSWindowStyleMaskResizable;
  const float window_scale = 4.0 / 5.0;
  NSRect window_rect = NSMakeRect(0, 0, screen_rect.size.width * window_scale, screen_rect.size.height * window_scale);
  _window = [[NSWindow alloc]
          initWithContentRect:window_rect
          styleMask:style
          backing:NSBackingStoreBuffered
          defer:NO];
  _windowDelegate = [[NSWindowDelegate alloc] init];
  [_window setDelegate:_windowDelegate];
  
  _view = [[MTKView alloc] initWithFrame:window_rect];
  id<MTLDevice> device = MTLCreateSystemDefaultDevice();
  [_view setDevice:device];
  [_view setColorPixelFormat:MTLPixelFormatBGRA8Unorm];
//  [_view setDepthStencilPixelFormat:MTLPixelFormatDepth32Float_Stencil8];
  _viewDelegate = [[MTKViewDelegate alloc] initWithMetalKitView:_view];
  [_view setDelegate:_viewDelegate];
  [_viewDelegate mtkView:_view drawableSizeWillChange:_view.drawableSize];
  
  [_window setContentView:_view];
  [_window makeFirstResponder:_view];
  
  [_window center];
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  [NSApp activateIgnoringOtherApps:YES];
  [_window makeKeyAndOrderFront:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender 
{
    return YES;
}

- (void)applicationWillTerminate:(NSNotification*)notification 
{
}
@end

int main(int argc, const char * argv[]) 
{
  @autoreleasepool {
    [NSApplication sharedApplication];
    
    AppDelegate* appDelegate = [[AppDelegate alloc] init];
    [NSApp setDelegate:appDelegate];
    
    [NSApp run];
  }
  return 0;
}
