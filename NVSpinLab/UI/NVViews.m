#import "NVViews.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

static NSColor *NVAccent(void) { return [NSColor colorWithSRGBRed:0.37 green:0.72 blue:1.0 alpha:1.0]; }
static NSColor *NVAmber(void) { return [NSColor colorWithSRGBRed:0.95 green:0.68 blue:0.22 alpha:1.0]; }
static NSColor *NVCyan(void) { return [NSColor colorWithSRGBRed:0.24 green:0.82 blue:0.78 alpha:1.0]; }
static NSColor *NVMagenta(void) { return [NSColor colorWithSRGBRed:0.95 green:0.35 blue:0.58 alpha:1.0]; }
static NSColor *NVGreen(void) { return [NSColor colorWithSRGBRed:0.45 green:0.90 blue:0.55 alpha:1.0]; }
static NSColor *NVPanel(void) { return [NSColor colorWithSRGBRed:0.075 green:0.095 blue:0.125 alpha:1.0]; }
static NSColor *NVText(void) { return [NSColor colorWithSRGBRed:0.90 green:0.93 blue:0.98 alpha:1.0]; }
static NSColor *NVSecondary(void) { return [NSColor colorWithSRGBRed:0.55 green:0.62 blue:0.72 alpha:1.0]; }

#pragma mark - Parameter control

@implementation NVParameterControl {
    NSTextField *_nameLabel;
    NSTextField *_valueLabel;
    NSSlider *_slider;
    NSPopUpButton *_popup;
}

- (instancetype)initWithParameter:(NVParameter *)parameter {
    self = [super initWithFrame:NSZeroRect];
    if (!self) return nil;
    _parameter = parameter;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.wantsLayer = YES;

    _nameLabel = [NSTextField labelWithString:parameter.label];
    _nameLabel.font = [NSFont systemFontOfSize:11 weight:NSFontWeightMedium];
    _nameLabel.textColor = NVSecondary();
    _nameLabel.translatesAutoresizingMaskIntoConstraints = NO;

    _valueLabel = [NSTextField labelWithString:@""];
    _valueLabel.font = [NSFont monospacedDigitSystemFontOfSize:11 weight:NSFontWeightRegular];
    _valueLabel.textColor = NVAccent();
    _valueLabel.alignment = NSTextAlignmentRight;
    _valueLabel.translatesAutoresizingMaskIntoConstraints = NO;

    [self addSubview:_nameLabel];
    [self addSubview:_valueLabel];

    if (parameter.kind == NVParameterKindChoice) {
        _popup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
        _popup.translatesAutoresizingMaskIntoConstraints = NO;
        _popup.font = [NSFont systemFontOfSize:11];
        _popup.controlSize = NSControlSizeSmall;
        [_popup addItemsWithTitles:parameter.choices ?: @[]];
        [_popup selectItemAtIndex:parameter.selectedIndex];
        _popup.target = self;
        _popup.action = @selector(popupChanged:);
        [self addSubview:_popup];
        [NSLayoutConstraint activateConstraints:@[
            [_nameLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_nameLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_valueLabel.leadingAnchor constant:-6],
            [_valueLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_valueLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_popup.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_popup.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_popup.topAnchor constraintEqualToAnchor:self.topAnchor constant:19],
            [_popup.heightAnchor constraintEqualToConstant:25]
        ]];
    } else {
        _slider = [[NSSlider alloc] initWithFrame:NSZeroRect];
        _slider.translatesAutoresizingMaskIntoConstraints = NO;
        _slider.minValue = parameter.minValue;
        _slider.maxValue = parameter.maxValue;
        _slider.doubleValue = parameter.value;
        _slider.continuous = YES;
        _slider.controlSize = NSControlSizeSmall;
        _slider.target = self;
        _slider.action = @selector(sliderChanged:);
        [self addSubview:_slider];
        [NSLayoutConstraint activateConstraints:@[
            [_nameLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_nameLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_nameLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_valueLabel.leadingAnchor constant:-6],
            [_valueLabel.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_valueLabel.topAnchor constraintEqualToAnchor:self.topAnchor],
            [_slider.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
            [_slider.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
            [_slider.topAnchor constraintEqualToAnchor:self.topAnchor constant:19],
            [_slider.heightAnchor constraintEqualToConstant:18]
        ]];
    }
    [self updateValueLabel];
    return self;
}

- (void)updateValueLabel {
    if (_parameter.kind == NVParameterKindChoice) {
        NSInteger idx = _popup.indexOfSelectedItem;
        _valueLabel.stringValue = idx >= 0 && idx < (NSInteger)_parameter.choices.count ? _parameter.choices[idx] : @"";
        return;
    }
    double v = _slider.doubleValue;
    NSString *unit = _parameter.unit ?: @"";
    if (unit.length == 0) {
        _valueLabel.stringValue = [NSString stringWithFormat:@"%.0f", v];
        return;
    }
    if ([unit isEqualToString:@"%"]) {
        _valueLabel.stringValue = [NSString stringWithFormat:@"%.1f%%", v];
        return;
    }
    if ([unit isEqualToString:@"°"]) {
        _valueLabel.stringValue = [NSString stringWithFormat:@"%.1f°", v];
        return;
    }
    double range = fabs(_parameter.maxValue - _parameter.minValue);
    NSInteger decimals = 1;
    if (range <= 1.0) decimals = 3;
    else if (range <= 20.0) decimals = 2;
    else if (range <= 200.0) decimals = 1;
    else decimals = 0;
    _valueLabel.stringValue = [NSString stringWithFormat:@"%.*f %@", (int)decimals, v, unit];
}

- (void)sliderChanged:(NSSlider *)sender {
    [self updateValueLabel];
    if (self.onChange) self.onChange(sender.doubleValue);
}

- (void)popupChanged:(NSPopUpButton *)sender {
    [self updateValueLabel];
    if (self.onChange) self.onChange((double)sender.indexOfSelectedItem);
}

- (double)currentValue {
    if (_parameter.kind == NVParameterKindChoice) return (double)_popup.indexOfSelectedItem;
    return _slider.doubleValue;
}

- (void)setCurrentValue:(double)value {
    if (_parameter.kind == NVParameterKindChoice) {
        [_popup selectItemAtIndex:(NSInteger)llround(value)];
    } else {
        _slider.doubleValue = value;
    }
    [self updateValueLabel];
}

- (NSSize)intrinsicContentSize {
    return NSMakeSize(NSViewNoIntrinsicMetric, _parameter.kind == NVParameterKindChoice ? 50.0 : 45.0);
}
@end

#pragma mark - Plot view

@implementation NVPlotView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = NVPanel().CGColor;
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = YES;
        _series = @[];
        _title = @"";
        _xLabel = @"";
        _yLabel = @"";
        _showLegend = YES;
        _detailSeries = @[];
        _detailTitle = @"";
        _detailXLabel = @"";
        _detailYLabel = @"";
    }
    return self;
}

- (BOOL)isFlipped { return YES; }

- (void)setSeries:(NSArray<NVSeries *> *)series
            title:(NSString *)title
           xLabel:(NSString *)xLabel
           yLabel:(NSString *)yLabel {
    _series = [series copy];
    _title = [title copy];
    _xLabel = [xLabel copy];
    _yLabel = [yLabel copy];
    [self setNeedsDisplay:YES];
}

- (void)setDetailSeries:(NSArray<NVSeries *> *)detailSeries
                   title:(NSString *)title
                xLabel:(NSString *)xLabel
                yLabel:(NSString *)yLabel {
    _detailSeries = [detailSeries copy] ?: @[];
    _detailTitle = [title copy] ?: @"";
    _detailXLabel = [xLabel copy] ?: @"";
    _detailYLabel = [yLabel copy] ?: @"";
    [self setNeedsDisplay:YES];
}

- (NSString *)tickString:(double)v {
    if (fabs(v) >= 100) return [NSString stringWithFormat:@"%.0f", v];
    if (fabs(v) >= 10) return [NSString stringWithFormat:@"%.1f", v];
    if (fabs(v) >= 1) return [NSString stringWithFormat:@"%.2f", v];
    return [NSString stringWithFormat:@"%.3f", v];
}

- (void)drawDetailChart:(NSRect)rect {
    if (rect.size.width < 120 || rect.size.height < 60) return;
    NSDictionary *labelAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:9], NSForegroundColorAttributeName: NVSecondary()};
    NSDictionary *smallAttrs = @{NSFontAttributeName: [NSFont monospacedDigitSystemFontOfSize:8 weight:NSFontWeightRegular],
                                 NSForegroundColorAttributeName: NVSecondary()};
    NSBezierPath *background = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:7 yRadius:7];
    [[NSColor colorWithWhite:0.015 alpha:0.48] setFill];
    [background fill];
    [[NSColor colorWithWhite:1.0 alpha:0.10] setStroke];
    [background setLineWidth:1.0];
    [background stroke];

    CGFloat lx = rect.origin.x + 10;
    CGFloat ly = rect.origin.y + 5;
    for (NVSeries *s in _detailSeries) {
        if (!s.showsInLegend) continue;
        NSString *label = s.label ?: @"";
        NSSize sz = [label sizeWithAttributes:labelAttrs];
        CGFloat itemWidth = sz.width + 24;
        if (lx + itemWidth > NSMaxX(rect) - 8) break;
        [s.color ?: NVAccent() setStroke];
        NSBezierPath *swatch = [NSBezierPath bezierPath];
        [swatch moveToPoint:NSMakePoint(lx, ly + 6)];
        [swatch lineToPoint:NSMakePoint(lx + 13, ly + 6)];
        [swatch setLineWidth:2.0];
        [swatch stroke];
        [label drawAtPoint:NSMakePoint(lx + 17, ly) withAttributes:labelAttrs];
        lx += itemWidth;
    }

    NSRect plot = NSMakeRect(rect.origin.x + 48, rect.origin.y + 24,
                             rect.size.width - 58, rect.size.height - 42);
    if (plot.size.width < 80 || plot.size.height < 25) return;
    BOOL hasData = NO;
    double xmin = INFINITY, xmax = -INFINITY, ymin = INFINITY, ymax = -INFINITY;
    for (NVSeries *s in _detailSeries) {
        NSUInteger n = MIN(s.x.count, s.y.count);
        for (NSUInteger i = 0; i < n; i++) {
            double x = s.x[i].doubleValue, y = s.y[i].doubleValue;
            if (!isfinite(x) || !isfinite(y)) continue;
            hasData = YES;
            xmin = MIN(xmin, x); xmax = MAX(xmax, x);
            ymin = MIN(ymin, y); ymax = MAX(ymax, y);
        }
    }
    if (!hasData) return;
    if (xmax - xmin < 1e-9) { xmin -= 1; xmax += 1; }
    if (ymax - ymin < 1e-9) { ymin -= 0.001; ymax += 0.001; }
    if (ymin < 0.0 && ymin > -1e-9) ymin = 0.0;
    double xpad = (xmax - xmin) * 0.04;
    xmin -= xpad; xmax += xpad;
    double ypad = (ymax - ymin) * 0.14;
    ymin -= ypad; ymax += ypad;

    NSColor *grid = [NSColor colorWithWhite:1.0 alpha:0.065];
    NSColor *axis = [NSColor colorWithWhite:1.0 alpha:0.14];
    for (int i = 0; i <= 2; i++) {
        double v = ymin + (ymax - ymin) * (double)i / 2.0;
        CGFloat py = plot.origin.y + plot.size.height * (1.0 - (double)i / 2.0);
        [grid setStroke];
        NSBezierPath *line = [NSBezierPath bezierPath];
        [line moveToPoint:NSMakePoint(plot.origin.x, py)];
        [line lineToPoint:NSMakePoint(NSMaxX(plot), py)];
        [line setLineWidth:1.0];
        [line stroke];
        NSString *label = [NSString stringWithFormat:@"%.3f", v];
        NSSize sz = [label sizeWithAttributes:smallAttrs];
        [label drawAtPoint:NSMakePoint(plot.origin.x - sz.width - 5, py - sz.height / 2.0) withAttributes:smallAttrs];
    }
    for (int i = 0; i <= 4; i++) {
        double v = xmin + (xmax - xmin) * (double)i / 4.0;
        CGFloat px = plot.origin.x + plot.size.width * (double)i / 4.0;
        [grid setStroke];
        NSBezierPath *line = [NSBezierPath bezierPath];
        [line moveToPoint:NSMakePoint(px, plot.origin.y)];
        [line lineToPoint:NSMakePoint(px, NSMaxY(plot))];
        [line setLineWidth:1.0];
        [line stroke];
        NSString *label = [NSString stringWithFormat:@"%+.1f", v];
        NSSize sz = [label sizeWithAttributes:smallAttrs];
        [label drawAtPoint:NSMakePoint(px - sz.width / 2.0, NSMaxY(plot) + 3) withAttributes:smallAttrs];
    }
    [axis setStroke];
    NSBezierPath *frame = [NSBezierPath bezierPathWithRect:plot];
    [frame setLineWidth:1.0];
    [frame stroke];

    [NSGraphicsContext saveGraphicsState];
    [NSBezierPath clipRect:plot];
    for (NVSeries *s in _detailSeries) {
        NSUInteger n = MIN(s.x.count, s.y.count);
        if (n == 0) continue;
        NSColor *col = s.color ?: NVAccent();
        [col setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
        for (NSUInteger i = 0; i < n; i++) {
            double x = s.x[i].doubleValue, y = s.y[i].doubleValue;
            CGFloat px = plot.origin.x + (x - xmin) / (xmax - xmin) * plot.size.width;
            CGFloat py = plot.origin.y + (1.0 - (y - ymin) / (ymax - ymin)) * plot.size.height;
            if (i == 0) [path moveToPoint:NSMakePoint(px, py)];
            else [path lineToPoint:NSMakePoint(px, py)];
        }
        [path setLineWidth:1.3];
        [path setLineJoinStyle:NSLineJoinStyleRound];
        if (s.dashed) {
            CGFloat dash[] = {4.0, 3.0};
            [path setLineDash:dash count:2 phase:0];
        }
        [path stroke];
    }
    [NSGraphicsContext restoreGraphicsState];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    NSRect bounds = self.bounds;
    CGFloat W = bounds.size.width;
    CGFloat H = bounds.size.height;
    if (W < 80 || H < 80) return;

    NSDictionary *titleAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold], NSForegroundColorAttributeName: NVText()};
    NSDictionary *labelAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:10], NSForegroundColorAttributeName: NVSecondary()};
    NSDictionary *tickAttrs = @{NSFontAttributeName: [NSFont monospacedDigitSystemFontOfSize:9 weight:NSFontWeightRegular], NSForegroundColorAttributeName: NVSecondary()};

    [_title drawAtPoint:NSMakePoint(18, 13) withAttributes:titleAttrs];
    if (_yLabel.length) [_yLabel drawAtPoint:NSMakePoint(18, 33) withAttributes:labelAttrs];

    BOOL hasData = NO;
    double xmin = INFINITY, xmax = -INFINITY, ymin = INFINITY, ymax = -INFINITY;
    for (NVSeries *s in _series) {
        NSUInteger n = MIN(s.x.count, s.y.count);
        for (NSUInteger i = 0; i < n; i++) {
            double x = s.x[i].doubleValue;
            double y = s.y[i].doubleValue;
            if (!isfinite(x) || !isfinite(y)) continue;
            hasData = YES;
            xmin = MIN(xmin, x); xmax = MAX(xmax, x);
            ymin = MIN(ymin, y); ymax = MAX(ymax, y);
        }
    }

    if (!hasData) {
        NSDictionary *emptyAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:13], NSForegroundColorAttributeName: NVSecondary()};
        NSString *msg = @"Adjust a parameter to generate data";
        NSSize sz = [msg sizeWithAttributes:emptyAttrs];
        [msg drawAtPoint:NSMakePoint((W - sz.width) / 2.0, (H - sz.height) / 2.0) withAttributes:emptyAttrs];
        return;
    }

    if (xmax - xmin < 1e-9) { xmin -= 1; xmax += 1; }
    if (ymax - ymin < 1e-9) { ymin -= 1; ymax += 1; }
    if (ymin < 0.0 && ymin > -1e-9) ymin = 0.0;
    double xpad = (xmax - xmin) * 0.035;
    double ypad = (ymax - ymin) * 0.12;
    if (xmin >= 0.0 && xmin < xpad) {
        xmax += xpad;
    } else {
        xmin -= xpad;
        xmax += xpad;
    }
    if (ymin >= 0.0 && ymin < ypad) {
        ymax += ypad;
    } else {
        ymin -= ypad;
        ymax += ypad;
    }

    BOOL hasDetail = _detailSeries.count > 0;
    CGFloat detailBlock = hasDetail ? MIN(270.0, MAX(180.0, H * 0.46)) : 0.0;
    if (H - 100.0 - detailBlock < 150.0) detailBlock = MAX(0.0, H - 250.0);
    NSRect chart = NSMakeRect(64, 56, W - 82, H - 100 - detailBlock);

    NSColor *grid = [NSColor colorWithWhite:1.0 alpha:0.075];
    NSColor *axis = [NSColor colorWithWhite:1.0 alpha:0.18];
    int yTicks = 4;
    for (int i = 0; i <= yTicks; i++) {
        double v = ymin + (ymax - ymin) * (double)i / (double)yTicks;
        double py = chart.origin.y + chart.size.height * (1.0 - (double)i / (double)yTicks);
        [grid setStroke];
        NSBezierPath *line = [NSBezierPath bezierPath];
        [line moveToPoint:NSMakePoint(chart.origin.x, py)];
        [line lineToPoint:NSMakePoint(chart.origin.x + chart.size.width, py)];
        [line setLineWidth:1.0];
        [line stroke];
        NSString *label = [self tickString:v];
        NSSize sz = [label sizeWithAttributes:tickAttrs];
        [label drawAtPoint:NSMakePoint(chart.origin.x - sz.width - 8, py - sz.height / 2.0) withAttributes:tickAttrs];
    }
    int xTicks = 5;
    for (int i = 0; i <= xTicks; i++) {
        double v = xmin + (xmax - xmin) * (double)i / (double)xTicks;
        double px = chart.origin.x + chart.size.width * (double)i / (double)xTicks;
        [grid setStroke];
        NSBezierPath *line = [NSBezierPath bezierPath];
        [line moveToPoint:NSMakePoint(px, chart.origin.y)];
        [line lineToPoint:NSMakePoint(px, chart.origin.y + chart.size.height)];
        [line setLineWidth:1.0];
        [line stroke];
        NSString *label = [self tickString:v];
        NSSize sz = [label sizeWithAttributes:tickAttrs];
        [label drawAtPoint:NSMakePoint(px - sz.width / 2.0, chart.origin.y + chart.size.height + 5) withAttributes:tickAttrs];
    }

    [axis setStroke];
    NSBezierPath *frame = [NSBezierPath bezierPathWithRect:chart];
    [frame setLineWidth:1.0];
    [frame stroke];

    [NSGraphicsContext saveGraphicsState];
    NSBezierPath *clip = [NSBezierPath bezierPathWithRect:chart];
    [clip addClip];
    for (NVSeries *s in _series) {
        NSUInteger n = MIN(s.x.count, s.y.count);
        if (n == 0) continue;
        NSColor *col = s.color ?: NVAccent();
        [col setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
        for (NSUInteger i = 0; i < n; i++) {
            double x = s.x[i].doubleValue;
            double y = s.y[i].doubleValue;
            double px = chart.origin.x + (x - xmin) / (xmax - xmin) * chart.size.width;
            double py = chart.origin.y + (1.0 - (y - ymin) / (ymax - ymin)) * chart.size.height;
            if (i == 0) [path moveToPoint:NSMakePoint(px, py)];
            else [path lineToPoint:NSMakePoint(px, py)];
        }
        [path setLineWidth:1.9];
        [path setLineJoinStyle:NSLineJoinStyleRound];
        [path setLineCapStyle:NSLineCapStyleRound];
        if (s.dashed) {
            CGFloat dash[] = {4.0, 4.0};
            [path setLineDash:dash count:2 phase:0];
        }
        [path stroke];

        if (s.showsPoints && n <= 900) {
            [col setFill];
            for (NSUInteger i = 0; i < n; i++) {
                double x = s.x[i].doubleValue;
                double y = s.y[i].doubleValue;
                double px = chart.origin.x + (x - xmin) / (xmax - xmin) * chart.size.width;
                double py = chart.origin.y + (1.0 - (y - ymin) / (ymax - ymin)) * chart.size.height;
                NSBezierPath *dot = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(px - 1.25, py - 1.25, 2.5, 2.5)];
                [dot fill];
            }
        }
    }
    [NSGraphicsContext restoreGraphicsState];

    if (_xLabel.length) {
        NSSize sz = [_xLabel sizeWithAttributes:labelAttrs];
        [_xLabel drawAtPoint:NSMakePoint(chart.origin.x + (chart.size.width - sz.width) / 2.0, NSMaxY(chart) + 20) withAttributes:labelAttrs];
    }

    if (_showLegend && _series.count > 0) {
        CGFloat y = chart.origin.y + 8;
        CGFloat x = chart.origin.x + chart.size.width - 8;
        for (NVSeries *s in _series) {
            if (!s.showsInLegend) continue;
            NSString *label = s.label ?: @"";
            NSSize sz = [label sizeWithAttributes:labelAttrs];
            x = MAX(chart.origin.x + 8, x);
            CGFloat itemX = x - sz.width;
            [s.color ?: NVAccent() setStroke];
            NSBezierPath *line = [NSBezierPath bezierPath];
            [line moveToPoint:NSMakePoint(itemX - 20, y + 6)];
            [line lineToPoint:NSMakePoint(itemX - 5, y + 6)];
            [line setLineWidth:2.0];
            [line stroke];
            [label drawAtPoint:NSMakePoint(itemX, y) withAttributes:labelAttrs];
            y += 16;
        }
    }

    if (hasDetail) {
        [self.detailTitle drawAtPoint:NSMakePoint(64, NSMaxY(chart) + 40)
                       withAttributes:@{NSFontAttributeName: [NSFont systemFontOfSize:10 weight:NSFontWeightSemibold],
                                        NSForegroundColorAttributeName: NVSecondary()}];
        NSRect detailChart = NSMakeRect(64, NSMaxY(chart) + 58, W - 82, H - (NSMaxY(chart) + 58) - 28);
        [self drawDetailChart:detailChart];
        if (_detailXLabel.length) {
            NSSize sz = [_detailXLabel sizeWithAttributes:labelAttrs];
            [_detailXLabel drawAtPoint:NSMakePoint(detailChart.origin.x + (detailChart.size.width - sz.width) / 2.0, H - 18)
                        withAttributes:labelAttrs];
        }
    }
}
@end

#pragma mark - Sequence view

@implementation NVSequenceView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = NVPanel().CGColor;
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = YES;
    }
    return self;
}

- (BOOL)isFlipped { return YES; }

- (void)setSequence:(NVSequenceModel *)sequence {
    _sequence = sequence;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    CGFloat W = self.bounds.size.width;
    NSDictionary *titleAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold], NSForegroundColorAttributeName: NVText()};
    NSDictionary *labelAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:10], NSForegroundColorAttributeName: NVSecondary()};
    NSDictionary *trackAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:9 weight:NSFontWeightSemibold], NSForegroundColorAttributeName: NVSecondary()};
    NSDictionary *eventAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:9 weight:NSFontWeightMedium], NSForegroundColorAttributeName: [NSColor colorWithWhite:0.05 alpha:1.0]};

    [_sequence.title ?: @"Pulse sequence" drawAtPoint:NSMakePoint(18, 14) withAttributes:titleAttrs];

    NSRect chart = NSMakeRect(92, 56, W - 112, 132);
    NSArray *tracks = @[@"LASER", @"MW", @"READOUT"];
    NSArray *colors = @[NVGreen(), NVAmber(), NVAccent()];
    for (int i = 0; i < 3; i++) {
        CGFloat rowY = chart.origin.y + (CGFloat)i * 44;
        [tracks[i] drawAtPoint:NSMakePoint(18, rowY + 10) withAttributes:trackAttrs];
        [[NSColor colorWithWhite:1.0 alpha:0.04] setFill];
        NSBezierPath *row = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(chart.origin.x, rowY, chart.size.width, 30) xRadius:5 yRadius:5];
        [row fill];
    }

    if (_sequence && _sequence.duration > 0) {
        for (NVSequenceEvent *e in _sequence.events) {
            CGFloat rowY = chart.origin.y + (CGFloat)e.track * 44;
            CGFloat x = chart.origin.x + (CGFloat)(e.start / _sequence.duration) * chart.size.width;
            CGFloat w = MAX(2.0, (CGFloat)(e.duration / _sequence.duration) * chart.size.width);
            NSColor *col = colors[e.track];
            [col setFill];
            NSBezierPath *bar = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(x, rowY + 5, w, 20) xRadius:4 yRadius:4];
            [bar fill];
            if (w > 42 && e.label.length) {
                [e.label drawAtPoint:NSMakePoint(x + 5, rowY + 10) withAttributes:eventAttrs];
            }
        }
        for (int i = 0; i <= 4; i++) {
            CGFloat px = chart.origin.x + chart.size.width * (CGFloat)i / 4.0;
            NSString *t = [NSString stringWithFormat:@"%d%%", i * 25];
            NSSize sz = [t sizeWithAttributes:labelAttrs];
            [t drawAtPoint:NSMakePoint(px - sz.width / 2.0, chart.origin.y + 150) withAttributes:labelAttrs];
        }
        [@"time" drawAtPoint:NSMakePoint(chart.origin.x + chart.size.width / 2.0 - 12, chart.origin.y + 168) withAttributes:labelAttrs];

        NSMutableArray<NSString *> *tokens = [NSMutableArray array];
        NVSequenceEvent *groupStart = nil;
        NVSequenceEvent *lastEvent = nil;
        NSInteger repeat = 0;
        for (NVSequenceEvent *e in _sequence.events) {
            if (lastEvent && e.track == lastEvent.track && [e.label isEqualToString:lastEvent.label]) {
                repeat++;
                lastEvent = e;
                continue;
            }
            if (lastEvent) {
                NSString *token = repeat > 1
                    ? [NSString stringWithFormat:@"%ld × %@ (%.0f–%.0f ns)", (long)repeat, groupStart.label, groupStart.start, lastEvent.start + lastEvent.duration]
                    : [NSString stringWithFormat:@"%@ (%.0f–%.0f ns)", groupStart.label, groupStart.start, lastEvent.start + lastEvent.duration];
                [tokens addObject:token];
            }
            groupStart = e;
            lastEvent = e;
            repeat = 1;
        }
        if (lastEvent) {
            NSString *token = repeat > 1
                ? [NSString stringWithFormat:@"%ld × %@ (%.0f–%.0f ns)", (long)repeat, groupStart.label, groupStart.start, lastEvent.start + lastEvent.duration]
                : [NSString stringWithFormat:@"%@ (%.0f–%.0f ns)", groupStart.label, groupStart.start, lastEvent.start + lastEvent.duration];
            [tokens addObject:token];
        }
        NSString *total = [NSString stringWithFormat:@"Sequence length: %.0f ns", _sequence.duration];
        [total drawAtPoint:NSMakePoint(chart.origin.x, chart.origin.y + 194) withAttributes:labelAttrs];
        NSMutableParagraphStyle *timelineStyle = [[NSMutableParagraphStyle alloc] init];
        timelineStyle.lineSpacing = 3;
        NSDictionary *timelineAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:10],
                                        NSForegroundColorAttributeName: NVSecondary(),
                                        NSParagraphStyleAttributeName: timelineStyle};
        NSRect timelineRect = NSMakeRect(chart.origin.x, chart.origin.y + 214, chart.size.width, 64);
        [[tokens componentsJoinedByString:@"   ·   "] drawInRect:timelineRect withAttributes:timelineAttrs];
    } else {
        NSDictionary *emptyAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:13], NSForegroundColorAttributeName: NVSecondary()};
        [@"No sequence available" drawAtPoint:NSMakePoint(18, 120) withAttributes:emptyAttrs];
    }
}
@end

#pragma mark - Bloch sphere

@implementation NVBlochSphereView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = NVPanel().CGColor;
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = YES;
        _title = @"Qubit state";
        _theta = 0;
        _phi = 0;
        _vectorLength = 1.0;
    }
    return self;
}

- (BOOL)isFlipped { return YES; }

- (void)setTheta:(double)theta phi:(double)phi {
    [self setTheta:theta phi:phi length:1.0];
}

- (void)setTheta:(double)theta phi:(double)phi length:(double)length {
    _theta = theta;
    _phi = phi;
    _vectorLength = fmin(1.0, fmax(0.0, length));
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;
    NSDictionary *titleAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold], NSForegroundColorAttributeName: NVText()};
    NSDictionary *labelAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:11], NSForegroundColorAttributeName: NVSecondary()};
    [_title drawAtPoint:NSMakePoint(18, 14) withAttributes:titleAttrs];

    CGFloat cx = W / 2.0;
    CGFloat cy = H / 2.0 + 12;
    CGFloat R = MIN(W, H) * 0.30;
    NSRect sphereRect = NSMakeRect(cx - R, cy - R, 2 * R, 2 * R);
    NSGradient *gradient = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithSRGBRed:0.05 green:0.10 blue:0.17 alpha:0.9]
                                                         endingColor:[NSColor colorWithSRGBRed:0.10 green:0.20 blue:0.34 alpha:0.9]];
    [gradient drawInBezierPath:[NSBezierPath bezierPathWithOvalInRect:sphereRect] angle:-90];
    [[NSColor colorWithWhite:1 alpha:0.22] setStroke];
    NSBezierPath *outline = [NSBezierPath bezierPathWithOvalInRect:sphereRect];
    [outline setLineWidth:1.2];
    [outline stroke];

    [[NSColor colorWithWhite:1 alpha:0.16] setStroke];
    NSBezierPath *equator = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(cx - R, cy - R * 0.33, 2 * R, R * 0.66)];
    [equator setLineWidth:1.0];
    [equator stroke];
    NSBezierPath *meridian = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(cx - R * 0.33, cy - R, R * 0.66, 2 * R)];
    [meridian setLineWidth:1.0];
    [meridian stroke];

    [[NSColor colorWithWhite:1 alpha:0.30] setStroke];
    NSBezierPath *zAxis = [NSBezierPath bezierPath];
    [zAxis moveToPoint:NSMakePoint(cx, cy - R * 1.12)];
    [zAxis lineToPoint:NSMakePoint(cx, cy + R * 1.12)];
    [zAxis setLineWidth:1.0];
    [zAxis stroke];
    NSBezierPath *xAxis = [NSBezierPath bezierPath];
    [xAxis moveToPoint:NSMakePoint(cx - R * 0.92, cy + R * 0.28)];
    [xAxis lineToPoint:NSMakePoint(cx + R * 0.92, cy - R * 0.28)];
    [xAxis setLineWidth:1.0];
    [xAxis stroke];

    [@"|0⟩" drawAtPoint:NSMakePoint(cx - 10, cy - R * 1.25) withAttributes:labelAttrs];
    [@"|1⟩" drawAtPoint:NSMakePoint(cx - 10, cy + R * 1.05) withAttributes:labelAttrs];
    [@"|+⟩" drawAtPoint:NSMakePoint(cx + R * 0.92, cy - R * 0.30) withAttributes:labelAttrs];

    double st = sin(_theta) * _vectorLength;
    double x = st * cos(_phi);
    double y = st * sin(_phi);
    double z = cos(_theta) * _vectorLength;
    double px = cx + R * (x * 0.86 + y * 0.34);
    double py = cy - R * (z * 0.86 - y * 0.18);

    [NVAmber() setStroke];
    NSBezierPath *vector = [NSBezierPath bezierPath];
    [vector moveToPoint:NSMakePoint(cx, cy)];
    [vector lineToPoint:NSMakePoint(px, py)];
    [vector setLineWidth:3.0];
    [vector setLineCapStyle:NSLineCapStyleRound];
    [vector stroke];
    [NVAmber() setFill];
    NSBezierPath *tip = [NSBezierPath bezierPathWithOvalInRect:NSMakeRect(px - 5, py - 5, 10, 10)];
    [tip fill];

    double phiDeg = fmod(_phi * 180.0 / M_PI + 360.0, 360.0);
    NSString *angles = [NSString stringWithFormat:@"θ = %.1f°   φ = %.1f°   |r| = %.2f", _theta * 180.0 / M_PI, phiDeg, _vectorLength];
    NSSize sz = [angles sizeWithAttributes:labelAttrs];
    [angles drawAtPoint:NSMakePoint((W - sz.width) / 2.0, H - 32) withAttributes:labelAttrs];
}
@end

#pragma mark - Histogram

@implementation NVHistogramView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        self.wantsLayer = YES;
        self.layer.backgroundColor = NVPanel().CGColor;
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = YES;
        _title = @"Readout histogram";
        _counts0 = 0;
        _counts1 = 0;
    }
    return self;
}

- (BOOL)isFlipped { return YES; }

- (void)setCounts0:(NSInteger)c0 counts1:(NSInteger)c1 {
    _counts0 = c0;
    _counts1 = c1;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    CGFloat W = self.bounds.size.width;
    CGFloat H = self.bounds.size.height;
    NSDictionary *titleAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:14 weight:NSFontWeightSemibold], NSForegroundColorAttributeName: NVText()};
    NSDictionary *labelAttrs = @{NSFontAttributeName: [NSFont systemFontOfSize:12], NSForegroundColorAttributeName: NVSecondary()};
    NSDictionary *countAttrs = @{NSFontAttributeName: [NSFont monospacedDigitSystemFontOfSize:12 weight:NSFontWeightMedium], NSForegroundColorAttributeName: NVText()};
    [_title drawAtPoint:NSMakePoint(18, 14) withAttributes:titleAttrs];

    NSInteger total = MAX(1, _counts0 + _counts1);
    NSInteger maxC = MAX(1, MAX(_counts0, _counts1));
    NSRect chart = NSMakeRect(72, 62, W - 100, H - 120);
    [[NSColor colorWithWhite:1 alpha:0.06] setStroke];
    NSBezierPath *axis = [NSBezierPath bezierPath];
    [axis moveToPoint:NSMakePoint(chart.origin.x, chart.origin.y + chart.size.height)];
    [axis lineToPoint:NSMakePoint(chart.origin.x + chart.size.width, chart.origin.y + chart.size.height)];
    [axis setLineWidth:1.0];
    [axis stroke];

    CGFloat barW = MIN(100, chart.size.width * 0.22);
    CGFloat baseY = chart.origin.y + chart.size.height;
    CGFloat h0 = (_counts0 / (double)maxC) * (chart.size.height - 24);
    CGFloat h1 = (_counts1 / (double)maxC) * (chart.size.height - 24);
    CGFloat x0 = chart.origin.x + chart.size.width * 0.28 - barW / 2;
    CGFloat x1 = chart.origin.x + chart.size.width * 0.72 - barW / 2;

    [NVCyan() setFill];
    NSBezierPath *bar0 = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(x0, baseY - h0, barW, h0) xRadius:5 yRadius:5];
    [bar0 fill];
    [NVAmber() setFill];
    NSBezierPath *bar1 = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(x1, baseY - h1, barW, h1) xRadius:5 yRadius:5];
    [bar1 fill];

    NSString *c0 = [NSString stringWithFormat:@"%ld", (long)_counts0];
    NSString *c1 = [NSString stringWithFormat:@"%ld", (long)_counts1];
    NSSize s0 = [c0 sizeWithAttributes:countAttrs];
    NSSize s1 = [c1 sizeWithAttributes:countAttrs];
    [c0 drawAtPoint:NSMakePoint(x0 + (barW - s0.width) / 2, baseY - h0 - 22) withAttributes:countAttrs];
    [c1 drawAtPoint:NSMakePoint(x1 + (barW - s1.width) / 2, baseY - h1 - 22) withAttributes:countAttrs];

    NSString *l0 = [NSString stringWithFormat:@"|0⟩  %.1f%%", 100.0 * _counts0 / total];
    NSString *l1 = [NSString stringWithFormat:@"|1⟩  %.1f%%", 100.0 * _counts1 / total];
    NSSize z0 = [l0 sizeWithAttributes:labelAttrs];
    NSSize z1 = [l1 sizeWithAttributes:labelAttrs];
    [l0 drawAtPoint:NSMakePoint(x0 + (barW - z0.width) / 2, baseY + 12) withAttributes:labelAttrs];
    [l1 drawAtPoint:NSMakePoint(x1 + (barW - z1.width) / 2, baseY + 12) withAttributes:labelAttrs];

    [@"photon counts" drawAtPoint:NSMakePoint(18, H - 30) withAttributes:labelAttrs];
}
@end

#pragma mark - 3D NV model

static SCNVector3 V3(double x, double y, double z) { return SCNVector3Make(x, y, z); }
static SCNVector3 vAdd(SCNVector3 a, SCNVector3 b) { return V3(a.x + b.x, a.y + b.y, a.z + b.z); }
static SCNVector3 vSub(SCNVector3 a, SCNVector3 b) { return V3(a.x - b.x, a.y - b.y, a.z - b.z); }
static SCNVector3 vScale(SCNVector3 a, double s) { return V3(a.x * s, a.y * s, a.z * s); }
static double vDot(SCNVector3 a, SCNVector3 b) { return a.x * b.x + a.y * b.y + a.z * b.z; }
static SCNVector3 vCross(SCNVector3 a, SCNVector3 b) {
    return V3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x);
}
static double vLength(SCNVector3 a) { return sqrt(vDot(a, a)); }
static SCNVector3 vNormalize(SCNVector3 a) {
    double l = vLength(a);
    return l > 1e-9 ? vScale(a, 1.0 / l) : V3(0, 1, 0);
}

@implementation NV3DView {
    SCNNode *_fieldNode;
    SCNNode *_assembly;
    SCNNode *_lattice;
    SCNNode *_laserNode;
    SCNNode *_plNode;
    NSMutableArray<SCNNode *> *_nvAxes;
    SCNVector3 _nvDirection;
    SCNNode *_cameraNode;
    SCNNode *_targetNode;
}

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) [self setupScene];
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) [self setupScene];
    return self;
}

- (void)setupScene {
    self.scene = [SCNScene scene];
    self.backgroundColor = [NSColor colorWithSRGBRed:0.025 green:0.040 blue:0.060 alpha:1.0];
    self.allowsCameraControl = YES;
    self.autoenablesDefaultLighting = NO;
    self.antialiasingMode = SCNAntialiasingModeMultisampling4X;
    self.preferredFramesPerSecond = 60;
    self.jitteringEnabled = YES;
    self.playing = YES;

    _cameraNode = [SCNNode node];
    _cameraNode.camera = [SCNCamera camera];
    _cameraNode.camera.fieldOfView = 38;
    _cameraNode.camera.zNear = 0.01;
    _cameraNode.camera.zFar = 100;
    _cameraNode.position = V3(4.7, 3.4, 5.5);
    _targetNode = [SCNNode node];
    _targetNode.position = V3(0, 0.05, 0);
    [self.scene.rootNode addChildNode:_targetNode];
    SCNLookAtConstraint *look = [SCNLookAtConstraint lookAtConstraintWithTarget:_targetNode];
    look.gimbalLockEnabled = YES;
    _cameraNode.constraints = @[look];
    [self.scene.rootNode addChildNode:_cameraNode];
    self.pointOfView = _cameraNode;

    SCNNode *ambient = [SCNNode node];
    ambient.light = [SCNLight light];
    ambient.light.type = SCNLightTypeAmbient;
    ambient.light.color = [NSColor colorWithWhite:1 alpha:1];
    ambient.light.intensity = 110;
    [self.scene.rootNode addChildNode:ambient];

    SCNNode *key = [SCNNode node];
    key.light = [SCNLight light];
    key.light.type = SCNLightTypeOmni;
    key.light.color = [NSColor colorWithSRGBRed:1.0 green:0.92 blue:0.80 alpha:1];
    key.light.intensity = 480;
    key.position = V3(4.0, 5.0, 6.0);
    [self.scene.rootNode addChildNode:key];

    SCNNode *fill = [SCNNode node];
    fill.light = [SCNLight light];
    fill.light.type = SCNLightTypeOmni;
    fill.light.color = [NSColor colorWithSRGBRed:0.55 green:0.70 blue:1.0 alpha:1];
    fill.light.intensity = 210;
    fill.position = V3(-4.0, -2.0, 3.0);
    [self.scene.rootNode addChildNode:fill];

    _assembly = [SCNNode node];
    [self.scene.rootNode addChildNode:_assembly];

    _lattice = [SCNNode node];
    [_assembly addChildNode:_lattice];
    [self buildLattice];

    _fieldNode = [SCNNode node];
    [self.scene.rootNode addChildNode:_fieldNode];
    [self updateField:10 theta:54.7 phi:45 ensemble:NO];

    // A slow autorotation makes the lattice readable from all sides while the
    // field stays fixed in the laboratory frame and camera controls remain available.
    // (The action is applied after the first frame so the initial snapshot and
    // first paint are stable.)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self->_lattice runAction:[SCNAction repeatActionForever:[SCNAction rotateByX:0 y:2.0 * M_PI z:0 duration:180.0]]];
    });

}

static SCNMaterial *material(NSColor *color, double emission) {
    SCNMaterial *m = [SCNMaterial material];
    m.diffuse.contents = color;
    m.roughness.contents = @0.72;
    m.metalness.contents = @0.04;
    m.lightingModelName = SCNLightingModelPhysicallyBased;
    if (emission > 0) {
        m.emission.contents = [color colorWithAlphaComponent:emission];
    }
    return m;
}

static SCNNode *sphereAt(SCNVector3 pos, CGFloat radius, NSColor *color, double emission) {
    SCNSphere *sphere = [SCNSphere sphereWithRadius:radius];
    sphere.segmentCount = 18;
    sphere.firstMaterial = material(color, emission);
    SCNNode *node = [SCNNode nodeWithGeometry:sphere];
    node.position = pos;
    return node;
}

static void orientAlong(SCNNode *node, SCNVector3 delta, SCNVector3 midpoint) {
    double len = vLength(delta);
    if (len < 1e-9) return;
    SCNVector3 dir = vScale(delta, 1.0 / len);
    SCNVector3 up = V3(0, 1, 0);
    SCNVector3 axis = vCross(up, dir);
    double axisLen = vLength(axis);
    SCNMatrix4 rot;
    if (axisLen < 1e-8) {
        rot = vDot(up, dir) > 0 ? SCNMatrix4Identity : SCNMatrix4MakeRotation(M_PI, 1, 0, 0);
    } else {
        axis = vScale(axis, 1.0 / axisLen);
        rot = SCNMatrix4MakeRotation(acos(MAX(-1.0, MIN(1.0, vDot(up, dir)))), axis.x, axis.y, axis.z);
    }
    node.transform = SCNMatrix4Mult(SCNMatrix4MakeTranslation(midpoint.x, midpoint.y, midpoint.z), rot);
}

static SCNNode *bondBetween(SCNVector3 a, SCNVector3 b, CGFloat radius, NSColor *color, double emission) {
    SCNVector3 delta = vSub(b, a);
    double len = vLength(delta);
    if (len < 1e-9) return nil;
    SCNCylinder *cyl = [SCNCylinder cylinderWithRadius:radius height:len];
    cyl.radialSegmentCount = 10;
    cyl.firstMaterial = material(color, emission);
    SCNNode *node = [SCNNode nodeWithGeometry:cyl];
    orientAlong(node, delta, vScale(vAdd(a, b), 0.5));
    return node;
}

static SCNNode *textLabel(NSString *text, NSColor *color, CGFloat scale) {
    SCNText *geo = [SCNText textWithString:text extrusionDepth:0.01];
    geo.font = [NSFont boldSystemFontOfSize:1.0];
    geo.flatness = 0.2;
    geo.firstMaterial = material(color, 0.6);
    geo.firstMaterial.readsFromDepthBuffer = NO;
    SCNNode *node = [SCNNode nodeWithGeometry:geo];
    node.renderingOrder = 50;
    node.scale = V3(scale, scale, scale);
    SCNBillboardConstraint *billboard = [SCNBillboardConstraint billboardConstraint];
    billboard.freeAxes = SCNBillboardAxisAll;
    node.constraints = @[billboard];
    return node;
}

- (void)buildLattice {
    // Generate a 2x2x2 diamond-cubic supercell.
    NSMutableArray<NSValue *> *positions = [NSMutableArray array];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    double fcc[4][3] = {{0, 0, 0}, {0, 0.5, 0.5}, {0.5, 0, 0.5}, {0.5, 0.5, 0}};
    double basis[2][3] = {{0, 0, 0}, {0.25, 0.25, 0.25}};
    for (int ix = 0; ix < 2; ix++) {
        for (int iy = 0; iy < 2; iy++) {
            for (int iz = 0; iz < 2; iz++) {
                for (int f = 0; f < 4; f++) {
                    for (int b = 0; b < 2; b++) {
                        double x = ix + fcc[f][0] + basis[b][0];
                        double y = iy + fcc[f][1] + basis[b][1];
                        double z = iz + fcc[f][2] + basis[b][2];
                        if (x > 1.76 || y > 1.76 || z > 1.76) continue;
                        NSString *key = [NSString stringWithFormat:@"%.3f_%.3f_%.3f", x, y, z];
                        if ([seen containsObject:key]) continue;
                        [seen addObject:key];
                        [positions addObject:[NSValue valueWithSCNVector3:V3(x, y, z)]];
                    }
                }
            }
        }
    }

    SCNVector3 centroid = V3(0, 0, 0);
    for (NSValue *v in positions) {
        SCNVector3 p = v.SCNVector3Value;
        centroid = vAdd(centroid, p);
    }
    centroid = vScale(centroid, 1.0 / (double)positions.count);

    // Use the atom nearest the centroid as nitrogen; use its [111] neighbour as the vacancy.
    NSInteger defect = 0;
    double best = INFINITY;
    for (NSInteger i = 0; i < (NSInteger)positions.count; i++) {
        SCNVector3 p = positions[i].SCNVector3Value;
        double d = vLength(vSub(p, centroid));
        if (d < best) { best = d; defect = i; }
    }
    SCNVector3 defectPos = positions[defect].SCNVector3Value;
    NSInteger vacancy = -1;
    best = INFINITY;
    for (NSInteger i = 0; i < (NSInteger)positions.count; i++) {
        if (i == defect) continue;
        SCNVector3 p = positions[i].SCNVector3Value;
        SCNVector3 delta = vSub(p, defectPos);
        double d = vLength(delta);
        if (d < 0.46 && d > 0.3) {
            // Prefer a bond with all-positive components, giving a [111] NV axis.
            double score = d - 0.05 * (delta.x + delta.y + delta.z);
            if (score < best) { best = score; vacancy = i; }
        }
    }
    if (vacancy < 0) vacancy = (defect + 1) % positions.count;
    SCNVector3 vacancyPos = positions[vacancy].SCNVector3Value;
    _nvDirection = vNormalize(vSub(vacancyPos, defectPos));

    // Centre and scale the lattice.
    double scale = 1.55;
    NSMutableArray<NSValue *> *atoms = [NSMutableArray array];
    for (NSValue *v in positions) {
        SCNVector3 p = v.SCNVector3Value;
        [atoms addObject:[NSValue valueWithSCNVector3:vScale(vSub(p, centroid), scale)]];
    }
    SCNVector3 nPos = atoms[defect].SCNVector3Value;
    SCNVector3 vPos = atoms[vacancy].SCNVector3Value;

    NSColor *carbonColor = [NSColor colorWithSRGBRed:0.23 green:0.26 blue:0.33 alpha:1.0];
    NSColor *bondColor = [NSColor colorWithSRGBRed:0.40 green:0.44 blue:0.52 alpha:1.0];
    NSColor *nitrogenColor = [NSColor colorWithSRGBRed:0.25 green:0.45 blue:1.0 alpha:1.0];
    NSColor *vacancyColor = [NSColor colorWithSRGBRed:1.0 green:0.22 blue:0.58 alpha:0.55];
    NSColor *gold = [NSColor colorWithSRGBRed:1.0 green:0.78 blue:0.28 alpha:1.0];

    // Highlight the three closest carbon neighbours of the vacancy so the local
    // defect geometry remains readable inside the full diamond lattice.
    NSMutableArray<NSNumber *> *neighbourIndices = [NSMutableArray array];
    for (NSInteger pick = 0; pick < 3; pick++) {
        NSInteger bestIndex = -1;
        double bestDistance = INFINITY;
        for (NSInteger i = 0; i < (NSInteger)atoms.count; i++) {
            if (i == defect || i == vacancy || [neighbourIndices containsObject:@(i)]) continue;
            double d = vLength(vSub(atoms[i].SCNVector3Value, vPos));
            if (d < bestDistance) { bestDistance = d; bestIndex = i; }
        }
        if (bestIndex >= 0) [neighbourIndices addObject:@(bestIndex)];
    }
    for (NSInteger i = 0; i < (NSInteger)atoms.count; i++) {
        if (i == defect || i == vacancy || [neighbourIndices containsObject:@(i)]) continue;
        [_lattice addChildNode:sphereAt(atoms[i].SCNVector3Value, 0.075, carbonColor, 0.0)];
    }
    NSColor *neighbourColor = [NSColor colorWithSRGBRed:0.42 green:0.74 blue:1.0 alpha:1.0];
    for (NSNumber *index in neighbourIndices) {
        SCNVector3 p = atoms[index.integerValue].SCNVector3Value;
        [_lattice addChildNode:sphereAt(p, 0.088, neighbourColor, 0.10)];
    }
    [_lattice addChildNode:sphereAt(nPos, 0.115, nitrogenColor, 0.35)];
    SCNNode *vacancySphere = sphereAt(vPos, 0.105, vacancyColor, 0.7);
    vacancySphere.geometry.firstMaterial.transparency = 0.55;
    [_lattice addChildNode:vacancySphere];

    for (NSInteger i = 0; i < (NSInteger)atoms.count; i++) {
        for (NSInteger j = i + 1; j < (NSInteger)atoms.count; j++) {
            SCNVector3 a = atoms[i].SCNVector3Value;
            SCNVector3 b = atoms[j].SCNVector3Value;
            double d = vLength(vSub(a, b));
            if (d > 0.74) continue;
            NSColor *col = bondColor;
            double emission = 0.0;
            if (i == defect || j == defect) { col = nitrogenColor; emission = 0.25; }
            if (i == vacancy || j == vacancy) { col = [NSColor colorWithSRGBRed:0.95 green:0.35 blue:0.65 alpha:0.7]; emission = 0.3; }
            SCNNode *bond = bondBetween(a, b, 0.013, col, emission);
            if (bond) [_lattice addChildNode:bond];
        }
    }

    // NV axis and labels.
    SCNVector3 axisEnd = vAdd(nPos, vScale(_nvDirection, 2.2));
    SCNNode *axis = bondBetween(vSub(nPos, vScale(_nvDirection, 0.45)), axisEnd, 0.014, gold, 0.8);
    if (axis) [_lattice addChildNode:axis];
    SCNNode *nLabel = textLabel(@"N", nitrogenColor, 0.20);
    nLabel.position = vAdd(nPos, V3(0, 0.30, 0));
    [_lattice addChildNode:nLabel];
    SCNNode *vLabel = textLabel(@"V", [NSColor colorWithSRGBRed:1.0 green:0.45 blue:0.75 alpha:1.0], 0.20);
    vLabel.position = vAdd(vPos, V3(0, 0.30, 0));
    [_lattice addChildNode:vLabel];
    SCNNode *axisLabel = textLabel(@"[111]", gold, 0.17);
    axisLabel.position = axisEnd;
    [_lattice addChildNode:axisLabel];

    // Spin cloud around the vacancy.
    SCNNode *cloud = sphereAt(vPos, 0.17, [NSColor colorWithSRGBRed:0.35 green:0.75 blue:1.0 alpha:1.0], 0.12);
    cloud.geometry.firstMaterial.transparency = 0.06;
    cloud.geometry.firstMaterial.writesToDepthBuffer = NO;
    [_lattice addChildNode:cloud];
    SCNTorus *spinRing = [SCNTorus torusWithRingRadius:0.23 pipeRadius:0.009];
    spinRing.firstMaterial = material(NVMagenta(), 0.7);
    SCNNode *spinRingNode = [SCNNode nodeWithGeometry:spinRing];
    spinRingNode.position = vPos;
    spinRingNode.eulerAngles = V3(M_PI / 2.0, 0, 0);
    [_lattice addChildNode:spinRingNode];

    // Laser excitation beam.
    SCNCylinder *beamGeo = [SCNCylinder cylinderWithRadius:0.014 height:3.4];
    beamGeo.radialSegmentCount = 12;
    beamGeo.firstMaterial = material(NVGreen(), 0.28);
    beamGeo.firstMaterial.transparency = 0.22;
    _laserNode = [SCNNode nodeWithGeometry:beamGeo];
    _laserNode.position = V3(0, 2.0, 0);
    [_lattice addChildNode:_laserNode];
    SCNNode *beamLabel = textLabel(@"532 nm", NVGreen(), 0.14);
    beamLabel.position = V3(0.20, 2.65, 0);
    [_lattice addChildNode:beamLabel];

    // Photoluminescence glow.
    _plNode = sphereAt(vPos, 0.14, [NSColor colorWithSRGBRed:1.0 green:0.32 blue:0.22 alpha:1.0], 1.0);
    _plNode.geometry.firstMaterial.transparency = 0.55;
    [_lattice addChildNode:_plNode];
    SCNAction *glowUp = [SCNAction group:@[
        [SCNAction scaleTo:1.45 duration:0.55],
        [SCNAction fadeOpacityTo:0.35 duration:0.55]
    ]];
    SCNAction *glowDown = [SCNAction group:@[
        [SCNAction scaleTo:1.0 duration:0.55],
        [SCNAction fadeOpacityTo:0.85 duration:0.55]
    ]];
    [_plNode runAction:[SCNAction repeatActionForever:[SCNAction sequence:@[glowUp, glowDown]]]];
    SCNAction *laserPulse = [SCNAction repeatActionForever:[SCNAction sequence:@[
        [SCNAction fadeOpacityTo:0.12 duration:0.65],
        [SCNAction fadeOpacityTo:0.40 duration:0.65]
    ]]];
    [_laserNode runAction:laserPulse];

    // Microwave antenna: two generic loops.
    for (int i = 0; i < 2; i++) {
        SCNTorus *loop = [SCNTorus torusWithRingRadius:1.16 + i * 0.07 pipeRadius:0.012];
        loop.firstMaterial = material(NVAmber(), 0.35);
        SCNNode *loopNode = [SCNNode nodeWithGeometry:loop];
        loopNode.position = V3(0, -0.75 + i * 0.06, 0);
        loopNode.eulerAngles = V3(M_PI / 2.0, 0, 0);
        [_lattice addChildNode:loopNode];
    }
    SCNNode *mwLabel = textLabel(@"MW", NVAmber(), 0.16);
    mwLabel.position = V3(1.28, -0.82, 0);
    [_lattice addChildNode:mwLabel];

    // Four NV axes, shown in ensemble mode.
    _nvAxes = [NSMutableArray array];
    SCNVector3 n1 = _nvDirection;
    SCNVector3 ref = fabs(vDot(n1, V3(0, 1, 0))) > 0.95 ? V3(1, 0, 0) : V3(0, 1, 0);
    SCNVector3 u = vNormalize(vCross(n1, ref));
    SCNVector3 v = vCross(n1, u);
    double alpha = acos(-1.0 / 3.0);
    SCNVector3 n2 = vAdd(vScale(n1, cos(alpha)), vScale(u, sin(alpha)));
    SCNVector3 n3 = vAdd(vAdd(vScale(n1, cos(alpha)), vScale(u, cos(2.0 * M_PI / 3.0) * sin(alpha))), vScale(v, sin(2.0 * M_PI / 3.0) * sin(alpha)));
    SCNVector3 n4 = vAdd(vAdd(vScale(n1, cos(alpha)), vScale(u, cos(4.0 * M_PI / 3.0) * sin(alpha))), vScale(v, sin(4.0 * M_PI / 3.0) * sin(alpha)));
    NSArray<NSValue *> *axes = @[[NSValue valueWithSCNVector3:n1], [NSValue valueWithSCNVector3:n2],
                                 [NSValue valueWithSCNVector3:n3], [NSValue valueWithSCNVector3:n4]];
    NSArray *axisColors = @[gold, NVCyan(), NVMagenta(), NVAccent()];
    for (int i = 0; i < 4; i++) {
        SCNVector3 dir = axes[i].SCNVector3Value;
        SCNNode *node = bondBetween(V3(0, 0, 0), vScale(dir, 1.75), 0.009, axisColors[i], 0.25);
        node.name = [NSString stringWithFormat:@"nvAxis%d", i];
        [_lattice addChildNode:node];
        [_nvAxes addObject:node];
    }
    for (SCNNode *n in _nvAxes) n.hidden = YES;
    _nvAxes[0].hidden = NO;
}

- (void)updateField:(double)field theta:(double)theta phi:(double)phi ensemble:(BOOL)ensemble {
    _field = field;
    _theta = theta;
    _phi = phi;
    _ensemble = ensemble;
    if (!_fieldNode) return;

    for (SCNNode *n in [_fieldNode.childNodes copy]) [n removeFromParentNode];
    SCNVector3 z = vNormalize(_nvDirection);
    SCNVector3 ref = fabs(vDot(z, V3(0, 1, 0))) > 0.95 ? V3(1, 0, 0) : V3(0, 1, 0);
    SCNVector3 x = vNormalize(vCross(ref, z));
    SCNVector3 y = vCross(z, x);
    double t = theta * M_PI / 180.0;
    double p = phi * M_PI / 180.0;
    SCNVector3 dir = vAdd(vAdd(vScale(x, sin(t) * cos(p)), vScale(y, sin(t) * sin(p))), vScale(z, cos(t)));
    double length = 1.5 + 0.8 * fmin(1.0, field / 100.0);
    SCNVector3 tip = vScale(dir, length);
    SCNVector3 shaftEnd = vSub(tip, vScale(dir, 0.16));
    SCNNode *shaft = bondBetween(V3(0, 0, 0), shaftEnd, 0.016, NVAccent(), 0.55);
    if (shaft) [_fieldNode addChildNode:shaft];

    SCNCone *cone = [SCNCone coneWithTopRadius:0.0 bottomRadius:0.075 height:0.22];
    cone.radialSegmentCount = 16;
    cone.firstMaterial = material(NVAccent(), 0.65);
    SCNNode *coneNode = [SCNNode nodeWithGeometry:cone];
    orientAlong(coneNode, dir, vSub(tip, vScale(dir, 0.11)));
    [_fieldNode addChildNode:coneNode];

    SCNNode *label = textLabel([NSString stringWithFormat:@"B  %.1f mT", field], NVAccent(), 0.17);
    label.position = vAdd(tip, vScale(dir, 0.14));
    [_fieldNode addChildNode:label];

    for (NSInteger i = 0; i < (NSInteger)_nvAxes.count; i++) {
        _nvAxes[i].hidden = !(ensemble || i == 0);
    }
}
@end
