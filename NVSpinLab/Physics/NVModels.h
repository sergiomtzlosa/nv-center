#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, NVExperimentKind) {
    NVExperimentKindODMR = 0,
    NVExperimentKindRabi,
    NVExperimentKindRamsey,
    NVExperimentKindEcho,
    NVExperimentKindCPMG,
    NVExperimentKindQubit,
    NVExperimentKindRelaxation,
    NVExperimentKindAlignment,
    NVExperimentKindExplorer
};

typedef NS_ENUM(NSInteger, NVParameterKind) {
    NVParameterKindSlider = 0,
    NVParameterKindChoice
};

typedef NS_ENUM(NSInteger, NVTrackKind) {
    NVTrackLaser = 0,
    NVTrackMW,
    NVTrackReadout
};

@interface NVSeries : NSObject
@property (nonatomic, copy) NSString *label;
@property (nonatomic, strong) NSColor *color;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *x;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *y;
@property (nonatomic) BOOL dashed;
@property (nonatomic) BOOL showsPoints;
@property (nonatomic) BOOL showsInLegend;

+ (instancetype)seriesWithLabel:(NSString *)label color:(NSColor *)color;
- (void)addX:(double)x y:(double)y;
@end

@interface NVParameter : NSObject
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSString *unit;
@property (nonatomic) NVParameterKind kind;
@property (nonatomic) double minValue;
@property (nonatomic) double maxValue;
@property (nonatomic) double value;
@property (nonatomic, copy, nullable) NSArray<NSString *> *choices;
@property (nonatomic) NSInteger selectedIndex;
@property (nonatomic) BOOL logarithmic;

+ (instancetype)sliderWithKey:(NSString *)key
                        label:(NSString *)label
                         unit:(NSString *)unit
                          min:(double)min
                          max:(double)max
                        value:(double)value;
+ (instancetype)choiceWithKey:(NSString *)key
                        label:(NSString *)label
                      choices:(NSArray<NSString *> *)choices
                selectedIndex:(NSInteger)selectedIndex;
@end

@interface NVSequenceEvent : NSObject
@property (nonatomic) NVTrackKind track;
@property (nonatomic) double start;
@property (nonatomic) double duration;
@property (nonatomic, copy) NSString *label;

+ (instancetype)eventWithTrack:(NVTrackKind)track
                         start:(double)start
                      duration:(double)duration
                         label:(NSString *)label;
@end

@interface NVSequenceModel : NSObject
@property (nonatomic, strong) NSMutableArray<NVSequenceEvent *> *events;
@property (nonatomic) double duration;
@property (nonatomic, copy) NSString *title;

+ (instancetype)sequenceWithTitle:(NSString *)title duration:(double)duration;
- (void)addTrack:(NVTrackKind)track start:(double)start duration:(double)duration label:(NSString *)label;
@end

@interface NVSimulationResult : NSObject
@property (nonatomic, strong) NSArray<NVSeries *> *signalSeries;
@property (nonatomic, strong) NSArray<NVSeries *> *levelSeries;
@property (nonatomic, strong) NSArray<NVSeries *> *noiseSeries;
@property (nonatomic, strong) NSArray<NVSeries *> *t1Series;
@property (nonatomic, strong) NSArray<NVSeries *> *t2Series;
@property (nonatomic, strong) NVSequenceModel *sequence;
@property (nonatomic, copy) NSString *summary;
@property (nonatomic, copy) NSString *hardwareText;
@property (nonatomic) double blochTheta;
@property (nonatomic) double blochPhi;
@property (nonatomic) double blochLength;
@property (nonatomic) NSInteger histogram0;
@property (nonatomic) NSInteger histogram1;
@property (nonatomic) double fidelity;
@property (nonatomic, strong) NSDictionary<NSString *, NSNumber *> *metrics;
@property (nonatomic, strong) NSArray<NVSeries *> *detailSeries;
@property (nonatomic, copy) NSString *detailTitle;
@property (nonatomic, copy) NSString *detailXLabel;
@property (nonatomic, copy) NSString *detailYLabel;
@end

@interface NVExperiment : NSObject
@property (nonatomic) NVExperimentKind kind;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, copy) NSString *symbol;
@property (nonatomic, strong) NSArray<NVParameter *> *parameters;
@property (nonatomic, strong) NSArray<NSString *> *tabs;

+ (NSArray<NVExperiment *> *)allExperiments;
- (nullable NVParameter *)parameterForKey:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
