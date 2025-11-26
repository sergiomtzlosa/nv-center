#import "NVWorkspaceViewController.h"
#import "NVViews.h"
#import "NVModels.h"
#import "NVPhysics.h"
#import <QuartzCore/QuartzCore.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

static NSColor *PanelColor(void) { return [NSColor colorWithSRGBRed:0.060 green:0.078 blue:0.105 alpha:1.0]; }
static NSColor *SidebarColor(void) { return [NSColor colorWithSRGBRed:0.040 green:0.052 blue:0.072 alpha:1.0]; }
static NSColor *AccentColor(void) { return [NSColor colorWithSRGBRed:0.37 green:0.72 blue:1.0 alpha:1.0]; }
static NSColor *TextColor(void) { return [NSColor colorWithSRGBRed:0.91 green:0.94 blue:0.98 alpha:1.0]; }
static NSColor *SecondaryColor(void) { return [NSColor colorWithSRGBRed:0.56 green:0.63 blue:0.73 alpha:1.0]; }

static NSString *NVSessionKeyForExperimentKind(NVExperimentKind kind) {
    switch (kind) {
        case NVExperimentKindODMR: return @"odmr";
        case NVExperimentKindRabi: return @"rabi";
        case NVExperimentKindRamsey: return @"ramsey";
        case NVExperimentKindEcho: return @"echo";
        case NVExperimentKindCPMG: return @"cpmg";
        case NVExperimentKindQubit: return @"qubit";
        case NVExperimentKindRelaxation: return @"relaxation";
        case NVExperimentKindAlignment: return @"alignment";
        case NVExperimentKindExplorer: return @"explorer";
    }
    return @"unknown";
}

static NSString *NVHowToUseText(void) {
    return @"NV SPIN LAB — HOW TO USE\n"
           @"\n"
           @"NV Spin Lab is a simulation. It does not connect to, discover, configure,\n"
           @"or control physical instruments, and it performs no hardware I/O.\n"
           @"\n"
           @"1. CHOOSE AN EXPERIMENT\n"
           @"   Select one of the nine experiments in the left navigator. The app runs\n"
           @"   that experiment immediately with its default parameters.\n"
           @"\n"
           @"2. CHANGE PARAMETERS\n"
           @"   Use the sliders and pop-up menus in the PARAMETERS panel. Every experiment\n"
           @"   redraws as you move a control: the signal, levels, sequence, 3D model,\n"
           @"   Bloch sphere, readout histogram and hardware view all follow the current\n"
           @"   parameters. There is no separate run step.\n"
           @"\n"
           @"   Guided mode is the default: it shows a short walkthrough and hides advanced\n"
           @"   controls. Advanced mode exposes detuning, pulse errors, noise and readout\n"
           @"   settings. Switch modes at the bottom of the sidebar or with Command-G.\n"
           @"\n"
           @"3. READ THE TABS\n"
           @"   Signal     measured or simulated signal versus the swept variable\n"
           @"   Levels     spin energy levels, splitting and avoided crossings\n"
           @"   Sequence   laser, microwave and readout pulse timeline\n"
           @"   3D         interactive NV-center model\n"
           @"   Bloch      qubit state on the Bloch sphere\n"
           @"   Readout    single-shot counts and readout fidelity\n"
           @"   Noise      CPMG filter function and noise response\n"
           @"   T1 / T2    relaxation and coherence decays\n"
           @"   Hardware   simulated optical and electronic reference chain\n"
           @"\n"
           @"4. EXPERIMENT NOTES\n"
           @"   ODMR & Zeeman   Change field, angle or strain live; raise B to split the dips.\n"
           @"                   Ensemble mode shows all four ⟨111⟩ axes on Levels.\n"
           @"                   Enable ¹⁴N hyperfine and read the zoomed triplet inset.\n"
           @"   Rabi            Keep the drive resonant and vary pulse length.\n"
           @"                   The first maximum is a π pulse. Add detuning to see the\n"
           @"                   faster generalized Rabi oscillation.\n"
           @"   Ramsey          π/2 – τ – π/2. The fringe period is set by detuning;\n"
           @"                   T₂* controls the envelope decay.\n"
           @"   Spin Echo       π/2 – τ₁ – π – τ₂ – π/2. Symmetric echo refocuses\n"
           @"                   inhomogeneous dephasing; asymmetric echo only refocuses\n"
           @"                   near τ₁ = τ₂.\n"
           @"   CPMG            Add π pulses to filter noise. The filter peaks near\n"
           @"                   1/(2τ); tune the AC tone to see resonant coherence loss.\n"
           @"   Qubit Lab       Initialize, apply X/Y/Z/H/rotation gates, inspect the\n"
           @"                   Bloch vector, then compare shot-noise counts with theory.\n"
           @"   Relaxation      Measure T₁ recovery and T₂*/T₂ decay. The model enforces\n"
           @"                   the physical constraint T₂ ≤ 2T₁.\n"
           @"   System Alignment Explore a simulated beam path, focus and microwave\n"
           @"                   coupling. No hardware is connected or controlled.\n"
           @"   NV Center 3D    Orbit the lattice, identify N and the vacancy, and rotate\n"
           @"                   the magnetic-field vector with θ and φ.\n"
           @"\n"
           @"5. REFERENCE VS IDEAL PROFILE\n"
           @"   Reference includes detector noise, finite contrast, pulse errors and readout\n"
           @"   misclassification. Ideal suppresses those non-idealities but keeps material\n"
           @"   T₁/T₂ times physical. Toggle with Simulation > Ideal Instrument Profile\n"
           @"   (Command-Shift-I).\n"
           @"\n"
           @"6. RECORD, EXPORT AND RESUME\n"
           @"   Export > Add to notebook records the current result and parameters.\n"
           @"   Export CSV or JSON for data; export a PNG or PDF report for a write-up.\n"
           @"   Save Session (Command-S) stores every experiment's parameters, the\n"
           @"   current tab, guided/advanced mode, instrument profile and notebook in a\n"
           @"   .nvlab file; Open Session (Command-O) restores the full workspace.\n"
           @"\n"
           @"7. 3D VIEW\n"
           @"   Drag to orbit, scroll to zoom, and wait for the slow auto-rotation. The field\n"
           @"   vector remains fixed in the laboratory frame while the lattice rotates.\n"
           @"\n"
           @"8. IF SOMETHING DOES NOT UPDATE\n"
           @"   Every experiment updates while you move a control. Check the status line at\n"
           @"   the bottom of the window. Switching experiments always runs a fresh\n"
           @"   simulation with that experiment's defaults.\n";
}

@interface NVFlippedView : NSView
@end
@implementation NVFlippedView
- (BOOL)isFlipped { return YES; }
@end

@interface NVReportView : NSView
@property (nonatomic, copy) NSString *experimentTitle;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSArray<NSString *> *parameterLines;
@property (nonatomic, strong, nullable) NSImage *visualization;
@property (nonatomic, copy) NSString *footer;
@end

@implementation NVReportView
- (BOOL)isFlipped { return YES; }

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;

    [[NSColor colorWithSRGBRed:0.965 green:0.972 blue:0.980 alpha:1.0] setFill];
    NSRectFill(self.bounds);

    NSRect header = NSMakeRect(0, 0, W, 76);
    [[NSColor colorWithSRGBRed:0.045 green:0.060 blue:0.082 alpha:1.0] setFill];
    NSRectFill(header);
    [[NSColor colorWithSRGBRed:0.37 green:0.72 blue:1.0 alpha:1.0] setFill];
    NSRectFill(NSMakeRect(0, 74, W, 2));

    NSDictionary *brandAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:15 weight:NSFontWeightBold],
                                 NSForegroundColorAttributeName: [NSColor whiteColor]};
    NSDictionary *smallCaps = @{NSFontAttributeName: [NSFont systemFontOfSize:9 weight:NSFontWeightSemibold],
                                NSForegroundColorAttributeName: [NSColor colorWithSRGBRed:0.58 green:0.68 blue:0.82 alpha:1.0]};
    [@"NV SPIN LAB" drawAtPoint:NSMakePoint(44, 22) withAttributes:brandAttrs];
    [@"EXPERIMENT REPORT" drawAtPoint:NSMakePoint(44, 43) withAttributes:smallCaps];
    NSString *dateText = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                       dateStyle:NSDateFormatterMediumStyle
                                                       timeStyle:NSDateFormatterShortStyle];
    NSDictionary *rightAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:9.5],
                                 NSForegroundColorAttributeName: [NSColor colorWithSRGBRed:0.75 green:0.81 blue:0.90 alpha:1.0]};
    NSSize dateSize = [dateText sizeWithAttributes:rightAttrs];
    [dateText drawAtPoint:NSMakePoint(W - 44 - dateSize.width, 29) withAttributes:rightAttrs];

    NSDictionary *titleAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:23 weight:NSFontWeightBold],
                                 NSForegroundColorAttributeName: [NSColor colorWithSRGBRed:0.07 green:0.09 blue:0.13 alpha:1.0]};
    [self.experimentTitle drawAtPoint:NSMakePoint(44, 98) withAttributes:titleAttrs];

    [[NSColor colorWithSRGBRed:0.82 green:0.86 blue:0.91 alpha:1.0] setFill];
    NSRectFill(NSMakeRect(44, 138, W - 88, 1));

    NSDictionary *sectionAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:9 weight:NSFontWeightSemibold],
                                   NSForegroundColorAttributeName: [NSColor colorWithSRGBRed:0.22 green:0.46 blue:0.72 alpha:1.0]};
    [@"PARAMETERS" drawAtPoint:NSMakePoint(44, 154) withAttributes:sectionAttrs];
    NSDictionary *paramAttrs = @{NSFontAttributeName: [NSFont monospacedSystemFontOfSize:9.5 weight:NSFontWeightRegular],
                                 NSForegroundColorAttributeName: [NSColor colorWithSRGBRed:0.18 green:0.21 blue:0.26 alpha:1.0]};
    NSUInteger count = self.parameterLines.count;
    NSUInteger rows = (count + 1) / 2;
    for (NSUInteger i = 0; i < count; i++) {
        NSUInteger col = i / MAX((NSUInteger)1, rows);
        NSUInteger row = i % MAX((NSUInteger)1, rows);
        NSString *line = self.parameterLines[i];
        [line drawAtPoint:NSMakePoint(44 + col * 266, 174 + row * 17) withAttributes:paramAttrs];
    }

    CGFloat chartTop = 174 + rows * 17 + 18;

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 2.2;
    NSDictionary *summaryAttrs = @{NSFontAttributeName: [NSFont monospacedSystemFontOfSize:9.3 weight:NSFontWeightRegular],
                                   NSForegroundColorAttributeName: [NSColor colorWithSRGBRed:0.16 green:0.19 blue:0.24 alpha:1.0],
                                   NSParagraphStyleAttributeName: style};
    NSRect measurement = [self.summary boundingRectWithSize:NSMakeSize(W - 88, CGFLOAT_MAX)
                                                   options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading)
                                                attributes:summaryAttrs];
    CGFloat summaryHeight = ceil(measurement.size.height);
    CGFloat maxChartHeight = H - (chartTop + 22 + 18 + 58) - summaryHeight;
    CGFloat chartHeight = MIN(248.0, MAX(150.0, maxChartHeight));
    NSRect chartRect = NSMakeRect(44, chartTop, W - 88, chartHeight);
    NSBezierPath *chartPath = [NSBezierPath bezierPathWithRoundedRect:chartRect xRadius:9 yRadius:9];
    [[NSColor colorWithSRGBRed:0.045 green:0.060 blue:0.082 alpha:1.0] setFill];
    [chartPath fill];
    [@"LIVE VISUALIZATION" drawAtPoint:NSMakePoint(58, chartTop + 12) withAttributes:sectionAttrs];

    if (self.visualization) {
        NSRect imageRect = NSInsetRect(chartRect, 16, 30);
        NSSize size = self.visualization.size;
        if (size.width > 1 && size.height > 1) {
            double scale = MIN(imageRect.size.width / size.width, imageRect.size.height / size.height);
            NSSize drawSize = NSMakeSize(size.width * scale, size.height * scale);
            NSRect drawRect = NSMakeRect(NSMidX(imageRect) - drawSize.width / 2.0,
                                         NSMidY(imageRect) - drawSize.height / 2.0,
                                         drawSize.width, drawSize.height);
            [self.visualization drawInRect:drawRect fromRect:NSZeroRect
                                 operation:NSCompositingOperationSourceOver fraction:1.0
                            respectFlipped:YES hints:nil];
        }
    } else {
        NSDictionary *emptyAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:11],
                                     NSForegroundColorAttributeName: [NSColor colorWithWhite:1 alpha:0.45]};
        [@"Visualization unavailable" drawAtPoint:NSMakePoint(58, chartTop + 55) withAttributes:emptyAttrs];
    }

    CGFloat summaryTop = chartTop + chartHeight + 22;
    [@"RESULTS & INTERPRETATION" drawAtPoint:NSMakePoint(44, summaryTop) withAttributes:sectionAttrs];
    NSRect summaryRect = NSMakeRect(44, summaryTop + 18, W - 88, MAX(0, H - summaryTop - 58));
    [self.summary drawInRect:summaryRect withAttributes:summaryAttrs];

    [[NSColor colorWithSRGBRed:0.82 green:0.86 blue:0.91 alpha:1.0] setFill];
    NSRectFill(NSMakeRect(44, H - 40, W - 88, 1));
    NSDictionary *footerAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:8.5],
                                  NSForegroundColorAttributeName: [NSColor colorWithSRGBRed:0.42 green:0.47 blue:0.54 alpha:1.0]};
    [self.footer drawAtPoint:NSMakePoint(44, H - 30) withAttributes:footerAttrs];
}
@end

@interface NVWorkspaceViewController () <NSTableViewDataSource, NSTableViewDelegate, NSMenuItemValidation>
@property (nonatomic, strong) NSArray<NVExperiment *> *experiments;
@property (nonatomic, strong) NSTableView *sidebarTable;
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSTextField *subtitleLabel;
@property (nonatomic, strong) NSTextField *statusLabel;
@property (nonatomic, strong) NSSegmentedControl *tabControl;
@property (nonatomic, strong) NSView *contentHost;
@property (nonatomic, strong) NSScrollView *parameterScroll;
@property (nonatomic, strong) NVFlippedView *parameterDoc;
@property (nonatomic, strong) NSMutableArray<NVParameterControl *> *controls;
@property (nonatomic, strong) NVPlotView *plotView;
@property (nonatomic, strong) NVSequenceView *sequenceView;
@property (nonatomic, strong) NVBlochSphereView *blochView;
@property (nonatomic, strong) NVHistogramView *histogramView;
@property (nonatomic, strong) NV3DView *threeDView;
@property (nonatomic, strong) NSTextField *threeDHint;
@property (nonatomic, strong) NSScrollView *resultsScroll;
@property (nonatomic, strong) NSTextView *resultsTextView;
@property (nonatomic, strong) NSScrollView *hardwareScroll;
@property (nonatomic, strong) NSTextView *hardwareTextView;
@property (nonatomic, strong) NVExperiment *currentExperiment;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *values;
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableDictionary<NSString *, NSNumber *> *> *experimentValues;
@property (nonatomic, strong) NVSimulationResult *result;
@property (nonatomic) NSInteger currentTab;
@property (nonatomic, strong) NSSegmentedControl *modeControl;
@property (nonatomic, strong) NSPopUpButton *exportButton;
@property (nonatomic) BOOL guidedModeActive;
@property (nonatomic) BOOL idealProfile;
@property (nonatomic, strong) NSTextField *profileLabel;
@property (nonatomic, strong) NSMutableArray<NSDictionary *> *notebook;
@property (nonatomic, strong) NSPanel *notebookPanel;
@property (nonatomic, strong) NSTextView *notebookTextView;
@property (nonatomic, strong) NSPanel *helpPanel;
@property (nonatomic, strong) NSTextView *helpTextView;
@property (nonatomic, strong, nullable) NSTimer *liveUpdateTimer;
@property (nonatomic) BOOL liveUpdatePending;
@property (nonatomic) BOOL liveUpdateActive;
- (NSString *)csvTextForSeries:(NSArray<NVSeries *> *)series;
@end

@implementation NVWorkspaceViewController

- (instancetype)init {
    self = [super initWithNibName:nil bundle:nil];
    return self;
}

- (void)dealloc {
    [_liveUpdateTimer invalidate];
}

- (void)viewDidDisappear {
    [super viewDidDisappear];
    [self.liveUpdateTimer invalidate];
    self.liveUpdateTimer = nil;
    self.liveUpdatePending = NO;
}

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 1320, 860)];
    self.view.wantsLayer = YES;
    self.view.layer.backgroundColor = [NSColor colorWithSRGBRed:0.030 green:0.042 blue:0.060 alpha:1.0].CGColor;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.experiments = [NVExperiment allExperiments];
    self.values = [NSMutableDictionary dictionary];
    self.experimentValues = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < (NSInteger)self.experiments.count; i++) {
        NVExperiment *experiment = self.experiments[i];
        NSMutableDictionary<NSString *, NSNumber *> *stored = [NSMutableDictionary dictionary];
        for (NVParameter *parameter in experiment.parameters) {
            stored[parameter.key] = @(parameter.kind == NVParameterKindChoice ? (double)parameter.selectedIndex : parameter.value);
        }
        self.experimentValues[@(i)] = stored;
    }
    self.controls = [NSMutableArray array];
    self.guidedModeActive = YES;
    self.idealProfile = NO;
    self.notebook = [NSMutableArray array];
    [self buildInterface];
    if (self.experiments.count > 0) {
        self.sidebarTable.delegate = nil;
        [self.sidebarTable selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        self.sidebarTable.delegate = self;
        [self activateExperiment:self.experiments[0]];
    }
}

- (NSTextField *)label:(NSString *)text font:(NSFont *)font color:(NSColor *)color {
    NSTextField *l = [NSTextField labelWithString:text];
    l.font = font;
    l.textColor = color;
    l.translatesAutoresizingMaskIntoConstraints = NO;
    return l;
}

- (void)buildInterface {
    NSView *root = self.view;

    // Sidebar
    NSView *sidebar = [[NSView alloc] initWithFrame:NSZeroRect];
    sidebar.translatesAutoresizingMaskIntoConstraints = NO;
    sidebar.wantsLayer = YES;
    sidebar.layer.backgroundColor = SidebarColor().CGColor;
    [root addSubview:sidebar];

    NSTextField *brand = [self label:@"NV SPIN LAB" font:[NSFont systemFontOfSize:17 weight:NSFontWeightBold] color:TextColor()];
    [sidebar addSubview:brand];
    NSTextField *tagline = [self label:@"Quantum sensing simulator" font:[NSFont systemFontOfSize:10] color:SecondaryColor()];
    [sidebar addSubview:tagline];

    self.sidebarTable = [[NSTableView alloc] initWithFrame:NSZeroRect];
    self.sidebarTable.translatesAutoresizingMaskIntoConstraints = NO;
    self.sidebarTable.headerView = nil;
    self.sidebarTable.rowHeight = 40;
    self.sidebarTable.backgroundColor = [NSColor clearColor];
    self.sidebarTable.intercellSpacing = NSMakeSize(0, 2);
    self.sidebarTable.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;
    self.sidebarTable.focusRingType = NSFocusRingTypeNone;
    NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:@"experiment"];
    col.width = 210;
    [self.sidebarTable addTableColumn:col];
    self.sidebarTable.dataSource = self;
    self.sidebarTable.delegate = self;

    NSScrollView *sidebarScroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    sidebarScroll.translatesAutoresizingMaskIntoConstraints = NO;
    sidebarScroll.documentView = self.sidebarTable;
    sidebarScroll.hasVerticalScroller = NO;
    sidebarScroll.drawsBackground = NO;
    sidebarScroll.borderType = NSNoBorder;
    [sidebar addSubview:sidebarScroll];

    NSTextField *mode = [self label:@"SIMULATION MODE" font:[NSFont systemFontOfSize:9 weight:NSFontWeightSemibold] color:AccentColor()];
    [sidebar addSubview:mode];
    NSTextField *offline = [self label:@"Simulation only · no I/O" font:[NSFont systemFontOfSize:10] color:SecondaryColor()];
    [sidebar addSubview:offline];

    self.modeControl = [NSSegmentedControl segmentedControlWithLabels:@[@"Guided", @"Advanced"]
                                                        trackingMode:NSSegmentSwitchTrackingSelectOne
                                                              target:self
                                                              action:@selector(modeChanged:)];
    self.modeControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.modeControl.segmentStyle = NSSegmentStyleRounded;
    self.modeControl.controlSize = NSControlSizeSmall;
    self.modeControl.font = [NSFont systemFontOfSize:10.5 weight:NSFontWeightMedium];
    self.modeControl.selectedSegment = 0;
    [sidebar addSubview:self.modeControl];

    [NSLayoutConstraint activateConstraints:@[
        [sidebar.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [sidebar.topAnchor constraintEqualToAnchor:root.topAnchor],
        [sidebar.bottomAnchor constraintEqualToAnchor:root.bottomAnchor],
        [sidebar.widthAnchor constraintEqualToConstant:232],

        [brand.leadingAnchor constraintEqualToAnchor:sidebar.leadingAnchor constant:20],
        [brand.topAnchor constraintEqualToAnchor:sidebar.topAnchor constant:42],
        [tagline.leadingAnchor constraintEqualToAnchor:brand.leadingAnchor],
        [tagline.topAnchor constraintEqualToAnchor:brand.bottomAnchor constant:3],

        [sidebarScroll.leadingAnchor constraintEqualToAnchor:sidebar.leadingAnchor constant:8],
        [sidebarScroll.trailingAnchor constraintEqualToAnchor:sidebar.trailingAnchor constant:-8],
        [sidebarScroll.topAnchor constraintEqualToAnchor:sidebar.topAnchor constant:104],
        [sidebarScroll.bottomAnchor constraintEqualToAnchor:self.modeControl.topAnchor constant:-12],

        [self.modeControl.leadingAnchor constraintEqualToAnchor:sidebar.leadingAnchor constant:18],
        [self.modeControl.trailingAnchor constraintEqualToAnchor:sidebar.trailingAnchor constant:-18],
        [self.modeControl.bottomAnchor constraintEqualToAnchor:mode.topAnchor constant:-8],
        [self.modeControl.heightAnchor constraintEqualToConstant:24],
        [mode.leadingAnchor constraintEqualToAnchor:sidebar.leadingAnchor constant:20],
        [mode.bottomAnchor constraintEqualToAnchor:offline.topAnchor constant:-3],
        [offline.leadingAnchor constraintEqualToAnchor:mode.leadingAnchor],
        [offline.bottomAnchor constraintEqualToAnchor:sidebar.bottomAnchor constant:-18]
    ]];

    // Main area
    NSView *main = [[NSView alloc] initWithFrame:NSZeroRect];
    main.translatesAutoresizingMaskIntoConstraints = NO;
    [root addSubview:main];

    self.titleLabel = [self label:@"ODMR & Zeeman" font:[NSFont systemFontOfSize:31 weight:NSFontWeightBold] color:TextColor()];
    self.subtitleLabel = [self label:@"" font:[NSFont systemFontOfSize:12] color:SecondaryColor()];
    self.subtitleLabel.maximumNumberOfLines = 2;
    self.subtitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [main addSubview:self.titleLabel];
    [main addSubview:self.subtitleLabel];

    NSButton *notebookButton = [NSButton buttonWithTitle:@"Notebook" target:self action:@selector(showNotebook:)];
    notebookButton.translatesAutoresizingMaskIntoConstraints = NO;
    notebookButton.bezelStyle = NSBezelStyleRounded;
    notebookButton.font = [NSFont systemFontOfSize:11];
    [main addSubview:notebookButton];

    self.exportButton = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:YES];
    self.exportButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.exportButton.bezelStyle = NSBezelStyleRounded;
    self.exportButton.font = [NSFont systemFontOfSize:11];
    [self.exportButton addItemWithTitle:@"Export"];
    [self.exportButton.menu addItem:[NSMenuItem separatorItem]];
    NSArray *exportTitles = @[@"CSV data…", @"JSON data…", @"PNG report…", @"PDF report…",
                              @"", @"Add to notebook", @"Show notebook…", @"Save notebook…"];
    NSInteger tag = 1;
    for (NSString *title in exportTitles) {
        if (title.length == 0) {
            [self.exportButton.menu addItem:[NSMenuItem separatorItem]];
            continue;
        }
        NSMenuItem *item = [self.exportButton.menu addItemWithTitle:title action:@selector(exportMenuChanged:) keyEquivalent:@""];
        item.tag = tag++;
        item.target = self;
    }
    self.exportButton.target = self;
    self.exportButton.action = @selector(exportMenuChanged:);
    [main addSubview:self.exportButton];

    NSView *headerRule = [[NSView alloc] initWithFrame:NSZeroRect];
    headerRule.translatesAutoresizingMaskIntoConstraints = NO;
    headerRule.wantsLayer = YES;
    headerRule.layer.backgroundColor = [NSColor colorWithWhite:1 alpha:0.065].CGColor;
    [main addSubview:headerRule];

    NSView *body = [[NSView alloc] initWithFrame:NSZeroRect];
    body.translatesAutoresizingMaskIntoConstraints = NO;
    [main addSubview:body];

    // Parameter panel
    NSView *paramPanel = [[NSView alloc] initWithFrame:NSZeroRect];
    paramPanel.translatesAutoresizingMaskIntoConstraints = NO;
    paramPanel.wantsLayer = YES;
    paramPanel.layer.backgroundColor = PanelColor().CGColor;
    paramPanel.layer.cornerRadius = 10;
    [body addSubview:paramPanel];

    NSTextField *paramTitle = [self label:@"PARAMETERS" font:[NSFont systemFontOfSize:9 weight:NSFontWeightSemibold] color:AccentColor()];
    [paramPanel addSubview:paramTitle];

    self.parameterScroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    self.parameterScroll.translatesAutoresizingMaskIntoConstraints = NO;
    self.parameterScroll.hasVerticalScroller = YES;
    self.parameterScroll.drawsBackground = NO;
    self.parameterScroll.borderType = NSNoBorder;
    self.parameterDoc = [[NVFlippedView alloc] initWithFrame:NSMakeRect(0, 0, 260, 300)];
    self.parameterScroll.documentView = self.parameterDoc;
    [paramPanel addSubview:self.parameterScroll];

    [NSLayoutConstraint activateConstraints:@[
        [paramPanel.leadingAnchor constraintEqualToAnchor:body.leadingAnchor],
        [paramPanel.topAnchor constraintEqualToAnchor:body.topAnchor],
        [paramPanel.bottomAnchor constraintEqualToAnchor:body.bottomAnchor],
        [paramPanel.widthAnchor constraintEqualToConstant:282],
        [paramTitle.leadingAnchor constraintEqualToAnchor:paramPanel.leadingAnchor constant:18],
        [paramTitle.topAnchor constraintEqualToAnchor:paramPanel.topAnchor constant:16],
        [self.parameterScroll.leadingAnchor constraintEqualToAnchor:paramPanel.leadingAnchor constant:8],
        [self.parameterScroll.trailingAnchor constraintEqualToAnchor:paramPanel.trailingAnchor constant:-8],
        [self.parameterScroll.topAnchor constraintEqualToAnchor:paramTitle.bottomAnchor constant:8],
        [self.parameterScroll.bottomAnchor constraintEqualToAnchor:paramPanel.bottomAnchor constant:-10]
    ]];

    // Content area
    NSView *contentArea = [[NSView alloc] initWithFrame:NSZeroRect];
    contentArea.translatesAutoresizingMaskIntoConstraints = NO;
    [body addSubview:contentArea];

    self.tabControl = [[NSSegmentedControl alloc] initWithFrame:NSZeroRect];
    self.tabControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.tabControl.segmentStyle = NSSegmentStyleRounded;
    self.tabControl.trackingMode = NSSegmentSwitchTrackingSelectOne;
    self.tabControl.target = self;
    self.tabControl.action = @selector(tabChanged:);
    [contentArea addSubview:self.tabControl];

    self.contentHost = [[NSView alloc] initWithFrame:NSZeroRect];
    self.contentHost.translatesAutoresizingMaskIntoConstraints = NO;
    [contentArea addSubview:self.contentHost];

    NSView *resultsPanel = [[NSView alloc] initWithFrame:NSZeroRect];
    resultsPanel.translatesAutoresizingMaskIntoConstraints = NO;
    resultsPanel.wantsLayer = YES;
    resultsPanel.layer.backgroundColor = PanelColor().CGColor;
    resultsPanel.layer.cornerRadius = 10;
    [contentArea addSubview:resultsPanel];

    NSTextField *resultsTitle = [self label:@"RESULTS & INTERPRETATION" font:[NSFont systemFontOfSize:9 weight:NSFontWeightSemibold] color:AccentColor()];
    [resultsPanel addSubview:resultsTitle];

    self.resultsTextView = [self textView];
    self.resultsScroll = [self scrollForTextView:self.resultsTextView];
    [resultsPanel addSubview:self.resultsScroll];

    [NSLayoutConstraint activateConstraints:@[
        [contentArea.leadingAnchor constraintEqualToAnchor:paramPanel.trailingAnchor constant:16],
        [contentArea.trailingAnchor constraintEqualToAnchor:body.trailingAnchor],
        [contentArea.topAnchor constraintEqualToAnchor:body.topAnchor],
        [contentArea.bottomAnchor constraintEqualToAnchor:body.bottomAnchor],

        [self.tabControl.leadingAnchor constraintEqualToAnchor:contentArea.leadingAnchor],
        [self.tabControl.topAnchor constraintEqualToAnchor:contentArea.topAnchor],
        [self.tabControl.heightAnchor constraintEqualToConstant:28],

        [self.contentHost.leadingAnchor constraintEqualToAnchor:contentArea.leadingAnchor],
        [self.contentHost.trailingAnchor constraintEqualToAnchor:contentArea.trailingAnchor],
        [self.contentHost.topAnchor constraintEqualToAnchor:self.tabControl.bottomAnchor constant:10],
        [self.contentHost.bottomAnchor constraintEqualToAnchor:resultsPanel.topAnchor constant:-12],

        [resultsPanel.leadingAnchor constraintEqualToAnchor:contentArea.leadingAnchor],
        [resultsPanel.trailingAnchor constraintEqualToAnchor:contentArea.trailingAnchor],
        [resultsPanel.bottomAnchor constraintEqualToAnchor:contentArea.bottomAnchor],
        [resultsPanel.heightAnchor constraintEqualToConstant:184],
        [resultsTitle.leadingAnchor constraintEqualToAnchor:resultsPanel.leadingAnchor constant:16],
        [resultsTitle.topAnchor constraintEqualToAnchor:resultsPanel.topAnchor constant:12],
        [self.resultsScroll.leadingAnchor constraintEqualToAnchor:resultsPanel.leadingAnchor constant:8],
        [self.resultsScroll.trailingAnchor constraintEqualToAnchor:resultsPanel.trailingAnchor constant:-8],
        [self.resultsScroll.topAnchor constraintEqualToAnchor:resultsTitle.bottomAnchor constant:4],
        [self.resultsScroll.bottomAnchor constraintEqualToAnchor:resultsPanel.bottomAnchor constant:-8]
    ]];

    [NSLayoutConstraint activateConstraints:@[
        [main.leadingAnchor constraintEqualToAnchor:sidebar.trailingAnchor],
        [main.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [main.topAnchor constraintEqualToAnchor:root.topAnchor],
        [main.bottomAnchor constraintEqualToAnchor:root.bottomAnchor],

        [self.titleLabel.leadingAnchor constraintEqualToAnchor:main.leadingAnchor constant:26],
        [self.titleLabel.topAnchor constraintEqualToAnchor:main.topAnchor constant:36],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:notebookButton.leadingAnchor constant:-16],
        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:2],
        [self.subtitleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:notebookButton.leadingAnchor constant:-16],

        [self.exportButton.trailingAnchor constraintEqualToAnchor:main.trailingAnchor constant:-26],
        [self.exportButton.topAnchor constraintEqualToAnchor:main.topAnchor constant:38],
        [self.exportButton.widthAnchor constraintEqualToConstant:92],
        [self.exportButton.heightAnchor constraintEqualToConstant:30],
        [notebookButton.trailingAnchor constraintEqualToAnchor:self.exportButton.leadingAnchor constant:-8],
        [notebookButton.centerYAnchor constraintEqualToAnchor:self.exportButton.centerYAnchor],

        [headerRule.leadingAnchor constraintEqualToAnchor:main.leadingAnchor],
        [headerRule.trailingAnchor constraintEqualToAnchor:main.trailingAnchor],
        [headerRule.topAnchor constraintEqualToAnchor:main.topAnchor constant:94],
        [headerRule.heightAnchor constraintEqualToConstant:1],

        [body.leadingAnchor constraintEqualToAnchor:main.leadingAnchor constant:26],
        [body.trailingAnchor constraintEqualToAnchor:main.trailingAnchor constant:-26],
        [body.topAnchor constraintEqualToAnchor:main.topAnchor constant:108],
        [body.bottomAnchor constraintEqualToAnchor:main.bottomAnchor constant:-20]
    ]];

    [self buildVisualizationViews];

    self.statusLabel = [self label:@"Ready" font:[NSFont systemFontOfSize:10.5] color:SecondaryColor()];
    [main addSubview:self.statusLabel];
    NSView *dot = [[NSView alloc] initWithFrame:NSZeroRect];
    dot.translatesAutoresizingMaskIntoConstraints = NO;
    dot.wantsLayer = YES;
    dot.layer.backgroundColor = [NSColor colorWithSRGBRed:0.42 green:0.86 blue:0.58 alpha:1.0].CGColor;
    dot.layer.cornerRadius = 3.5;
    [main addSubview:dot];
    self.profileLabel = [self label:@"Reference profile · simulated" font:[NSFont systemFontOfSize:10] color:SecondaryColor()];
    [main addSubview:self.profileLabel];
    [NSLayoutConstraint activateConstraints:@[
        [dot.leadingAnchor constraintEqualToAnchor:main.leadingAnchor constant:28],
        [dot.bottomAnchor constraintEqualToAnchor:main.bottomAnchor constant:-6],
        [dot.widthAnchor constraintEqualToConstant:7],
        [dot.heightAnchor constraintEqualToConstant:7],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:dot.trailingAnchor constant:7],
        [self.statusLabel.centerYAnchor constraintEqualToAnchor:dot.centerYAnchor],
        [self.profileLabel.trailingAnchor constraintEqualToAnchor:main.trailingAnchor constant:-28],
        [self.profileLabel.centerYAnchor constraintEqualToAnchor:dot.centerYAnchor]
    ]];
}

- (NSTextView *)textView {
    NSTextView *tv = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 500, 120)];
    tv.editable = NO;
    tv.selectable = YES;
    tv.drawsBackground = NO;
    tv.textColor = [NSColor colorWithSRGBRed:0.78 green:0.84 blue:0.93 alpha:1.0];
    tv.font = [NSFont monospacedSystemFontOfSize:10.8 weight:NSFontWeightRegular];
    tv.textContainerInset = NSMakeSize(10, 6);
    tv.verticallyResizable = YES;
    tv.horizontallyResizable = NO;
    tv.textContainer.widthTracksTextView = YES;
    tv.autoresizingMask = NSViewWidthSizable;
    return tv;
}

- (NSScrollView *)scrollForTextView:(NSTextView *)tv {
    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.hasVerticalScroller = YES;
    scroll.drawsBackground = NO;
    scroll.borderType = NSNoBorder;
    scroll.documentView = tv;
    return scroll;
}

- (void)buildVisualizationViews {
    self.plotView = [[NVPlotView alloc] initWithFrame:NSZeroRect];
    self.plotView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentHost addSubview:self.plotView];

    self.sequenceView = [[NVSequenceView alloc] initWithFrame:NSZeroRect];
    self.sequenceView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentHost addSubview:self.sequenceView];

    self.blochView = [[NVBlochSphereView alloc] initWithFrame:NSZeroRect];
    self.blochView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentHost addSubview:self.blochView];

    self.histogramView = [[NVHistogramView alloc] initWithFrame:NSZeroRect];
    self.histogramView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentHost addSubview:self.histogramView];

    self.threeDView = [[NV3DView alloc] initWithFrame:NSZeroRect];
    self.threeDView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentHost addSubview:self.threeDView];

    self.hardwareTextView = [self textView];
    self.hardwareScroll = [self scrollForTextView:self.hardwareTextView];
    self.hardwareScroll.wantsLayer = YES;
    self.hardwareScroll.layer.backgroundColor = PanelColor().CGColor;
    self.hardwareScroll.layer.cornerRadius = 10;
    [self.contentHost addSubview:self.hardwareScroll];

    for (NSView *v in @[self.plotView, self.sequenceView, self.blochView, self.histogramView, self.threeDView, self.hardwareScroll]) {
        [NSLayoutConstraint activateConstraints:@[
            [v.leadingAnchor constraintEqualToAnchor:self.contentHost.leadingAnchor],
            [v.trailingAnchor constraintEqualToAnchor:self.contentHost.trailingAnchor],
            [v.topAnchor constraintEqualToAnchor:self.contentHost.topAnchor],
            [v.bottomAnchor constraintEqualToAnchor:self.contentHost.bottomAnchor]
        ]];
        v.hidden = YES;
    }

    self.threeDHint = [self label:@"Drag to orbit  ·  scroll to zoom  ·  slow auto-rotate"
                              font:[NSFont systemFontOfSize:10]
                             color:SecondaryColor()];
    self.threeDHint.hidden = YES;
    [self.contentHost addSubview:self.threeDHint];
    [NSLayoutConstraint activateConstraints:@[
        [self.threeDHint.leadingAnchor constraintEqualToAnchor:self.contentHost.leadingAnchor constant:18],
        [self.threeDHint.bottomAnchor constraintEqualToAnchor:self.contentHost.bottomAnchor constant:-12]
    ]];
}

- (NSImage *)threeDSnapshot {
    return [self.threeDView snapshot];
}

- (void)selectExperimentAtIndex:(NSInteger)index tab:(NSInteger)tab {
    if (index < 0 || index >= (NSInteger)self.experiments.count) return;
    self.sidebarTable.delegate = nil;
    [self.sidebarTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    self.sidebarTable.delegate = self;
    [self activateExperiment:self.experiments[index]];
    if (tab >= 0) [self selectTabAtIndex:tab];
}

- (void)selectTabAtIndex:(NSInteger)tab {
    if (tab < 0 || tab >= (NSInteger)self.currentExperiment.tabs.count) return;
    self.tabControl.selectedSegment = tab;
    self.currentTab = tab;
    [self refreshTabContent];
}

- (NSInteger)indexOfCurrentExperiment {
    if (!self.currentExperiment) return NSNotFound;
    return [self.experiments indexOfObject:self.currentExperiment];
}

- (void)storeCurrentValues {
    NSInteger index = [self indexOfCurrentExperiment];
    if (index == NSNotFound) return;
    NSMutableDictionary<NSString *, NSNumber *> *stored = self.experimentValues[@(index)];
    if (!stored) {
        stored = [NSMutableDictionary dictionary];
        self.experimentValues[@(index)] = stored;
    }
    for (NVParameter *parameter in self.currentExperiment.parameters) {
        NSNumber *value = self.values[parameter.key];
        if (![value isKindOfClass:[NSNumber class]]) {
            value = @(parameter.kind == NVParameterKindChoice ? (double)parameter.selectedIndex : parameter.value);
        }
        stored[parameter.key] = value;
    }
}

- (void)activateExperiment:(NVExperiment *)experiment {
    [self storeCurrentValues];
    self.currentExperiment = experiment;
    self.currentTab = 0;
    self.result = nil;
    self.titleLabel.stringValue = experiment.title;
    self.subtitleLabel.stringValue = experiment.subtitle;
    [self.values removeAllObjects];
    NSInteger index = [self.experiments indexOfObject:experiment];
    if (index != NSNotFound) {
        NSDictionary<NSString *, NSNumber *> *stored = self.experimentValues[@(index)];
        if (stored) [self.values addEntriesFromDictionary:stored];
    }
    [self buildParameterControls];
    [self updateTabs];
    [self runSimulation:nil];
    [self resetParameterScrollPosition];
}

- (BOOL)isParameterVisible:(NVParameter *)parameter {
    if (!self.guidedModeActive) return YES;
    NSSet<NSString *> *hidden = nil;
    switch (self.currentExperiment.kind) {
        case NVExperimentKindODMR:
            hidden = [NSSet setWithObjects:@"phi", @"linewidth", nil];
            break;
        case NVExperimentKindRabi:
            hidden = [NSSet setWithObjects:@"t2rabi", @"shots", nil];
            break;
        case NVExperimentKindRamsey:
            hidden = [NSSet setWithObjects:@"phase", @"envelope", nil];
            break;
        case NVExperimentKindEcho:
            hidden = [NSSet setWithObjects:@"pulseError", @"contrast", nil];
            break;
        case NVExperimentKindCPMG:
            hidden = [NSSet setWithObjects:@"alpha", @"acAmp", @"sequence", nil];
            break;
        case NVExperimentKindQubit:
            hidden = [NSSet setWithObjects:@"readoutTime", @"shots", nil];
            break;
        case NVExperimentKindRelaxation:
            hidden = [NSSet setWithObjects:@"maxTime", @"contrast", nil];
            break;
        case NVExperimentKindAlignment:
            hidden = [NSSet setWithObject:@"gain"];
            break;
        case NVExperimentKindExplorer:
            break;
    }
    return ![hidden containsObject:parameter.key];
}

- (void)buildParameterControls {
    for (NVParameterControl *c in self.controls) [c removeFromSuperview];
    [self.controls removeAllObjects];
    for (NVParameter *p in self.currentExperiment.parameters) {
        if (!self.values[p.key]) {
            self.values[p.key] = @(p.kind == NVParameterKindChoice ? (double)p.selectedIndex : p.value);
        }
        if (![self isParameterVisible:p]) continue;
        NVParameterControl *control = [[NVParameterControl alloc] initWithParameter:p];
        control.translatesAutoresizingMaskIntoConstraints = YES;
        [control setCurrentValue:self.values[p.key].doubleValue];
        __weak typeof(self) weakSelf = self;
        control.onChange = ^(double value) {
            weakSelf.values[p.key] = @(value);
            weakSelf.statusLabel.stringValue = @"Parameters changed — updating live…";
            [weakSelf scheduleLiveUpdate];
        };
        [self.parameterDoc addSubview:control];
        [self.controls addObject:control];
    }
    [self layoutParameters];
}

- (void)modeChanged:(NSSegmentedControl *)sender {
    BOOL guided = sender.selectedSegment == 0;
    if (guided == self.guidedModeActive) return;
    self.guidedModeActive = guided;
    [self buildParameterControls];
    [self runSimulation:nil];
}

- (void)toggleGuidedMode:(id)sender {
    [self setGuidedMode:!self.guidedModeActive];
}

- (void)toggleIdealProfile:(id)sender {
    self.idealProfile = !self.idealProfile;
    self.profileLabel.stringValue = self.idealProfile ? @"Ideal profile · simulated" : @"Reference profile · simulated";
    [self runSimulation:nil];
}

- (NSString *)guidedTextForKind:(NVExperimentKind)kind {
    switch (kind) {
        case NVExperimentKindODMR:
            return @"1. Start at a low field and identify the central ODMR dip.\n2. Increase the field and compare the split of the dip with the axial Zeeman slope.\n3. Change the field angle to see the four ⟨111⟩ orientations separate in ensemble mode.";
        case NVExperimentKindRabi:
            return @"1. Keep the drive resonant and vary the pulse length.\n2. Find the first maximum: this is a π pulse.\n3. Add detuning and observe the faster, lower-contrast generalized Rabi oscillation.";
        case NVExperimentKindRamsey:
            return @"1. Set a small detuning and scan the free-evolution time.\n2. Measure the fringe period and compare it with 1/Δ.\n3. Reduce T₂* and watch the Gaussian envelope decay.";
        case NVExperimentKindEcho:
            return @"1. With τ₁ = τ₂, compare the echo decay with the faster Ramsey decay.\n2. Switch to asymmetric mode and break the refocusing condition.\n3. Notice how the slow inhomogeneous dephasing is recovered only at τ₁ = τ₂.";
        case NVExperimentKindCPMG:
            return @"1. Keep the AC tone off and increase the number of π pulses.\n2. The coherence should improve as the noise is filtered.\n3. Tune the AC frequency to the filter maximum and observe the resonant dip.";
        case NVExperimentKindQubit:
            return @"1. Initialize the spin into |0⟩ with the laser pulse.\n2. Apply a gate and inspect the Bloch vector.\n3. Read out many shots and compare the histogram with the expected state.";
        case NVExperimentKindRelaxation:
            return @"1. Measure T₁ by inverting the spin and waiting before readout.\n2. Compare the T₂* Ramsey decay with the T₂ echo decay.\n3. Remember the physical constraint T₂ ≤ 2T₁.";
        case NVExperimentKindAlignment:
            return @"1. Maximize beam overlap and objective focus first.\n2. Adjust the microwave antenna coupling for a strong ODMR contrast.\n3. Keep the laser power and detector gain in the linear range.";
        case NVExperimentKindExplorer:
            return @"1. Orbit the model and identify the substitutional nitrogen and vacancy.\n2. Rotate the field vector with θ and φ.\n3. Switch to the four-axis view to see the crystallographic ⟨111⟩ orientations.";
    }
    return @"";
}

- (void)resetParameterScrollPosition {
    NSClipView *clipView = self.parameterScroll.contentView;
    [clipView scrollToPoint:NSZeroPoint];
    [self.parameterScroll reflectScrolledClipView:clipView];
}

- (void)layoutParameters {
    CGFloat width = self.parameterScroll.contentView.bounds.size.width;
    if (width < 50) width = 264;
    CGFloat y = 12;
    for (NVParameterControl *control in self.controls) {
        control.frame = NSMakeRect(8, y, width - 16, control.intrinsicContentSize.height);
        y += control.intrinsicContentSize.height + 4;
    }
    self.parameterDoc.frame = NSMakeRect(0, 0, width, MAX(y + 12, self.parameterScroll.contentView.bounds.size.height));
}

- (void)viewDidLayout {
    [super viewDidLayout];
    [self layoutParameters];
}

- (void)updateTabs {
    NSArray *tabs = self.currentExperiment.tabs;
    [self.tabControl setSegmentCount:(NSInteger)tabs.count];
    for (NSInteger i = 0; i < (NSInteger)tabs.count; i++) {
        [self.tabControl setLabel:tabs[i] forSegment:i];
    }
    self.tabControl.selectedSegment = 0;
    self.currentTab = 0;
}

- (void)tabChanged:(NSSegmentedControl *)sender {
    self.currentTab = sender.selectedSegment;
    [self refreshTabContent];
}

- (void)runSimulation:(id)sender {
    if (!self.currentExperiment) return;
    [self.liveUpdateTimer invalidate];
    self.liveUpdateTimer = nil;
    self.liveUpdatePending = NO;
    for (NVParameterControl *c in self.controls) {
        self.values[c.parameter.key] = @(c.currentValue);
    }
    NSMutableDictionary *parameters = [self.values mutableCopy];
    parameters[@"ideal"] = @(self.idealProfile ? 1 : 0);
    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
    self.result = NVRunExperiment(self.currentExperiment.kind, parameters);
    double ms = (CFAbsoluteTimeGetCurrent() - start) * 1000.0;
    if (self.idealProfile) {
        self.result.summary = [NSString stringWithFormat:@"%@\n\nINSTRUMENT PROFILE\nIdeal profile: detector noise, pulse errors, and readout misclassification are suppressed. Material T₁/T₂ times remain physical.", self.result.summary ?: @""];
    }
    NSString *reportText = self.result.summary ?: @"";
    if (self.guidedModeActive) {
        reportText = [NSString stringWithFormat:@"GUIDED WALKTHROUGH\n%@\n\nRESULTS\n%@",
                      [self guidedTextForKind:self.currentExperiment.kind], reportText];
    }
    self.resultsTextView.string = reportText;
    [self.resultsTextView scrollRangeToVisible:NSMakeRange(0, 0)];
    self.statusLabel.stringValue = self.liveUpdateActive
        ? [NSString stringWithFormat:@"Live update · %.1f ms · %@ · %@",
                                     ms, self.currentExperiment.title,
                                     self.guidedModeActive ? @"guided" : @"advanced"]
        : [NSString stringWithFormat:@"Simulation complete · %.1f ms · %@ · %@",
                                     ms, self.currentExperiment.title,
                                     self.guidedModeActive ? @"guided" : @"advanced"];
    [self refreshTabContent];
}

#pragma mark - Live updates

- (BOOL)supportsLiveUpdate {
    if (!self.result) return NO;
    NSWindow *window = self.view.window;
    if (window && !window.isVisible) return NO;
    return YES;
}

- (void)scheduleLiveUpdate {
    self.liveUpdatePending = YES;
    if (self.liveUpdateTimer) return;
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.05 target:self selector:@selector(liveUpdateTimerFired:) userInfo:nil repeats:NO];
    self.liveUpdateTimer = timer;
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)liveUpdateTimerFired:(NSTimer *)timer {
    self.liveUpdateTimer = nil;
    if (!self.liveUpdatePending) return;
    self.liveUpdatePending = NO;
    if (![self supportsLiveUpdate]) return;
    self.liveUpdateActive = YES;
    [self runSimulation:nil];
    self.liveUpdateActive = NO;
}

- (void)refreshTabContent {
    NSString *tab = self.currentExperiment.tabs[self.currentTab];
    for (NSView *v in @[self.plotView, self.sequenceView, self.blochView, self.histogramView, self.threeDView, self.hardwareScroll]) v.hidden = YES;
    self.threeDHint.hidden = ![tab isEqualToString:@"3D"];

    BOOL odmrSignal = self.currentExperiment.kind == NVExperimentKindODMR && [tab isEqualToString:@"Signal"];
    if (odmrSignal && self.result.detailSeries.count > 0) {
        [self.plotView setDetailSeries:self.result.detailSeries
                                title:self.result.detailTitle
                               xLabel:self.result.detailXLabel
                               yLabel:self.result.detailYLabel];
    } else {
        [self.plotView setDetailSeries:@[] title:@"" xLabel:@"" yLabel:@""];
    }

    double field = self.values[@"field"] ? self.values[@"field"].doubleValue : 8.0;
    double theta = self.values[@"theta"] ? self.values[@"theta"].doubleValue : 0.0;
    double phi = self.values[@"phi"] ? self.values[@"phi"].doubleValue : 0.0;
    BOOL ensemble = self.values[@"ensemble"] ? self.values[@"ensemble"].integerValue == 1 : NO;
    [self.threeDView updateField:field theta:theta phi:phi ensemble:ensemble];

    if ([tab isEqualToString:@"Signal"] || [tab isEqualToString:@"Levels"] || [tab isEqualToString:@"Noise"] ||
        [tab isEqualToString:@"T1"] || [tab isEqualToString:@"T2"]) {
        self.plotView.hidden = NO;
        NSArray<NVSeries *> *series = self.result.signalSeries;
        NSString *title = self.currentExperiment.title;
        NSString *xLabel = @"";
        NSString *yLabel = @"Normalized PL";
        if ([tab isEqualToString:@"Levels"]) {
            series = self.result.levelSeries;
            BOOL ensemble = self.values[@"ensemble"] ? self.values[@"ensemble"].integerValue == 1 : NO;
            title = (self.currentExperiment.kind == NVExperimentKindODMR && ensemble)
                ? @"Spin energy levels · four ⟨111⟩ orientations"
                : @"Spin energy levels";
            xLabel = @"Magnetic field (mT)";
            yLabel = @"Frequency (GHz)";
        } else if ([tab isEqualToString:@"Noise"]) {
            series = self.result.noiseSeries;
            title = @"CPMG filter function";
            xLabel = @"Frequency (MHz)";
            yLabel = @"Normalized response";
        } else if ([tab isEqualToString:@"T1"]) {
            series = self.result.t1Series;
            title = @"T₁ relaxation recovery";
            xLabel = @"Wait time (µs)";
        } else if ([tab isEqualToString:@"T2"]) {
            series = self.result.t2Series;
            title = @"Coherence decay";
            xLabel = @"Free evolution (ns)";
        } else {
            switch (self.currentExperiment.kind) {
                case NVExperimentKindODMR: xLabel = @"Microwave frequency (GHz)"; break;
                case NVExperimentKindRabi:
                case NVExperimentKindRamsey:
                case NVExperimentKindEcho: xLabel = @"Time (ns)"; break;
                case NVExperimentKindCPMG: xLabel = @"Number of π pulses"; yLabel = @"Normalized PL"; break;
                case NVExperimentKindAlignment: xLabel = @"Beam overlap (%)"; yLabel = @"Normalized response"; break;
                case NVExperimentKindRelaxation: xLabel = @"Time (µs)"; break;
                default: xLabel = @""; break;
            }
        }
        [self.plotView setSeries:series title:title xLabel:xLabel yLabel:yLabel];
    } else if ([tab isEqualToString:@"Sequence"]) {
        self.sequenceView.hidden = NO;
        [self.sequenceView setSequence:self.result.sequence];
    } else if ([tab isEqualToString:@"Bloch"]) {
        self.blochView.hidden = NO;
        self.blochView.title = @"Qubit state on the Bloch sphere";
        [self.blochView setTheta:self.result.blochTheta phi:self.result.blochPhi length:self.result.blochLength];
    } else if ([tab isEqualToString:@"Readout"]) {
        self.histogramView.hidden = NO;
        self.histogramView.title = @"Single-shot readout";
        [self.histogramView setCounts0:self.result.histogram0 counts1:self.result.histogram1];
    } else if ([tab isEqualToString:@"3D"]) {
        self.threeDView.hidden = NO;
        double f = field;
        if (self.currentExperiment.kind == NVExperimentKindAlignment) f = 0;
        [self.threeDView updateField:f theta:theta phi:phi ensemble:ensemble];
    } else if ([tab isEqualToString:@"Hardware"]) {
        self.hardwareScroll.hidden = NO;
        self.hardwareTextView.string = self.result.hardwareText.length ? self.result.hardwareText : NVHardwareDescription();
        [self.hardwareTextView scrollRangeToVisible:NSMakeRange(0, 0)];
    }
}

#pragma mark - Table

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return (NSInteger)self.experiments.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cell = [tableView makeViewWithIdentifier:@"ExperimentCell" owner:self];
    if (!cell) {
        cell = [[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, 210, 40)];
        cell.identifier = @"ExperimentCell";
        NSTextField *tf = [NSTextField labelWithString:@""];
        tf.translatesAutoresizingMaskIntoConstraints = NO;
        tf.font = [NSFont systemFontOfSize:12 weight:NSFontWeightMedium];
        tf.textColor = TextColor();
        tf.lineBreakMode = NSLineBreakByTruncatingTail;
        [cell addSubview:tf];
        cell.textField = tf;
        [NSLayoutConstraint activateConstraints:@[
            [tf.leadingAnchor constraintEqualToAnchor:cell.leadingAnchor constant:12],
            [tf.trailingAnchor constraintEqualToAnchor:cell.trailingAnchor constant:-8],
            [tf.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor]
        ]];
    }
    NVExperiment *e = self.experiments[row];
    cell.textField.stringValue = [NSString stringWithFormat:@"%@   %@", e.symbol, e.title];
    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger row = self.sidebarTable.selectedRow;
    if (row >= 0 && row < (NSInteger)self.experiments.count) {
        [self activateExperiment:self.experiments[row]];
    }
}

#pragma mark - Export helpers

- (NSString *)displayStringForParameter:(NVParameter *)parameter value:(NSNumber *)number {
    double v = number.doubleValue;
    if (parameter.kind == NVParameterKindChoice) {
        NSInteger index = (NSInteger)llround(v);
        if (index >= 0 && index < (NSInteger)parameter.choices.count) return parameter.choices[index];
        return [NSString stringWithFormat:@"%ld", (long)index];
    }
    if (parameter.unit.length == 0) return [NSString stringWithFormat:@"%.4g", v];
    if ([parameter.unit isEqualToString:@"°"] || [parameter.unit isEqualToString:@"%"]) {
        return [NSString stringWithFormat:@"%.4g%@", v, parameter.unit];
    }
    return [NSString stringWithFormat:@"%.4g %@", v, parameter.unit];
}

- (NSArray<NSString *> *)parameterLines {
    NSMutableArray *lines = [NSMutableArray array];
    for (NVParameter *p in self.currentExperiment.parameters) {
        if (![self isParameterVisible:p]) continue;
        NSNumber *value = self.values[p.key];
        if (!value) value = @(p.kind == NVParameterKindChoice ? (double)p.selectedIndex : p.value);
        [lines addObject:[NSString stringWithFormat:@"%@: %@", p.label, [self displayStringForParameter:p value:value]]];
    }
    return lines;
}

- (NSArray<NVSeries *> *)exportSeries {
    if (!self.result) return @[];
    NSString *tab = self.currentTab >= 0 && self.currentTab < (NSInteger)self.currentExperiment.tabs.count
        ? self.currentExperiment.tabs[self.currentTab] : @"Signal";
    if ([tab isEqualToString:@"Levels"]) return self.result.levelSeries;
    if ([tab isEqualToString:@"Noise"]) return self.result.noiseSeries;
    if ([tab isEqualToString:@"T1"]) return self.result.t1Series;
    if ([tab isEqualToString:@"T2"]) return self.result.t2Series;
    if (self.result.signalSeries.count > 0) return self.result.signalSeries;
    for (NSArray<NVSeries *> *candidate in @[self.result.t1Series, self.result.t2Series,
                                             self.result.levelSeries, self.result.noiseSeries]) {
        if (candidate.count > 0) return candidate;
    }
    return @[];
}

- (NSString *)exportSeriesTitle {
    NSString *tab = self.currentTab >= 0 && self.currentTab < (NSInteger)self.currentExperiment.tabs.count
        ? self.currentExperiment.tabs[self.currentTab] : @"Signal";
    if ([tab isEqualToString:@"Levels"]) return @"Spin energy levels";
    if ([tab isEqualToString:@"Noise"]) return @"CPMG filter function";
    if ([tab isEqualToString:@"T1"]) return @"T₁ relaxation recovery";
    if ([tab isEqualToString:@"T2"]) return @"Coherence decay";
    if ([tab isEqualToString:@"Signal"]) return self.currentExperiment.title;
    return [NSString stringWithFormat:@"%@ — %@", self.currentExperiment.title, tab];
}

- (NSString *)safeFileStem {
    NSString *stem = [self.currentExperiment.title stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
    stem = [stem stringByReplacingOccurrencesOfString:@":" withString:@"-"];
    return stem.length ? stem : @"NVSpinLab";
}

- (NSString *)timestampString {
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    return [formatter stringFromDate:[NSDate date]];
}

- (NSDictionary *)seriesPayload:(NVSeries *)series {
    return @{@"label": series.label ?: @"",
             @"x": series.x,
             @"y": series.y};
}

- (NSDictionary *)resultPayload {
    NSMutableDictionary *payload = [NSMutableDictionary dictionary];
    payload[@"format"] = @"org.nvlabs.NVSpinLab.result";
    payload[@"version"] = @1;
    payload[@"generatedAt"] = [self timestampString];
    payload[@"experiment"] = @{@"index": @([self.experiments indexOfObject:self.currentExperiment]),
                               @"kind": @(self.currentExperiment.kind),
                               @"title": self.currentExperiment.title ?: @""};
    payload[@"mode"] = self.guidedModeActive ? @"guided" : @"advanced";
    payload[@"profile"] = self.idealProfile ? @"ideal" : @"reference";
    payload[@"summary"] = self.result.summary ?: @"";
    payload[@"parameters"] = self.values ?: @{};
    payload[@"parameterLabels"] = [self parameterLines];

    NSMutableArray *seriesGroups = [NSMutableArray array];
    NSArray *groups = @[@{@"name": @"signal", @"series": self.result.signalSeries ?: @[]},
                        @{@"name": @"levels", @"series": self.result.levelSeries ?: @[]},
                        @{@"name": @"noise", @"series": self.result.noiseSeries ?: @[]},
                        @{@"name": @"t1", @"series": self.result.t1Series ?: @[]},
                        @{@"name": @"t2", @"series": self.result.t2Series ?: @[]}];
    for (NSDictionary *group in groups) {
        NSMutableArray *items = [NSMutableArray array];
        for (NVSeries *series in group[@"series"]) [items addObject:[self seriesPayload:series]];
        if (items.count > 0) [seriesGroups addObject:@{@"name": group[@"name"], @"series": items}];
    }
    payload[@"series"] = seriesGroups;
    if (self.result.detailSeries.count > 0) {
        NSMutableArray *detail = [NSMutableArray array];
        for (NVSeries *series in self.result.detailSeries) [detail addObject:[self seriesPayload:series]];
        payload[@"detail"] = @{@"title": self.result.detailTitle ?: @"",
                               @"xLabel": self.result.detailXLabel ?: @"",
                               @"yLabel": self.result.detailYLabel ?: @"",
                               @"series": detail};
    }

    NVSequenceModel *sequence = self.result.sequence;
    if (sequence) {
        NSMutableArray *events = [NSMutableArray array];
        for (NVSequenceEvent *event in sequence.events) {
            NSString *track = event.track == NVTrackLaser ? @"laser" : (event.track == NVTrackMW ? @"microwave" : @"readout");
            [events addObject:@{@"track": track, @"start": @(event.start), @"duration": @(event.duration),
                                 @"label": event.label ?: @""}];
        }
        payload[@"sequence"] = @{@"title": sequence.title ?: @"", @"duration": @(sequence.duration), @"events": events};
    }
    payload[@"readout"] = @{@"counts0": @(self.result.histogram0), @"counts1": @(self.result.histogram1),
                            @"fidelity": @(self.result.fidelity)};
    payload[@"bloch"] = @{@"theta": @(self.result.blochTheta), @"phi": @(self.result.blochPhi), @"length": @(self.result.blochLength)};
    payload[@"metrics"] = self.result.metrics ?: @{};
    return payload;
}

- (NSImage *)visualizationImage {
    if (!self.threeDView.hidden) {
        NSImage *snapshot = [self.threeDView snapshot];
        if (snapshot) return snapshot;
    }
    NSView *view = self.contentHost;
    if (view.bounds.size.width < 10 || view.bounds.size.height < 10) return nil;
    NSBitmapImageRep *rep = [view bitmapImageRepForCachingDisplayInRect:view.bounds];
    [view cacheDisplayInRect:view.bounds toBitmapImageRep:rep];
    NSImage *image = [[NSImage alloc] initWithSize:view.bounds.size];
    [image addRepresentation:rep];
    return image;
}

- (void)setGuidedMode:(BOOL)guided {
    if (guided == self.guidedModeActive) return;
    self.guidedModeActive = guided;
    self.modeControl.selectedSegment = guided ? 0 : 1;
    [self buildParameterControls];
    [self runSimulation:nil];
}

- (NVReportView *)makeReportView {
    NVReportView *report = [[NVReportView alloc] initWithFrame:NSMakeRect(0, 0, 612, 792)];
    report.experimentTitle = self.currentExperiment.title ?: @"NV Spin Lab";
    report.summary = self.result.summary ?: @"";
    report.parameterLines = [self parameterLines];
    report.visualization = [self visualizationImage];
    report.footer = [NSString stringWithFormat:@"NV Spin Lab · offline simulation · %@ · %@ · %@",
                     [self timestampString], self.guidedModeActive ? @"Guided mode" : @"Advanced mode",
                     self.idealProfile ? @"Ideal profile" : @"Reference profile"];
    return report;
}

- (NSData *)reportPDFData {
    NVReportView *report = [self makeReportView];
    return [report dataWithPDFInsideRect:report.bounds];
}

- (NSData *)reportPNGData {
    NVReportView *report = [self makeReportView];
    NSBitmapImageRep *rep = [report bitmapImageRepForCachingDisplayInRect:report.bounds];
    [report cacheDisplayInRect:report.bounds toBitmapImageRep:rep];
    return [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
}

- (void)debugWriteExportsToDirectory:(NSString *)directory {
    [[NSFileManager defaultManager] createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    NSData *json = [NSJSONSerialization dataWithJSONObject:[self resultPayload]
                                                   options:(NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys)
                                                     error:nil];
    if (json) [json writeToFile:[directory stringByAppendingPathComponent:@"result.json"] atomically:YES];
    NSArray<NVSeries *> *series = [self exportSeries];
    if (series.count > 0) {
        [[self csvTextForSeries:series] writeToFile:[directory stringByAppendingPathComponent:@"data.csv"]
                                          atomically:YES encoding:NSUTF8StringEncoding error:nil];
    }
    NSError *sessionError = nil;
    [self writeSessionToURL:[NSURL fileURLWithPath:[directory stringByAppendingPathComponent:@"session.nvlab"]]
                     error:&sessionError];
    NSData *pdf = [self reportPDFData];
    if (pdf) [pdf writeToFile:[directory stringByAppendingPathComponent:@"report.pdf"] atomically:YES];
    NSData *png = [self reportPNGData];
    if (png) [png writeToFile:[directory stringByAppendingPathComponent:@"report.png"] atomically:YES];
    NSImage *visualization = [self visualizationImage];
    if (visualization) {
        NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:visualization.TIFFRepresentation];
        NSData *vpn = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
        if (vpn) [vpn writeToFile:[directory stringByAppendingPathComponent:@"visualization.png"] atomically:YES];
    }
}

- (void)presentError:(NSString *)title message:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = title;
    alert.informativeText = message ?: @"";
    [alert runModal];
}

- (UTType *)contentTypeForExtension:(NSString *)extension fallback:(UTType *)fallback {
    UTType *type = [UTType typeWithFilenameExtension:extension];
    return type ?: fallback;
}

#pragma mark - Export actions

- (NSString *)csvTextForSeries:(NSArray<NVSeries *> *)series {
    NSMutableString *csv = [NSMutableString string];
    [csv appendString:@"# NV Spin Lab\n"];
    [csv appendFormat:@"# Experiment,%@\n", self.currentExperiment.title];
    [csv appendFormat:@"# Mode,%@\n", self.guidedModeActive ? @"Guided" : @"Advanced"];
    [csv appendFormat:@"# Profile,%@\n", self.idealProfile ? @"Ideal" : @"Reference"];
    [csv appendFormat:@"# Generated,%@\n", [self timestampString]];
    for (NSString *line in [self parameterLines]) {
        [csv appendFormat:@"# %@\n", [line stringByReplacingOccurrencesOfString:@"," withString:@";"]];
    }
    [csv appendString:@"#\n"];
    NSInteger maxCount = 0;
    for (NVSeries *s in series) maxCount = MAX(maxCount, (NSInteger)MIN(s.x.count, s.y.count));
    [csv appendString:@"x"];
    for (NVSeries *s in series) [csv appendFormat:@",%@", s.label ?: @"y"];
    [csv appendString:@"\n"];
    for (NSInteger i = 0; i < maxCount; i++) {
        NSNumber *x = i < (NSInteger)series[0].x.count ? series[0].x[i] : @0;
        [csv appendFormat:@"%@", x];
        for (NVSeries *s in series) {
            NSNumber *y = i < (NSInteger)s.y.count ? s.y[i] : @0;
            [csv appendFormat:@",%@", y];
        }
        [csv appendString:@"\n"];
    }
    return csv;
}

- (void)exportCSV:(id)sender {
    NSArray<NVSeries *> *series = [self exportSeries];
    if (series.count == 0) {
        [self presentError:@"Nothing to export" message:@"The current view has no plotted result yet."];
        return;
    }
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.nameFieldStringValue = [NSString stringWithFormat:@"%@.csv", [self safeFileStem]];
    panel.allowedContentTypes = @[[self contentTypeForExtension:@"csv" fallback:UTTypeCommaSeparatedText]];
    panel.canCreateDirectories = YES;
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse response) {
        if (response != NSModalResponseOK) return;
        NSError *error = nil;
        [[self csvTextForSeries:series] writeToURL:panel.URL atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (error) [self presentError:@"Could not export CSV" message:error.localizedDescription];
        else self.statusLabel.stringValue = [NSString stringWithFormat:@"Exported CSV · %@", panel.URL.lastPathComponent];
    }];
}

- (void)exportJSON:(id)sender {
    if (!self.result) {
        [self presentError:@"Nothing to export" message:@"Adjust a parameter to generate a result first."];
        return;
    }
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.nameFieldStringValue = [NSString stringWithFormat:@"%@.json", [self safeFileStem]];
    panel.allowedContentTypes = @[[self contentTypeForExtension:@"json" fallback:UTTypeJSON]];
    panel.canCreateDirectories = YES;
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse response) {
        if (response != NSModalResponseOK) return;
        NSError *error = nil;
        NSData *data = [NSJSONSerialization dataWithJSONObject:[self resultPayload]
                                                       options:(NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys)
                                                         error:&error];
        if (!error) [data writeToURL:panel.URL options:NSDataWritingAtomic error:&error];
        if (error) [self presentError:@"Could not export JSON" message:error.localizedDescription];
        else self.statusLabel.stringValue = [NSString stringWithFormat:@"Exported JSON · %@", panel.URL.lastPathComponent];
    }];
}

- (void)exportPNG:(id)sender {
    NSImage *visualization = [self visualizationImage];
    if (!visualization) {
        [self presentError:@"Nothing to export" message:@"No visualization is available for the current tab."];
        return;
    }
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.nameFieldStringValue = [NSString stringWithFormat:@"%@.png", [self safeFileStem]];
    panel.allowedContentTypes = @[[self contentTypeForExtension:@"png" fallback:UTTypePNG]];
    panel.canCreateDirectories = YES;
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse response) {
        if (response != NSModalResponseOK) return;
        NSData *png = [self reportPNGData];
        NSError *error = nil;
        if (png) [png writeToURL:panel.URL options:NSDataWritingAtomic error:&error];
        if (!png || error) [self presentError:@"Could not export PNG" message:error.localizedDescription ?: @"Image encoding failed."];
        else self.statusLabel.stringValue = [NSString stringWithFormat:@"Exported PNG · %@", panel.URL.lastPathComponent];
    }];
}

- (void)exportPDF:(id)sender {
    if (!self.result) {
        [self presentError:@"Nothing to export" message:@"Adjust a parameter to generate a result first."];
        return;
    }
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.nameFieldStringValue = [NSString stringWithFormat:@"%@-report.pdf", [self safeFileStem]];
    panel.allowedContentTypes = @[[self contentTypeForExtension:@"pdf" fallback:UTTypePDF]];
    panel.canCreateDirectories = YES;
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse response) {
        if (response != NSModalResponseOK) return;
        NSData *pdf = [self reportPDFData];
        NSError *error = nil;
        if (pdf) [pdf writeToURL:panel.URL options:NSDataWritingAtomic error:&error];
        if (!pdf || error) [self presentError:@"Could not export PDF" message:error.localizedDescription ?: @"PDF rendering failed."];
        else self.statusLabel.stringValue = [NSString stringWithFormat:@"Exported PDF report · %@", panel.URL.lastPathComponent];
    }];
}

- (void)exportMenuChanged:(id)sender {
    NSMenuItem *item = self.exportButton.selectedItem;
    NSInteger tag = item.tag;
    [self.exportButton selectItemAtIndex:0];
    switch (tag) {
        case 1: [self exportCSV:sender]; break;
        case 2: [self exportJSON:sender]; break;
        case 3: [self exportPNG:sender]; break;
        case 4: [self exportPDF:sender]; break;
        case 5: [self addToNotebook:sender]; break;
        case 6: [self showNotebook:sender]; break;
        case 7: [self saveNotebook:sender]; break;
        default: break;
    }
}

#pragma mark - Sessions

- (NSDictionary *)sessionPayload {
    [self storeCurrentValues];
    NSInteger currentIndex = [self indexOfCurrentExperiment];
    NSMutableDictionary<NSString *, NSDictionary *> *allParameters = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < (NSInteger)self.experiments.count; i++) {
        NVExperiment *experiment = self.experiments[i];
        NSDictionary<NSString *, NSNumber *> *stored = self.experimentValues[@(i)];
        NSMutableDictionary<NSString *, NSNumber *> *parameters = [NSMutableDictionary dictionary];
        for (NVParameter *parameter in experiment.parameters) {
            NSNumber *value = (i == currentIndex) ? self.values[parameter.key] : stored[parameter.key];
            if (![value isKindOfClass:[NSNumber class]]) {
                value = @(parameter.kind == NVParameterKindChoice ? (double)parameter.selectedIndex : parameter.value);
            }
            parameters[parameter.key] = value;
        }
        allParameters[NVSessionKeyForExperimentKind(experiment.kind)] = parameters;
    }
    NSString *currentKey = NVSessionKeyForExperimentKind(self.currentExperiment.kind);
    NSDictionary *currentParameters = allParameters[currentKey] ?: @{};
    return @{@"format": @"org.nvlabs.NVSpinLab.session",
             @"version": @2,
             @"experimentIndex": @(currentIndex),
             @"experimentTitle": self.currentExperiment.title ?: @"",
             @"currentTab": @(MAX(0, self.currentTab)),
             @"guided": @(self.guidedModeActive),
             @"idealProfile": @(self.idealProfile),
             @"parameters": currentParameters,
             @"experimentParameters": allParameters,
             @"notebook": [self.notebook copy],
             @"savedAt": [self timestampString]};
}

- (BOOL)writeSessionToURL:(NSURL *)url error:(NSError **)error {
    NSData *data = [NSJSONSerialization dataWithJSONObject:[self sessionPayload]
                                                   options:(NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys)
                                                     error:error];
    if (!data) return NO;
    return [data writeToURL:url options:NSDataWritingAtomic error:error];
}

- (BOOL)loadSessionFromURL:(NSURL *)url error:(NSError **)error {
    NSData *data = [NSData dataWithContentsOfURL:url options:0 error:error];
    if (!data) return NO;
    id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:error];
    if (![object isKindOfClass:[NSDictionary class]]) {
        if (error) *error = [NSError errorWithDomain:@"org.nvlabs.NVSpinLab" code:1
                                           userInfo:@{NSLocalizedDescriptionKey: @"Unrecognized file format."}];
        return NO;
    }
    NSDictionary *session = object;
    if (![session[@"format"] isEqual:@"org.nvlabs.NVSpinLab.session"]) {
        if (error) *error = [NSError errorWithDomain:@"org.nvlabs.NVSpinLab" code:2
                                           userInfo:@{NSLocalizedDescriptionKey: @"This is not an NV Spin Lab session file."}];
        return NO;
    }
    [self applySession:session];
    return YES;
}

- (void)saveSession:(id)sender {
    if (!self.currentExperiment) return;
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.nameFieldStringValue = [NSString stringWithFormat:@"%@.nvlab", [self safeFileStem]];
    panel.allowedContentTypes = @[[self contentTypeForExtension:@"nvlab" fallback:UTTypeData]];
    panel.canCreateDirectories = YES;
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse response) {
        if (response != NSModalResponseOK) return;
        NSError *error = nil;
        if (![self writeSessionToURL:panel.URL error:&error]) {
            [self presentError:@"Could not save session" message:error.localizedDescription];
        } else {
            self.statusLabel.stringValue = [NSString stringWithFormat:@"Session saved · %@", panel.URL.lastPathComponent];
        }
    }];
}

- (void)restoreAllExperimentParameters:(NSDictionary *)allParameters {
    for (NSInteger i = 0; i < (NSInteger)self.experiments.count; i++) {
        NVExperiment *experiment = self.experiments[i];
        NSDictionary *saved = allParameters[NVSessionKeyForExperimentKind(experiment.kind)];
        NSMutableDictionary<NSString *, NSNumber *> *stored = [NSMutableDictionary dictionary];
        for (NVParameter *parameter in experiment.parameters) {
            NSNumber *value = [saved isKindOfClass:[NSDictionary class]] ? saved[parameter.key] : nil;
            if (![value isKindOfClass:[NSNumber class]]) {
                value = @(parameter.kind == NVParameterKindChoice ? (double)parameter.selectedIndex : parameter.value);
            }
            stored[parameter.key] = value;
        }
        self.experimentValues[@(i)] = stored;
    }
}

- (void)refreshSidebarAfterSessionLoadAtIndex:(NSInteger)index {
    self.sidebarTable.delegate = nil;
    [self.sidebarTable reloadData];
    [self.sidebarTable selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    self.sidebarTable.delegate = self;
    [self.sidebarTable scrollRowToVisible:index];
    [self.view layoutSubtreeIfNeeded];
}

- (void)applySession:(NSDictionary *)session {
    NSNumber *indexNumber = session[@"experimentIndex"];
    NSInteger index = indexNumber.integerValue;
    if (![indexNumber isKindOfClass:[NSNumber class]] || index < 0 || index >= (NSInteger)self.experiments.count) {
        [self presentError:@"Invalid session" message:@"The session does not contain a valid experiment index."];
        return;
    }

    if (session[@"guided"] != nil) {
        self.guidedModeActive = [session[@"guided"] boolValue];
        self.modeControl.selectedSegment = self.guidedModeActive ? 0 : 1;
    }
    if (session[@"idealProfile"] != nil) {
        self.idealProfile = [session[@"idealProfile"] boolValue];
        self.profileLabel.stringValue = self.idealProfile ? @"Ideal profile · simulated" : @"Reference profile · simulated";
    }

    NSInteger tab = 0;
    NSNumber *tabNumber = session[@"currentTab"];
    if ([tabNumber isKindOfClass:[NSNumber class]]) tab = tabNumber.integerValue;
    [self selectExperimentAtIndex:index tab:tab];

    NSDictionary *allParameters = session[@"experimentParameters"];
    if ([allParameters isKindOfClass:[NSDictionary class]]) {
        [self restoreAllExperimentParameters:allParameters];
        NSDictionary<NSString *, NSNumber *> *currentStore = self.experimentValues[@(index)];
        [self.values removeAllObjects];
        if (currentStore) [self.values addEntriesFromDictionary:currentStore];
    } else {
        NSDictionary *parameters = session[@"parameters"];
        if ([parameters isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary<NSString *, NSNumber *> *currentStore = self.experimentValues[@(index)];
            for (NSString *key in parameters) {
                NSNumber *value = parameters[key];
                if ([value isKindOfClass:[NSNumber class]] && [self.currentExperiment parameterForKey:key]) {
                    self.values[key] = value;
                    if (currentStore) currentStore[key] = value;
                }
            }
        }
    }

    id notebook = session[@"notebook"];
    if ([notebook isKindOfClass:[NSArray class]]) {
        [self.notebook removeAllObjects];
        for (id entry in (NSArray *)notebook) {
            if ([entry isKindOfClass:[NSDictionary class]]) {
                [self.notebook addObject:[entry mutableCopy]];
            }
        }
        [self refreshNotebook];
    }

    [self buildParameterControls];
    [self runSimulation:nil];
    [self resetParameterScrollPosition];
    [self refreshSidebarAfterSessionLoadAtIndex:index];
    self.statusLabel.stringValue = [NSString stringWithFormat:@"Session loaded · %@", self.currentExperiment.title];
}

- (void)openSession:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedContentTypes = @[[self contentTypeForExtension:@"nvlab" fallback:UTTypeData]];
    panel.allowsMultipleSelection = NO;
    panel.canChooseDirectories = NO;
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse response) {
        if (response != NSModalResponseOK) return;
        NSError *error = nil;
        if (![self loadSessionFromURL:panel.URL error:&error]) {
            [self presentError:@"Could not open session" message:error.localizedDescription ?: @"Unrecognized file format."];
        }
    }];
}

#pragma mark - Notebook

- (NSString *)notebookText {
    if (self.notebook.count == 0) return @"No entries yet. Adjust a parameter, then choose Export → Add to notebook.";
    NSMutableString *text = [NSMutableString string];
    [text appendString:@"NV SPIN LAB — LAB NOTEBOOK\n\n"];
    for (NSInteger i = 0; i < (NSInteger)self.notebook.count; i++) {
        NSDictionary *entry = self.notebook[i];
        [text appendFormat:@"%ld. %@  ·  %@\n", (long)(i + 1), entry[@"experiment"], entry[@"date"]];
        [text appendFormat:@"  Profile: %@\n", entry[@"profile"] ?: @"Reference"];
        [text appendString:@"------------------------------------------------------------\n"];
        NSArray *parameters = entry[@"parameters"];
        for (NSString *line in parameters) [text appendFormat:@"  %@\n", line];
        [text appendFormat:@"\n%@\n\n", entry[@"summary"]];
    }
    return text;
}

- (void)refreshNotebook {
    if (!self.notebookPanel) return;
    self.notebookTextView.string = [self notebookText];
    [self.notebookTextView scrollRangeToVisible:NSMakeRange(0, 0)];
    self.notebookPanel.title = [NSString stringWithFormat:@"Lab Notebook — %lu entries", (unsigned long)self.notebook.count];
}

- (void)addToNotebook:(id)sender {
    if (!self.result) {
        [self presentError:@"Nothing to record" message:@"Adjust a parameter to generate a result first."];
        return;
    }
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateStyle = NSDateFormatterMediumStyle;
    formatter.timeStyle = NSDateFormatterShortStyle;
    NSDictionary *entry = @{@"experiment": self.currentExperiment.title ?: @"",
                            @"date": [formatter stringFromDate:[NSDate date]],
                            @"profile": self.idealProfile ? @"Ideal" : @"Reference",
                            @"parameters": [self parameterLines],
                            @"summary": self.result.summary ?: @""};
    [self.notebook addObject:entry];
    [self refreshNotebook];
    self.statusLabel.stringValue = @"Added current result to the lab notebook";
}

- (void)showNotebook:(id)sender {
    if (!self.notebookPanel) {
        NSPanel *panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 760, 560)
                                                    styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
        panel.title = @"Lab Notebook";
        panel.minSize = NSMakeSize(520, 360);
        panel.releasedWhenClosed = NO;
        panel.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
        panel.backgroundColor = PanelColor();
        [panel center];
        NSView *content = panel.contentView;
        content.wantsLayer = YES;
        content.layer.backgroundColor = PanelColor().CGColor;

        self.notebookTextView = [self textView];
        NSScrollView *scroll = [self scrollForTextView:self.notebookTextView];
        scroll.wantsLayer = YES;
        scroll.layer.backgroundColor = SidebarColor().CGColor;
        scroll.layer.cornerRadius = 8;
        [content addSubview:scroll];

        NSButton *save = [NSButton buttonWithTitle:@"Save notebook…" target:self action:@selector(saveNotebook:)];
        save.translatesAutoresizingMaskIntoConstraints = NO;
        save.bezelStyle = NSBezelStyleRounded;
        [content addSubview:save];
        NSButton *clear = [NSButton buttonWithTitle:@"Clear" target:self action:@selector(clearNotebook:)];
        clear.translatesAutoresizingMaskIntoConstraints = NO;
        clear.bezelStyle = NSBezelStyleRounded;
        [content addSubview:clear];
        NSButton *close = [NSButton buttonWithTitle:@"Close" target:panel action:@selector(performClose:)];
        close.translatesAutoresizingMaskIntoConstraints = NO;
        close.bezelStyle = NSBezelStyleRounded;
        [content addSubview:close];

        [NSLayoutConstraint activateConstraints:@[
            [scroll.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:16],
            [scroll.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-16],
            [scroll.topAnchor constraintEqualToAnchor:content.topAnchor constant:16],
            [scroll.bottomAnchor constraintEqualToAnchor:save.topAnchor constant:-12],
            [save.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:16],
            [save.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-12],
            [clear.leadingAnchor constraintEqualToAnchor:save.trailingAnchor constant:8],
            [clear.centerYAnchor constraintEqualToAnchor:save.centerYAnchor],
            [close.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-16],
            [close.centerYAnchor constraintEqualToAnchor:save.centerYAnchor]
        ]];
        self.notebookPanel = panel;
    }
    [self refreshNotebook];
    [self.notebookPanel makeKeyAndOrderFront:nil];
}

- (void)saveNotebook:(id)sender {
    if (self.notebook.count == 0) {
        [self presentError:@"Notebook is empty" message:@"Add a result to the notebook first."];
        return;
    }
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.nameFieldStringValue = @"NVSpinLab-Notebook.txt";
    panel.allowedContentTypes = @[[self contentTypeForExtension:@"txt" fallback:UTTypePlainText]];
    panel.canCreateDirectories = YES;
    [panel beginSheetModalForWindow:self.notebookPanel ?: self.view.window completionHandler:^(NSModalResponse response) {
        if (response != NSModalResponseOK) return;
        NSError *error = nil;
        [[self notebookText] writeToURL:panel.URL atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (error) [self presentError:@"Could not save notebook" message:error.localizedDescription];
        else self.statusLabel.stringValue = [NSString stringWithFormat:@"Notebook saved · %@", panel.URL.lastPathComponent];
    }];
}

- (void)clearNotebook:(id)sender {
    if (self.notebook.count == 0) return;
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Clear the lab notebook?";
    alert.informativeText = @"This removes all entries from the current session.";
    [alert addButtonWithTitle:@"Clear"];
    [alert addButtonWithTitle:@"Cancel"];
    if ([alert runModal] != NSAlertFirstButtonReturn) return;
    [self.notebook removeAllObjects];
    [self refreshNotebook];
}

- (void)showHowToUse:(id)sender {
    if (!self.helpPanel) {
        NSPanel *panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 700, 620)
                                                    styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
        panel.title = @"How to Use NV Spin Lab";
        panel.minSize = NSMakeSize(520, 400);
        panel.releasedWhenClosed = NO;
        panel.appearance = [NSAppearance appearanceNamed:NSAppearanceNameDarkAqua];
        panel.backgroundColor = PanelColor();
        [panel center];

        NSView *content = panel.contentView;
        content.wantsLayer = YES;
        content.layer.backgroundColor = PanelColor().CGColor;

        self.helpTextView = [self textView];
        NSScrollView *scroll = [self scrollForTextView:self.helpTextView];
        scroll.wantsLayer = YES;
        scroll.layer.backgroundColor = SidebarColor().CGColor;
        scroll.layer.cornerRadius = 8;
        [content addSubview:scroll];

        NSButton *close = [NSButton buttonWithTitle:@"Close" target:panel action:@selector(performClose:)];
        close.translatesAutoresizingMaskIntoConstraints = NO;
        close.bezelStyle = NSBezelStyleRounded;
        [content addSubview:close];

        [NSLayoutConstraint activateConstraints:@[
            [scroll.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:16],
            [scroll.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-16],
            [scroll.topAnchor constraintEqualToAnchor:content.topAnchor constant:16],
            [scroll.bottomAnchor constraintEqualToAnchor:close.topAnchor constant:-12],
            [close.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-16],
            [close.bottomAnchor constraintEqualToAnchor:content.bottomAnchor constant:-12]
        ]];
        self.helpPanel = panel;
    }
    self.helpTextView.string = NVHowToUseText();
    [self.helpTextView scrollRangeToVisible:NSMakeRange(0, 0)];
    [self.helpPanel makeKeyAndOrderFront:nil];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if (menuItem.action == @selector(toggleGuidedMode:)) {
        menuItem.state = self.guidedModeActive ? NSControlStateValueOn : NSControlStateValueOff;
    }
    if (menuItem.action == @selector(toggleIdealProfile:)) {
        menuItem.state = self.idealProfile ? NSControlStateValueOn : NSControlStateValueOff;
    }
    if (menuItem.action == @selector(addToNotebook:)) return self.result != nil;
    return YES;
}

@end
