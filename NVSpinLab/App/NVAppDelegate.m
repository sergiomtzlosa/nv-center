#import "NVAppDelegate.h"
#import "NVWorkspaceViewController.h"

@implementation NVAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [self buildMenu];
    self.mainWindowController = [[NVMainWindowController alloc] init];
    [self.mainWindowController showWindow:nil];
    [self targetWorkspaceMenuItems];
    [NSApp activateIgnoringOtherApps:YES];

#if DEBUG
    NSDictionary *env = NSProcessInfo.processInfo.environment;
    NSString *snapshotPath = env[@"NV_SNAPSHOT_PATH"];
    NVWorkspaceViewController *debugWorkspace = (NVWorkspaceViewController *)self.mainWindowController.window.contentViewController;
    if (env[@"NV_SNAPSHOT_EXPERIMENT"]) {
        NSInteger experiment = [env[@"NV_SNAPSHOT_EXPERIMENT"] integerValue];
        [debugWorkspace selectExperimentAtIndex:experiment tab:-1];
    }
    NSString *loadSession = env[@"NV_LOAD_SESSION"];
    if (loadSession.length > 0) {
        NSError *error = nil;
        if (![debugWorkspace loadSessionFromURL:[NSURL fileURLWithPath:loadSession] error:&error]) {
            NSLog(@"Could not load debug session: %@", error);
        }
    }
    if (env[@"NV_SNAPSHOT_TAB"]) {
        [debugWorkspace selectTabAtIndex:[env[@"NV_SNAPSHOT_TAB"] integerValue]];
    }
    if (env[@"NV_GUIDED"]) {
        NVWorkspaceViewController *workspace = (NVWorkspaceViewController *)self.mainWindowController.window.contentViewController;
        [workspace setGuidedMode:[env[@"NV_GUIDED"] boolValue]];
    }
    if (env[@"NV_NOTEBOOK_TEST"]) {
        NVWorkspaceViewController *workspace = (NVWorkspaceViewController *)self.mainWindowController.window.contentViewController;
        [workspace addToNotebook:nil];
        [workspace showNotebook:nil];
    }
    NSString *notebookPath = env[@"NV_NOTEBOOK_PATH"];
    if (notebookPath.length > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            for (NSWindow *window in NSApp.windows) {
                if ([window.title hasPrefix:@"Lab Notebook"]) {
                    NSView *view = window.contentView;
                    NSBitmapImageRep *rep = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
                    [view cacheDisplayInRect:view.bounds toBitmapImageRep:rep];
                    NSData *png = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
                    [png writeToFile:notebookPath atomically:YES];
                    break;
                }
            }
            [NSApp terminate:nil];
        });
    }
    NSString *exportDirectory = env[@"NV_EXPORT_DIR"];
    if (exportDirectory.length > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NVWorkspaceViewController *workspace = (NVWorkspaceViewController *)self.mainWindowController.window.contentViewController;
            [workspace debugWriteExportsToDirectory:exportDirectory];
            [NSApp terminate:nil];
        });
    }
    NSString *threeDPath = env[@"NV_SNAPSHOT_3D_PATH"];
    if (threeDPath.length > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NVWorkspaceViewController *workspace = (NVWorkspaceViewController *)self.mainWindowController.window.contentViewController;
            NSImage *image = [workspace threeDSnapshot];
            NSData *tiff = image.TIFFRepresentation;
            NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:tiff];
            NSData *png = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
            [png writeToFile:threeDPath atomically:YES];
            [NSApp terminate:nil];
        });
    }
    if (snapshotPath.length > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSWindow *window = self.mainWindowController.window;
            NSView *view = window.contentView;
            NSBitmapImageRep *rep = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
            [view cacheDisplayInRect:view.bounds toBitmapImageRep:rep];
            NSData *png = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
            [png writeToFile:snapshotPath atomically:YES];
            [NSApp terminate:nil];
        });
    }
#endif
}

- (void)targetMenu:(NSMenu *)menu workspace:(NVWorkspaceViewController *)workspace {
    NSSet<NSString *> *actions = [NSSet setWithObjects:
        @"openSession:", @"saveSession:", @"exportCSV:", @"exportJSON:", @"exportPNG:", @"exportPDF:",
        @"addToNotebook:", @"showNotebook:", @"toggleGuidedMode:", @"toggleIdealProfile:", @"showHowToUse:", nil];
    for (NSMenuItem *item in menu.itemArray) {
        if (item.action && [actions containsObject:NSStringFromSelector(item.action)]) {
            item.target = workspace;
        }
        if (item.submenu) [self targetMenu:item.submenu workspace:workspace];
    }
}

- (void)targetWorkspaceMenuItems {
    NVWorkspaceViewController *workspace = (NVWorkspaceViewController *)self.mainWindowController.window.contentViewController;
    if (workspace && NSApp.mainMenu) [self targetMenu:NSApp.mainMenu workspace:workspace];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (void)buildMenu {
    NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@"Main Menu"];

    NSMenuItem *appItem = [[NSMenuItem alloc] initWithTitle:@"NV Spin Lab" action:nil keyEquivalent:@""];
    [mainMenu addItem:appItem];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"NV Spin Lab"];
    appItem.submenu = appMenu;

    NSMenuItem *about = [appMenu addItemWithTitle:@"About NV Spin Lab" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    about.target = NSApp;
    [appMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *hide = [appMenu addItemWithTitle:@"Hide NV Spin Lab" action:@selector(hide:) keyEquivalent:@"h"];
    hide.target = NSApp;
    NSMenuItem *hideOthers = [appMenu addItemWithTitle:@"Hide Others" action:@selector(hideOtherApplications:) keyEquivalent:@"h"];
    hideOthers.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagOption;
    hideOthers.target = NSApp;
    NSMenuItem *showAll = [appMenu addItemWithTitle:@"Show All" action:@selector(unhideAllApplications:) keyEquivalent:@""];
    showAll.target = NSApp;
    [appMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *quit = [appMenu addItemWithTitle:@"Quit NV Spin Lab" action:@selector(terminate:) keyEquivalent:@"q"];
    quit.target = NSApp;

    NSMenuItem *fileItem = [[NSMenuItem alloc] initWithTitle:@"File" action:nil keyEquivalent:@""];
    [mainMenu addItem:fileItem];
    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
    fileItem.submenu = fileMenu;
    NSMenuItem *openSession = [fileMenu addItemWithTitle:@"Open Session…" action:@selector(openSession:) keyEquivalent:@"o"];
    openSession.target = nil;
    NSMenuItem *saveSession = [fileMenu addItemWithTitle:@"Save Session…" action:@selector(saveSession:) keyEquivalent:@"s"];
    saveSession.target = nil;
    [fileMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *exportCSV = [fileMenu addItemWithTitle:@"Export CSV…" action:@selector(exportCSV:) keyEquivalent:@"e"];
    exportCSV.target = nil;
    NSMenuItem *exportJSON = [fileMenu addItemWithTitle:@"Export JSON…" action:@selector(exportJSON:) keyEquivalent:@""];
    exportJSON.target = nil;
    NSMenuItem *exportPNG = [fileMenu addItemWithTitle:@"Export PNG Report…" action:@selector(exportPNG:) keyEquivalent:@""];
    exportPNG.target = nil;
    NSMenuItem *exportPDF = [fileMenu addItemWithTitle:@"Export PDF Report…" action:@selector(exportPDF:) keyEquivalent:@""];
    exportPDF.target = nil;
    [fileMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *addNotebook = [fileMenu addItemWithTitle:@"Add Result to Notebook" action:@selector(addToNotebook:) keyEquivalent:@""];
    addNotebook.target = nil;
    NSMenuItem *showNotebook = [fileMenu addItemWithTitle:@"Show Notebook…" action:@selector(showNotebook:) keyEquivalent:@"n"];
    showNotebook.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagShift;
    showNotebook.target = nil;
    [fileMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *close = [fileMenu addItemWithTitle:@"Close Window" action:@selector(performClose:) keyEquivalent:@"w"];
    close.target = nil;

    NSMenuItem *simulationItem = [[NSMenuItem alloc] initWithTitle:@"Simulation" action:nil keyEquivalent:@""];
    [mainMenu addItem:simulationItem];
    NSMenu *simulationMenu = [[NSMenu alloc] initWithTitle:@"Simulation"];
    simulationItem.submenu = simulationMenu;
    NSMenuItem *guidedMenu = [simulationMenu addItemWithTitle:@"Guided Mode" action:@selector(toggleGuidedMode:) keyEquivalent:@"g"];
    guidedMenu.target = nil;
    NSMenuItem *idealMenu = [simulationMenu addItemWithTitle:@"Ideal Instrument Profile" action:@selector(toggleIdealProfile:) keyEquivalent:@"i"];
    idealMenu.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagShift;
    idealMenu.target = nil;

    NSMenuItem *viewItem = [[NSMenuItem alloc] initWithTitle:@"View" action:nil keyEquivalent:@""];
    [mainMenu addItem:viewItem];
    NSMenu *viewMenu = [[NSMenu alloc] initWithTitle:@"View"];
    viewItem.submenu = viewMenu;
    NSMenuItem *fullScreen = [viewMenu addItemWithTitle:@"Enter Full Screen" action:@selector(toggleFullScreen:) keyEquivalent:@"f"];
    fullScreen.keyEquivalentModifierMask = NSEventModifierFlagControl | NSEventModifierFlagCommand;
    fullScreen.target = nil;

    NSMenuItem *windowItem = [[NSMenuItem alloc] initWithTitle:@"Window" action:nil keyEquivalent:@""];
    [mainMenu addItem:windowItem];
    NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"Window"];
    windowItem.submenu = windowMenu;
    NSMenuItem *minimize = [windowMenu addItemWithTitle:@"Minimize" action:@selector(performMiniaturize:) keyEquivalent:@"m"];
    minimize.target = nil;
    NSMenuItem *zoom = [windowMenu addItemWithTitle:@"Zoom" action:@selector(performZoom:) keyEquivalent:@""];
    zoom.target = nil;
    [NSApp setWindowsMenu:windowMenu];

    NSMenuItem *helpItem = [[NSMenuItem alloc] initWithTitle:@"Help" action:nil keyEquivalent:@""];
    [mainMenu addItem:helpItem];
    NSMenu *helpMenu = [[NSMenu alloc] initWithTitle:@"Help"];
    helpItem.submenu = helpMenu;
    NSMenuItem *howTo = [helpMenu addItemWithTitle:@"How to Use NV Spin Lab"
                                            action:@selector(showHowToUse:)
                                     keyEquivalent:@"?"];
    howTo.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagShift;
    howTo.target = nil;
    [NSApp setHelpMenu:helpMenu];

    [NSApp setMainMenu:mainMenu];
}
@end
