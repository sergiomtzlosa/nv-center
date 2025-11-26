#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface NVWorkspaceViewController : NSViewController
- (void)exportCSV:(nullable id)sender;
- (void)exportJSON:(nullable id)sender;
- (void)exportPNG:(nullable id)sender;
- (void)exportPDF:(nullable id)sender;
- (void)saveSession:(nullable id)sender;
- (void)openSession:(nullable id)sender;
- (void)addToNotebook:(nullable id)sender;
- (void)showNotebook:(nullable id)sender;
- (void)saveNotebook:(nullable id)sender;
- (void)toggleGuidedMode:(nullable id)sender;
- (void)toggleIdealProfile:(nullable id)sender;
- (void)showHowToUse:(nullable id)sender;
- (void)setGuidedMode:(BOOL)guided;
- (void)debugWriteExportsToDirectory:(NSString *)directory;
- (BOOL)loadSessionFromURL:(NSURL *)url error:(NSError **)error;
- (void)selectExperimentAtIndex:(NSInteger)index tab:(NSInteger)tab;
- (void)selectTabAtIndex:(NSInteger)tab;
- (nullable NSImage *)threeDSnapshot;
@end

NS_ASSUME_NONNULL_END
