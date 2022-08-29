#import <Foundation/Foundation.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

#include <memory>

#include "ShaderTypes.h"
#include "Renderer.h"

@interface MTKViewDelegate: NSObject<MTKViewDelegate>
-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;
@end

@implementation MTKViewDelegate
{
  std::unique_ptr<Renderer> _renderer;
}

-(nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)view;
{
  self = [super init];
  if (self)
  {
    _renderer = std::make_unique<Renderer>(view);
  }
  return self;
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
  _renderer->UpdateViewport(size.width, size.height);
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
  _renderer->Render(view);
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
