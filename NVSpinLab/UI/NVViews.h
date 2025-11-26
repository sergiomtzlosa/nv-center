#import <Cocoa/Cocoa.h>
#import <SceneKit/SceneKit.h>
#import "NVModels.h"

NS_ASSUME_NONNULL_BEGIN

@interface NVParameterControl : NSView
@property (nonatomic, strong) NVParameter *parameter;
@property (nonatomic, copy, nullable) void (^onChange)(double value);
- (instancetype)initWithParameter:(NVParameter *)parameter;
- (double)currentValue;
- (void)setCurrentValue:(double)value;
@end

@interface NVPlotView : NSView
@property (nonatomic, copy) NSArray<NVSeries *> *series;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *xLabel;
@property (nonatomic, copy) NSString *yLabel;
@property (nonatomic) BOOL showLegend;
@property (nonatomic, copy) NSArray<NVSeries *> *detailSeries;
@property (nonatomic, copy) NSString *detailTitle;
@property (nonatomic, copy) NSString *detailXLabel;
@property (nonatomic, copy) NSString *detailYLabel;
- (void)setSeries:(NSArray<NVSeries *> *)series
            title:(NSString *)title
           xLabel:(NSString *)xLabel
           yLabel:(NSString *)yLabel;
- (void)setDetailSeries:(NSArray<NVSeries *> *)detailSeries
                   title:(NSString *)title
                xLabel:(NSString *)xLabel
                yLabel:(NSString *)yLabel;
@end

@interface NVSequenceView : NSView
@property (nonatomic, strong, nullable) NVSequenceModel *sequence;
- (void)setSequence:(NVSequenceModel *)sequence;
@end

@interface NVBlochSphereView : NSView
@property (nonatomic, copy) NSString *title;
@property (nonatomic) double theta;
@property (nonatomic) double phi;
@property (nonatomic) double vectorLength;
- (void)setTheta:(double)theta phi:(double)phi;
- (void)setTheta:(double)theta phi:(double)phi length:(double)length;
@end

@interface NVHistogramView : NSView
@property (nonatomic, copy) NSString *title;
@property (nonatomic) NSInteger counts0;
@property (nonatomic) NSInteger counts1;
- (void)setCounts0:(NSInteger)c0 counts1:(NSInteger)c1;
@end

@interface NV3DView : SCNView
@property (nonatomic) double field;
@property (nonatomic) double theta;
@property (nonatomic) double phi;
@property (nonatomic) BOOL ensemble;
- (void)updateField:(double)field theta:(double)theta phi:(double)phi ensemble:(BOOL)ensemble;
@end

NS_ASSUME_NONNULL_END
