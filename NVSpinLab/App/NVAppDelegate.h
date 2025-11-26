#import <Cocoa/Cocoa.h>
#import "NVMainWindowController.h"

NS_ASSUME_NONNULL_BEGIN

@interface NVAppDelegate : NSObject <NSApplicationDelegate>
@property (nonatomic, strong) NVMainWindowController *mainWindowController;
@end

NS_ASSUME_NONNULL_END
