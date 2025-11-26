#import "NVModels.h"

@implementation NVSeries
- (instancetype)init {
    self = [super init];
    if (self) _showsInLegend = YES;
    return self;
}
+ (instancetype)seriesWithLabel:(NSString *)label color:(NSColor *)color {
    NVSeries *s = [NVSeries new];
    s.label = label;
    s.color = color;
    s.x = [NSMutableArray array];
    s.y = [NSMutableArray array];
    return s;
}
- (void)addX:(double)x y:(double)y {
    [self.x addObject:@(x)];
    [self.y addObject:@(y)];
}
@end

@implementation NVParameter
+ (instancetype)sliderWithKey:(NSString *)key
                        label:(NSString *)label
                         unit:(NSString *)unit
                          min:(double)min
                          max:(double)max
                        value:(double)value {
    NVParameter *p = [NVParameter new];
    p.key = key;
    p.label = label;
    p.unit = unit;
    p.kind = NVParameterKindSlider;
    p.minValue = min;
    p.maxValue = max;
    p.value = value;
    return p;
}
+ (instancetype)choiceWithKey:(NSString *)key
                        label:(NSString *)label
                      choices:(NSArray<NSString *> *)choices
                selectedIndex:(NSInteger)selectedIndex {
    NVParameter *p = [NVParameter new];
    p.key = key;
    p.label = label;
    p.unit = @"";
    p.kind = NVParameterKindChoice;
    p.choices = choices;
    p.selectedIndex = selectedIndex;
    p.minValue = 0;
    p.maxValue = MAX(0, (double)choices.count - 1);
    p.value = selectedIndex;
    return p;
}
@end

@implementation NVSequenceEvent
+ (instancetype)eventWithTrack:(NVTrackKind)track
                         start:(double)start
                      duration:(double)duration
                         label:(NSString *)label {
    NVSequenceEvent *e = [NVSequenceEvent new];
    e.track = track;
    e.start = start;
    e.duration = duration;
    e.label = label;
    return e;
}
@end

@implementation NVSequenceModel
+ (instancetype)sequenceWithTitle:(NSString *)title duration:(double)duration {
    NVSequenceModel *s = [NVSequenceModel new];
    s.title = title;
    s.duration = duration;
    s.events = [NSMutableArray array];
    return s;
}
- (void)addTrack:(NVTrackKind)track start:(double)start duration:(double)duration label:(NSString *)label {
    [self.events addObject:[NVSequenceEvent eventWithTrack:track start:start duration:duration label:label]];
}
@end

@implementation NVSimulationResult
- (instancetype)init {
    self = [super init];
    if (self) {
        _signalSeries = @[];
        _levelSeries = @[];
        _noiseSeries = @[];
        _t1Series = @[];
        _t2Series = @[];
        _sequence = [NVSequenceModel sequenceWithTitle:@"Sequence" duration:1.0];
        _summary = @"";
        _hardwareText = @"";
        _metrics = @{};
        _detailSeries = @[];
        _detailTitle = @"";
        _detailXLabel = @"";
        _detailYLabel = @"";
        _blochTheta = 0;
        _blochPhi = 0;
        _blochLength = 1.0;
        _histogram0 = 0;
        _histogram1 = 0;
        _fidelity = 0;
    }
    return self;
}
@end

@implementation NVExperiment
+ (NSArray<NVExperiment *> *)allExperiments {
    NSMutableArray *a = [NSMutableArray array];

    NVExperiment *odmr = [NVExperiment new];
    odmr.kind = NVExperimentKindODMR;
    odmr.title = @"ODMR & Zeeman";
    odmr.subtitle = @"Change the magnetic field, field angle or strain and the fluorescence trace updates immediately, revealing quantized spin levels, strain, hyperfine structure and magnetic-field splitting.";
    odmr.symbol = @"◎";
    odmr.parameters = @[
        [NVParameter sliderWithKey:@"field" label:@"Magnetic field" unit:@"mT" min:0 max:30 value:8],
        [NVParameter sliderWithKey:@"theta" label:@"Field angle θ" unit:@"°" min:0 max:90 value:0],
        [NVParameter sliderWithKey:@"phi" label:@"Field azimuth φ" unit:@"°" min:0 max:360 value:0],
        [NVParameter sliderWithKey:@"strain" label:@"Strain splitting E" unit:@"MHz" min:0 max:20 value:0],
        [NVParameter sliderWithKey:@"linewidth" label:@"ODMR linewidth" unit:@"MHz" min:1 max:30 value:6],
        [NVParameter sliderWithKey:@"contrast" label:@"PL contrast" unit:@"%" min:0.2 max:10 value:2.0],
        [NVParameter choiceWithKey:@"ensemble" label:@"Sample mode" choices:@[@"Single NV", @"NV ensemble"] selectedIndex:1],
        [NVParameter choiceWithKey:@"hyperfine" label:@"¹⁴N hyperfine" choices:@[@"Off", @"On"] selectedIndex:1]
    ];
    odmr.tabs = @[@"Signal", @"Levels", @"Sequence", @"3D"];
    [a addObject:odmr];

    NVExperiment *rabi = [NVExperiment new];
    rabi.kind = NVExperimentKindRabi;
    rabi.title = @"Rabi Oscillations";
    rabi.subtitle = @"Drive the |0⟩ ↔ |+1⟩ transition with a resonant microwave pulse and map the qubit population versus pulse duration.";
    rabi.symbol = @"∿";
    rabi.parameters = @[
        [NVParameter sliderWithKey:@"rabi" label:@"Rabi frequency Ω" unit:@"MHz" min:0.5 max:20 value:4.0],
        [NVParameter sliderWithKey:@"detuning" label:@"Microwave detuning Δ" unit:@"MHz" min:-10 max:10 value:0],
        [NVParameter sliderWithKey:@"maxTime" label:@"Maximum pulse" unit:@"ns" min:50 max:1200 value:450],
        [NVParameter sliderWithKey:@"t2rabi" label:@"Rabi coherence time" unit:@"ns" min:100 max:5000 value:900],
        [NVParameter sliderWithKey:@"contrast" label:@"PL contrast" unit:@"%" min:0.2 max:10 value:2.0],
        [NVParameter sliderWithKey:@"shots" label:@"Averaged shots" unit:@"" min:10 max:5000 value:500]
    ];
    rabi.tabs = @[@"Signal", @"Sequence", @"Bloch", @"3D"];
    [a addObject:rabi];

    NVExperiment *ramsey = [NVExperiment new];
    ramsey.kind = NVExperimentKindRamsey;
    ramsey.title = @"Ramsey Interferometry";
    ramsey.subtitle = @"Apply two π/2 pulses separated by a free-evolution time τ. Fringes versus detuning reveal the qubit phase and T₂*.";
    ramsey.symbol = @"⌁";
    ramsey.parameters = @[
        [NVParameter sliderWithKey:@"detuning" label:@"Detuning Δ" unit:@"MHz" min:0.05 max:20 value:2.0],
        [NVParameter sliderWithKey:@"maxTime" label:@"Maximum free time τ" unit:@"ns" min:50 max:4000 value:1400],
        [NVParameter sliderWithKey:@"t2star" label:@"Coherence time T₂*" unit:@"ns" min:50 max:5000 value:650],
        [NVParameter sliderWithKey:@"phase" label:@"Final pulse phase" unit:@"°" min:0 max:360 value:0],
        [NVParameter sliderWithKey:@"contrast" label:@"PL contrast" unit:@"%" min:0.2 max:10 value:2.0],
        [NVParameter choiceWithKey:@"envelope" label:@"Noise envelope" choices:@[@"Gaussian", @"Lorentzian"] selectedIndex:0]
    ];
    ramsey.tabs = @[@"Signal", @"Sequence", @"Bloch", @"3D"];
    [a addObject:ramsey];

    NVExperiment *echo = [NVExperiment new];
    echo.kind = NVExperimentKindEcho;
    echo.title = @"Spin Echo";
    echo.subtitle = @"A π pulse refocuses slow dephasing. Compare Hahn echo with Ramsey decay, then break the symmetry by making τ₁ ≠ τ₂.";
    echo.symbol = @"↺";
    echo.parameters = @[
        [NVParameter choiceWithKey:@"mode" label:@"Echo mode" choices:@[@"Symmetric (τ₁ = τ₂)", @"Asymmetric (τ₁ ≠ τ₂)"] selectedIndex:0],
        [NVParameter sliderWithKey:@"maxTime" label:@"Maximum free evolution" unit:@"ns" min:100 max:6000 value:1800],
        [NVParameter sliderWithKey:@"t2" label:@"Echo coherence T₂" unit:@"ns" min:100 max:12000 value:1400],
        [NVParameter sliderWithKey:@"t2star" label:@"Ramsey coherence T₂*" unit:@"ns" min:50 max:5000 value:500],
        [NVParameter sliderWithKey:@"pulseError" label:@"π-pulse error" unit:@"%" min:0 max:25 value:2],
        [NVParameter sliderWithKey:@"contrast" label:@"PL contrast" unit:@"%" min:0.2 max:10 value:2.0]
    ];
    echo.tabs = @[@"Signal", @"Sequence", @"3D"];
    [a addObject:echo];

    NVExperiment *cpmg = [NVExperiment new];
    cpmg.kind = NVExperimentKindCPMG;
    cpmg.title = @"CPMG & Decoupling";
    cpmg.subtitle = @"Repeat refocusing pulses to filter noise. Tune the pulse spacing to move the passband and sense an AC field.";
    cpmg.symbol = @"⋮⋮";
    cpmg.parameters = @[
        [NVParameter sliderWithKey:@"pulses" label:@"Number of π pulses N" unit:@"" min:1 max:64 value:8],
        [NVParameter sliderWithKey:@"tau" label:@"Half-spacing τ" unit:@"ns" min:20 max:1000 value:200],
        [NVParameter sliderWithKey:@"t2" label:@"Coherence T₂" unit:@"ns" min:100 max:12000 value:1800],
        [NVParameter sliderWithKey:@"alpha" label:@"Noise suppression exponent" unit:@"" min:0.2 max:1.0 value:0.67],
        [NVParameter sliderWithKey:@"acFreq" label:@"AC field frequency" unit:@"MHz" min:0.1 max:20 value:1.25],
        [NVParameter sliderWithKey:@"acAmp" label:@"AC field amplitude" unit:@"%" min:0 max:100 value:35],
        [NVParameter sliderWithKey:@"contrast" label:@"PL contrast" unit:@"%" min:0.2 max:10 value:2.0],
        [NVParameter choiceWithKey:@"sequence" label:@"Decoupling sequence" choices:@[@"CPMG", @"XY-8"] selectedIndex:0]
    ];
    cpmg.tabs = @[@"Signal", @"Noise", @"Sequence", @"3D"];
    [a addObject:cpmg];

    NVExperiment *qubit = [NVExperiment new];
    qubit.kind = NVExperimentKindQubit;
    qubit.title = @"Qubit Lab";
    qubit.subtitle = @"Initialize the electronic spin, apply single-qubit gates, and read out the state through spin-dependent photoluminescence.";
    qubit.symbol = @"◉";
    qubit.parameters = @[
        [NVParameter choiceWithKey:@"gate" label:@"Quantum gate" choices:@[@"X (π)", @"Y (π)", @"Z (phase)", @"H", @"Rx(θ)", @"Ry(θ)"] selectedIndex:3],
        [NVParameter sliderWithKey:@"angle" label:@"Rotation angle (Rx/Ry)" unit:@"°" min:0 max:360 value:90],
        [NVParameter sliderWithKey:@"initEff" label:@"Initialization fidelity" unit:@"%" min:50 max:100 value:92],
        [NVParameter sliderWithKey:@"readoutTime" label:@"Readout integration" unit:@"ns" min:50 max:1000 value:300],
        [NVParameter sliderWithKey:@"shots" label:@"Readout shots" unit:@"" min:100 max:10000 value:1000],
        [NVParameter sliderWithKey:@"contrast" label:@"Readout contrast" unit:@"%" min:0.2 max:10 value:2.0]
    ];
    qubit.tabs = @[@"Bloch", @"Readout", @"Sequence", @"3D"];
    [a addObject:qubit];

    NVExperiment *relax = [NVExperiment new];
    relax.kind = NVExperimentKindRelaxation;
    relax.title = @"Coherence & Relaxation";
    relax.subtitle = @"Measure energy relaxation (T₁), Ramsey dephasing (T₂*) and echo coherence (T₂) from their characteristic decays.";
    relax.symbol = @"⏱";
    relax.parameters = @[
        [NVParameter sliderWithKey:@"t1" label:@"Relaxation time T₁" unit:@"µs" min:1 max:5000 value:850],
        [NVParameter sliderWithKey:@"t2star" label:@"Dephasing time T₂*" unit:@"ns" min:50 max:5000 value:550],
        [NVParameter sliderWithKey:@"t2" label:@"Echo coherence T₂" unit:@"ns" min:100 max:12000 value:1500],
        [NVParameter sliderWithKey:@"maxTime" label:@"Maximum measurement time" unit:@"µs" min:10 max:5000 value:2500],
        [NVParameter sliderWithKey:@"contrast" label:@"PL contrast" unit:@"%" min:0.2 max:10 value:2.0]
    ];
    relax.tabs = @[@"T1", @"T2", @"Sequence", @"3D"];
    [a addObject:relax];

    NVExperiment *align = [NVExperiment new];
    align.kind = NVExperimentKindAlignment;
    align.title = @"System Alignment";
    align.subtitle = @"Explore a simulated optical and electronic chain. Adjust beam overlap, focus, microwave coupling, laser power and detector gain; the response curves and current operating point update live. No hardware is connected.";
    align.symbol = @"⚙";
    align.parameters = @[
        [NVParameter sliderWithKey:@"overlap" label:@"Beam overlap" unit:@"%" min:0 max:100 value:82],
        [NVParameter sliderWithKey:@"focus" label:@"Objective focus" unit:@"%" min:0 max:100 value:76],
        [NVParameter sliderWithKey:@"coupling" label:@"MW antenna coupling" unit:@"%" min:0 max:100 value:72],
        [NVParameter sliderWithKey:@"laserPower" label:@"Laser power" unit:@"mW" min:0.1 max:5.0 value:2.5],
        [NVParameter sliderWithKey:@"gain" label:@"Detector gain" unit:@"%" min:1 max:100 value:55]
    ];
    align.tabs = @[@"Signal", @"Hardware", @"3D"];
    [a addObject:align];

    NVExperiment *explorer = [NVExperiment new];
    explorer.kind = NVExperimentKindExplorer;
    explorer.title = @"NV Center 3D";
    explorer.subtitle = @"Explore the diamond lattice, the nitrogen-vacancy defect, the ⟨111⟩ axis, spin density, laser excitation and magnetic field geometry.";
    explorer.symbol = @"◇";
    explorer.parameters = @[
        [NVParameter sliderWithKey:@"field" label:@"Magnetic field" unit:@"mT" min:0 max:100 value:10],
        [NVParameter sliderWithKey:@"theta" label:@"Field angle θ" unit:@"°" min:0 max:180 value:54.7],
        [NVParameter sliderWithKey:@"phi" label:@"Field azimuth φ" unit:@"°" min:0 max:360 value:45],
        [NVParameter choiceWithKey:@"ensemble" label:@"Orientation view" choices:@[@"Single NV axis", @"Four ⟨111⟩ axes"] selectedIndex:0]
    ];
    explorer.tabs = @[@"3D", @"Levels", @"Hardware"];
    [a addObject:explorer];

    return a;
}

- (nullable NVParameter *)parameterForKey:(NSString *)key {
    for (NVParameter *p in self.parameters) {
        if ([p.key isEqualToString:key]) return p;
    }
    return nil;
}
@end
