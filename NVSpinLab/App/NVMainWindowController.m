#import "NVMainWindowController.h"
#import "NVWorkspaceViewController.h"

@implementation NVMainWindowController

- (instancetype)init {
    NSRect frame = NSMakeRect(0, 0, 1320, 860);
    NSWindowStyleMask style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                              NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable |
                              NSWindowStyleMaskFullSizeContentView;
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                   styleMask:style
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    window.title = @"NV Spin Lab";
    window.titleVisibility = NSWindowTitleHidden;
    window.titlebarAppearsTransparent = YES;
    window.movableByWindowBackground = NO;
    window.minSize = NSMakeSize(1120, 720);
    window.backgroundColor = [NSColor colorWithSRGBRed:0.030 green:0.042 blue:0.060 alpha:1.0];
    window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
    window.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;
    window.restorable = NO;
    window.contentViewController = [[NVWorkspaceViewController alloc] init];
    self = [super initWithWindow:window];
    if (self) {
        [window center];
    }
    return self;
}

@end
