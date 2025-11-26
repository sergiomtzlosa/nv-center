#import "NVPhysics.h"
#define ACCELERATE_NEW_LAPACK 1
#import <Accelerate/Accelerate.h>
#include <complex.h>
#import <math.h>

const double NVD_MHz = 2870.0;
const double NVGamma_MHzPerG = 2.802;
const double NVHyperfine_MHz = 2.16;
const double NVZeroFieldSplittingGHz = 2.870;

static uint64_t gRngState = 0x123456789abcdefULL;

static void seedRng(uint64_t s) { gRngState = s ? s : 1; }

static uint64_t xorshift64(void) {
    uint64_t x = gRngState;
    x ^= x >> 12;
    x ^= x << 25;
    x ^= x >> 27;
    gRngState = x;
    return x * 2685821657736338717ULL;
}

static double uniform01(void) {
    return (double)(xorshift64() >> 11) * (1.0 / 9007199254740992.0);
}

static double gaussianNoise(void) {
    double u1 = fmax(uniform01(), 1e-12);
    double u2 = uniform01();
    return sqrt(-2.0 * log(u1)) * cos(2.0 * M_PI * u2);
}


static double noiseScale(NSDictionary<NSString *, NSNumber *> *p) {
    return p[@"ideal"].integerValue == 1 ? 0.0 : 1.0;
}

static NSColor *C(double r, double g, double b) {
    return [NSColor colorWithSRGBRed:r green:g blue:b alpha:1.0];
}

static NSColor *Cyan(void) { return C(0.24, 0.82, 0.78); }
static NSColor *Amber(void) { return C(0.95, 0.68, 0.22); }
static NSColor *Magenta(void) { return C(0.95, 0.35, 0.58); }
static NSColor *Green(void) { return C(0.45, 0.90, 0.55); }

NVMat3 NVMat3Zero(void) {
    NVMat3 m;
    memset(&m, 0, sizeof(m));
    return m;
}

NVMat3 NVMat3Identity(void) {
    NVMat3 m = NVMat3Zero();
    m.m[0].re = m.m[4].re = m.m[8].re = 1.0;
    return m;
}

NVMat3 NVMat3Hamiltonian(double BxG, double ByG, double BzG, double E_MHz) {
    NVMat3 h = NVMat3Zero();
    double D = NVD_MHz;
    double bz = NVGamma_MHzPerG * BzG;
    double offRe = NVGamma_MHzPerG * BxG / sqrt(2.0);
    double offIm = -NVGamma_MHzPerG * ByG / sqrt(2.0);

    h.m[0].re = D + bz;
    h.m[4].re = 0.0;
    h.m[8].re = D - bz;

    h.m[0 * 3 + 1] = (NVComplex){offRe, offIm};
    h.m[1 * 3 + 0] = (NVComplex){offRe, -offIm};
    h.m[1 * 3 + 2] = (NVComplex){offRe, offIm};
    h.m[2 * 3 + 1] = (NVComplex){offRe, -offIm};
    h.m[0 * 3 + 2] = (NVComplex){E_MHz, 0.0};
    h.m[2 * 3 + 0] = (NVComplex){E_MHz, 0.0};
    return h;
}

void NVMat3Diagonalize(NVMat3 H, double eigenvalues[_Nonnull 3], NVMat3 * _Nullable eigenvectors) {
    __LAPACK_double_complex a[9];
    for (int col = 0; col < 3; col++) {
        for (int row = 0; row < 3; row++) {
            a[col * 3 + row] = CMPLX(H.m[row * 3 + col].re, H.m[row * 3 + col].im);
        }
    }
    char jobz = 'V';
    char uplo = 'U';
    __LAPACK_int n = 3;
    __LAPACK_int lda = 3;
    __LAPACK_int lwork = 64;
    __LAPACK_int info = 0;
    double w[3];
    double rwork[9];
    __LAPACK_double_complex work[64];
    zheev_(&jobz, &uplo, &n, a, &lda, w, work, &lwork, rwork, &info);
    for (int i = 0; i < 3; i++) eigenvalues[i] = info == 0 ? w[i] : 0.0;
    if (eigenvectors) {
        for (int col = 0; col < 3; col++) {
            for (int row = 0; row < 3; row++) {
                eigenvectors->m[row * 3 + col].re = creal(a[col * 3 + row]);
                eigenvectors->m[row * 3 + col].im = cimag(a[col * 3 + row]);
            }
        }
    }
}

static NVComplex cAdd(NVComplex a, NVComplex b) { return (NVComplex){a.re + b.re, a.im + b.im}; }
static NVComplex cMul(NVComplex a, NVComplex b) { return (NVComplex){a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re}; }
static NVComplex cConj(NVComplex a) { return (NVComplex){a.re, -a.im}; }
static double cAbs2(NVComplex a) { return a.re * a.re + a.im * a.im; }

static double transitionStrength(NVMat3 v, int i, int j) {
    // <i|Sx|j> and <i|Sy|j> in the {|+1>,|0>,|-1>} basis.
    NVComplex sx = {0, 0};
    NVComplex sy = {0, 0};
    const double s = 1.0 / sqrt(2.0);
    NVComplex sxi = {s, 0};
    NVComplex syi = {0, -s};

    // Sx has nonzero (0,1),(1,0),(1,2),(2,1).
    sx = cAdd(sx, cMul(cConj(v.m[0 * 3 + i]), cMul(sxi, v.m[1 * 3 + j])));
    sx = cAdd(sx, cMul(cConj(v.m[1 * 3 + i]), cMul(sxi, v.m[0 * 3 + j])));
    sx = cAdd(sx, cMul(cConj(v.m[1 * 3 + i]), cMul(sxi, v.m[2 * 3 + j])));
    sx = cAdd(sx, cMul(cConj(v.m[2 * 3 + i]), cMul(sxi, v.m[1 * 3 + j])));

    // Sy has the same positions with +/- i/sqrt(2).
    sy = cAdd(sy, cMul(cConj(v.m[0 * 3 + i]), cMul(syi, v.m[1 * 3 + j])));
    sy = cAdd(sy, cMul(cConj(v.m[1 * 3 + i]), cMul((NVComplex){0, s}, v.m[0 * 3 + j])));
    sy = cAdd(sy, cMul(cConj(v.m[1 * 3 + i]), cMul(syi, v.m[2 * 3 + j])));
    sy = cAdd(sy, cMul(cConj(v.m[2 * 3 + i]), cMul((NVComplex){0, s}, v.m[1 * 3 + j])));

    return cAbs2(sx) + cAbs2(sy);
}

double NVRabiPopulation(double omegaMHz, double detuningMHz, double timeNs) {
    if (omegaMHz <= 0.0) return 0.0;
    double gen = sqrt(omegaMHz * omegaMHz + detuningMHz * detuningMHz);
    double phase = M_PI * gen * timeNs / 1000.0;
    double s = sin(phase);
    return (omegaMHz * omegaMHz / (gen * gen)) * s * s;
}

double NVRamseyPopulation(double detuningMHz, double t2starNs, double timeNs, double phaseRad) {
    double env = exp(-pow(timeNs / t2starNs, 2.0));
    double phase = 2.0 * M_PI * detuningMHz * timeNs / 1000.0 + phaseRad;
    return 0.5 + 0.5 * cos(phase) * env;
}

double NVEchoCoherence(double tau1Ns, double tau2Ns, double t2Ns, double t2starNs) {
    double total = tau1Ns + tau2Ns;
    double slow = exp(-pow((tau1Ns - tau2Ns) / t2starNs, 2.0));
    double dynamic = exp(-pow(total / t2Ns, 2.0));
    return slow * dynamic;
}

double NVCpmgFilter(double frequencyMHz, double tauNs, NSInteger pulses) {
    if (pulses < 1 || tauNs <= 0.0) return 0.0;
    double total = 2.0 * (double)pulses * tauNs;
    const int steps = 2000;
    double dt = total / (double)steps;
    double real = 0.0;
    double imag = 0.0;
    for (int k = 0; k < steps; k++) {
        double t = ((double)k + 0.5) * dt;
        double sign = 1.0;
        for (NSInteger p = 0; p < pulses; p++) {
            double pulseTime = (2.0 * (double)p + 1.0) * tauNs;
            if (t > pulseTime) sign = -sign;
        }
        double phase = 2.0 * M_PI * frequencyMHz * t / 1000.0;
        real += sign * cos(phase) * dt;
        imag += sign * sin(phase) * dt;
    }
    double reNorm = real / total;
    double imNorm = imag / total;
    return reNorm * reNorm + imNorm * imNorm;
}

static NSString *formatGHz(double mhz) {
    return [NSString stringWithFormat:@"%.4f", mhz / 1000.0];
}

typedef struct {
    double frequency;
    double weight;
} NVLine;

static void addHyperfineLines(NSMutableArray<NSValue *> *lineValues,
                              double frequency,
                              double weight,
                              BOOL hyperfine) {
    if (hyperfine) {
        for (int mI = -1; mI <= 1; mI++) {
            NVLine line = {frequency + (double)mI * NVHyperfine_MHz, weight / 3.0};
            [lineValues addObject:[NSValue valueWithBytes:&line objCType:@encode(NVLine)]];
        }
    } else {
        NVLine line = {frequency, weight};
        [lineValues addObject:[NSValue valueWithBytes:&line objCType:@encode(NVLine)]];
    }
}

static NSArray<NSDictionary *> *groupedLines(NSArray<NSValue *> *lineValues) {
    NSMutableArray<NSValue *> *sorted = [lineValues mutableCopy];
    [sorted sortUsingComparator:^NSComparisonResult(NSValue *a, NSValue *b) {
        NVLine la, lb;
        [a getValue:&la];
        [b getValue:&lb];
        if (la.frequency < lb.frequency) return NSOrderedAscending;
        if (la.frequency > lb.frequency) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    NSMutableArray<NSDictionary *> *groups = [NSMutableArray array];
    for (NSValue *v in sorted) {
        NVLine line;
        [v getValue:&line];
        if (line.weight < 0.012) continue;
        NSMutableDictionary *last = (NSMutableDictionary *)groups.lastObject;
        if (last && fabs(line.frequency - [last[@"freq"] doubleValue]) < 0.6) {
            double oldF = [last[@"freq"] doubleValue];
            double oldW = [last[@"weight"] doubleValue];
            double nw = oldW + line.weight;
            last[@"freq"] = @((oldF * oldW + line.frequency * line.weight) / nw);
            last[@"weight"] = @(nw);
        } else {
            [groups addObject:[@{@"freq": @(line.frequency), @"weight": @(line.weight)} mutableCopy]];
        }
    }
    return groups;
}

static NSArray<NVSeries *> *buildLevelSeries(BOOL ensemble,
                                                   double maxField,
                                                   double thetaDeg,
                                                   double phiDeg,
                                                   double strain,
                                                   int points) {
    double axes[4][3] = {
        {0, 0, 1},
        {sqrt(8.0 / 9.0), 0, -1.0 / 3.0},
        {-sqrt(2.0 / 9.0), sqrt(2.0 / 3.0), -1.0 / 3.0},
        {-sqrt(2.0 / 9.0), -sqrt(2.0 / 3.0), -1.0 / 3.0}
    };
    double theta = thetaDeg * M_PI / 180.0;
    double phi = phiDeg * M_PI / 180.0;
    double ux = sin(theta) * cos(phi);
    double uy = sin(theta) * sin(phi);
    double uz = cos(theta);
    int axisCount = ensemble ? 4 : 1;
    NSArray<NSColor *> *axisColors = @[Cyan(), Amber(), Magenta(), Green()];
    NSArray<NSColor *> *singleColors = @[Amber(), Cyan(), Magenta()];
    NSMutableArray<NVSeries *> *result = [NSMutableArray array];
    double topField = fmax(1.0, maxField);
    if (points < 2) points = 2;
    for (int o = 0; o < axisCount; o++) {
        double nx = axes[o][0], ny = axes[o][1], nz = axes[o][2];
        double dot = ux * nx + uy * ny + uz * nz;
        NSColor *base = axisColors[o % 4];
        NVSeries *mPlus = [NVSeries seriesWithLabel:(ensemble
            ? [NSString stringWithFormat:@"axis %d", o + 1] : @"m_s = +1")
                                             color:(ensemble ? base : singleColors[0])];
        NVSeries *mZero = [NVSeries seriesWithLabel:(ensemble
            ? [NSString stringWithFormat:@"axis %d · mₛ=0", o + 1] : @"m_s = 0")
                                             color:(ensemble ? [base blendedColorWithFraction:0.22 ofColor:[NSColor whiteColor]] : singleColors[1])];
        NVSeries *mMinus = [NVSeries seriesWithLabel:(ensemble
            ? [NSString stringWithFormat:@"axis %d · mₛ=−1", o + 1] : @"m_s = -1")
                                              color:(ensemble ? [base blendedColorWithFraction:0.26 ofColor:[NSColor blackColor]] : singleColors[2])];
        if (ensemble) {
            // One legend entry per orientation keeps the four-axis view readable.
            mZero.showsInLegend = NO;
            mMinus.showsInLegend = NO;
        }
        for (int k = 0; k < points; k++) {
            double bmT = topField * (double)k / (double)(points - 1);
            double bg = bmT * 10.0;
            double axial = bg * dot;
            double transverse = sqrt(fmax(0.0, bg * bg - axial * axial));
            double e[3];
            NVMat3 v;
            NVMat3Diagonalize(NVMat3Hamiltonian(transverse, 0.0, axial, strain), e, &v);
            double sz[3];
            int idx[3] = {0, 1, 2};
            for (int i = 0; i < 3; i++) sz[i] = cAbs2(v.m[0 * 3 + i]) - cAbs2(v.m[2 * 3 + i]);
            for (int i = 0; i < 3; i++) {
                for (int j = i + 1; j < 3; j++) {
                    if (sz[idx[j]] > sz[idx[i]]) {
                        int t = idx[i]; idx[i] = idx[j]; idx[j] = t;
                    }
                }
            }
            [mPlus addX:bmT y:e[idx[0]] / 1000.0];
            [mZero addX:bmT y:e[idx[1]] / 1000.0];
            [mMinus addX:bmT y:e[idx[2]] / 1000.0];
        }
        [result addObjectsFromArray:@[mPlus, mZero, mMinus]];
    }
    return result;
}

static NVSimulationResult *runODMR(NSDictionary<NSString *, NSNumber *> *p) {
    NVSimulationResult *r = [NVSimulationResult new];
    seedRng(0x51A7ULL);
    double field = MAX(0.0, p[@"field"].doubleValue);
    double theta = p[@"theta"].doubleValue * M_PI / 180.0;
    double phi = p[@"phi"].doubleValue * M_PI / 180.0;
    double strain = p[@"strain"].doubleValue;
    double linewidth = MAX(0.5, p[@"linewidth"].doubleValue);
    double contrast = p[@"contrast"].doubleValue / 100.0;
    BOOL ensemble = p[@"ensemble"].integerValue == 1;
    BOOL hyperfine = p[@"hyperfine"].integerValue == 1;

    double Bg = field * 10.0;
    double bLab[3] = {Bg * sin(theta) * cos(phi), Bg * sin(theta) * sin(phi), Bg * cos(theta)};

    double axes[4][3] = {
        {0, 0, 1},
        {sqrt(8.0 / 9.0), 0, -1.0 / 3.0},
        {-sqrt(2.0 / 9.0), sqrt(2.0 / 3.0), -1.0 / 3.0},
        {-sqrt(2.0 / 9.0), -sqrt(2.0 / 3.0), -1.0 / 3.0}
    };
    int axisCount = ensemble ? 4 : 1;
    NSMutableArray<NSValue *> *lines = [NSMutableArray array];
    double strongestFrequency = 0.0;
    double strongestWeight = 0.0;

    for (int o = 0; o < axisCount; o++) {
        double nx = axes[o][0], ny = axes[o][1], nz = axes[o][2];
        double axial = bLab[0] * nx + bLab[1] * ny + bLab[2] * nz;
        double transverse = sqrt(fmax(0.0, Bg * Bg - axial * axial));
        double e[3];
        NVMat3 v;
        NVMat3 h = NVMat3Hamiltonian(transverse, 0.0, axial, strain);
        NVMat3Diagonalize(h, e, &v);
        for (int i = 0; i < 3; i++) {
            for (int j = i + 1; j < 3; j++) {
                double f = fabs(e[i] - e[j]);
                double strength = transitionStrength(v, i, j);
                if (f < 1.0 || strength < 1e-4) continue;
                double normalizedStrength = strength / (double)axisCount;
                if (hyperfine && normalizedStrength > strongestWeight) {
                    strongestWeight = normalizedStrength;
                    strongestFrequency = f;
                }
                addHyperfineLines(lines, f, normalizedStrength, hyperfine);
            }
        }
    }

    double span = fmax(700.0, 2.0 * NVGamma_MHzPerG * Bg * 1.15 + 4.0 * linewidth);
    double freqMin = fmax(50.0, NVD_MHz - span);
    double freqMax = NVD_MHz + span;
    int points = 2600;
    NVSeries *series = [NVSeries seriesWithLabel:@"Photoluminescence" color:Cyan()];
    for (int k = 0; k < points; k++) {
        double f = freqMin + (freqMax - freqMin) * (double)k / (double)(points - 1);
        double y = 1.0;
        for (NSValue *val in lines) {
            NVLine line;
            [val getValue:&line];
            double x = 2.0 * (f - line.frequency) / linewidth;
            y -= contrast * line.weight / (1.0 + x * x);
        }
        y += 0.00022 * gaussianNoise() * noiseScale(p);
        [series addX:f / 1000.0 y:y];
    }
    r.signalSeries = @[series];

    if (hyperfine && strongestWeight > 0.0) {
        double halfSpan = MAX(9.0, 4.0 * linewidth + 3.0);
        int detailPoints = 601;
        NVSeries *total = [NVSeries seriesWithLabel:@"Total PL" color:Cyan()];
        NVSeries *mIPlus = [NVSeries seriesWithLabel:@"m_I = +1" color:Amber()];
        NVSeries *mIZero = [NVSeries seriesWithLabel:@"m_I = 0" color:Magenta()];
        NVSeries *mIMinus = [NVSeries seriesWithLabel:@"m_I = −1" color:Green()];
        for (int k = 0; k < detailPoints; k++) {
            double offset = -halfSpan + 2.0 * halfSpan * (double)k / (double)(detailPoints - 1);
            double f = strongestFrequency + offset;
            double y = 1.0;
            for (NSValue *val in lines) {
                NVLine line;
                [val getValue:&line];
                if (fabs(line.frequency - strongestFrequency) > halfSpan + 2.0 * linewidth) continue;
                double x = 2.0 * (f - line.frequency) / linewidth;
                y -= contrast * line.weight / (1.0 + x * x);
            }
            [total addX:offset y:y];
            for (int mI = -1; mI <= 1; mI++) {
                double componentFrequency = strongestFrequency + (double)mI * NVHyperfine_MHz;
                double x = 2.0 * (f - componentFrequency) / linewidth;
                double component = 1.0 - contrast * strongestWeight / 3.0 / (1.0 + x * x);
                NVSeries *target = mI < 0 ? mIMinus : (mI == 0 ? mIZero : mIPlus);
                [target addX:offset y:component];
            }
        }
        r.detailSeries = @[total, mIPlus, mIZero, mIMinus];
        r.detailTitle = [NSString stringWithFormat:@"¹⁴N hyperfine detail · f₀ = %.4f GHz", strongestFrequency / 1000.0];
        r.detailXLabel = @"Frequency − f₀ (MHz)";
        r.detailYLabel = @"Normalized PL";
    }

    // Energy levels for every orientation represented by the sample.
    double Bmax = fmax(5.0, field * 1.3);
    r.levelSeries = buildLevelSeries(ensemble, Bmax, p[@"theta"].doubleValue, p[@"phi"].doubleValue, strain, 121);

    NVSequenceModel *seq = [NVSequenceModel sequenceWithTitle:@"CW ODMR" duration:100.0];
    [seq addTrack:NVTrackLaser start:0 duration:100 label:@"532 nm pump"];
    [seq addTrack:NVTrackMW start:0 duration:100 label:@"MW drive"];
    [seq addTrack:NVTrackReadout start:0 duration:100 label:@"PL detection"];
    r.sequence = seq;

    NSArray<NSDictionary *> *groups = groupedLines(lines);
    NSMutableString *s = [NSMutableString string];
    [s appendFormat:@"D = %.3f GHz   E = %.2f MHz\n", NVD_MHz / 1000.0, strain];
    [s appendFormat:@"B = %.2f mT (%.0f G)   θ = %.1f°   φ = %.1f°\n", field, Bg, p[@"theta"].doubleValue, p[@"phi"].doubleValue];
    [s appendFormat:@"Sample: %@   hyperfine: %@\n", ensemble ? @"NV ensemble (4 orientations)" : @"single NV", hyperfine ? @"on" : @"off"];
    if (ensemble) {
        [s appendString:@"Ensemble Levels plots all four ⟨111⟩ axes; symmetry-related branches can overlap.\n"];
    }
    if (hyperfine) {
        [s appendFormat:@"Hyperfine detail: three ¹⁴N lines at f₀ ± %.2f MHz.\n", NVHyperfine_MHz];
        if (linewidth > 2.0 * NVHyperfine_MHz) {
            [s appendString:@"The ODMR dips overlap at this linewidth; use the hyperfine detail inset to resolve the triplet.\n"];
        }
    }
    [s appendString:@"Predicted ODMR lines (GHz, weight):\n"];
    int shown = 0;
    for (NSDictionary *g in groups) {
        if (shown++ >= 8) break;
        [s appendFormat:@"  %@   w = %.2f\n", formatGHz([g[@"freq"] doubleValue]), [g[@"weight"] doubleValue]];
    }
    if (groups.count == 0) [s appendString:@"  no lines in the scan window\n"];
    double split = 0.0;
    if (groups.count >= 2) {
        split = ([groups.lastObject[@"freq"] doubleValue] - [groups.firstObject[@"freq"] doubleValue]) / 1000.0;
    }
    if (split > 0.0) [s appendFormat:@"Observed line span: %.3f GHz\n", split];
    [s appendString:@"The dip positions are eigenfrequency differences of the full spin-1 Hamiltonian."];
    r.summary = s;
    r.blochTheta = 0.0;
    r.blochPhi = 0.0;
    r.metrics = @{@"field": @(field), @"D": @(NVD_MHz / 1000.0), @"E": @(strain)};
    return r;
}

static NVSimulationResult *runRabi(NSDictionary<NSString *, NSNumber *> *p) {
    NVSimulationResult *r = [NVSimulationResult new];
    seedRng(0x7AB1ULL);
    double omega = MAX(0.01, p[@"rabi"].doubleValue);
    double delta = p[@"detuning"].doubleValue;
    double maxT = MAX(20.0, p[@"maxTime"].doubleValue);
    double t2 = MAX(20.0, p[@"t2rabi"].doubleValue);
    double contrast = p[@"contrast"].doubleValue / 100.0;
    double gen = sqrt(omega * omega + delta * delta);

    NVSeries *s = [NVSeries seriesWithLabel:@"Rabi signal" color:Cyan()];
    s.showsPoints = YES;
    int points = 520;
    for (int i = 0; i < points; i++) {
        double t = maxT * (double)i / (double)(points - 1);
        double pop = NVRabiPopulation(omega, delta, t) * exp(-pow(t / t2, 2.0));
        double y = 1.0 - contrast * pop + 0.00016 * gaussianNoise() * noiseScale(p);
        [s addX:t y:y];
    }
    r.signalSeries = @[s];

    double tpi = 1000.0 / (2.0 * gen);
    double pPi = (omega * omega / (gen * gen)) * pow(sin(M_PI * gen * tpi / 1000.0), 2.0);
    double pFinal = NVRabiPopulation(omega, delta, maxT) * exp(-pow(maxT / t2, 2.0));
    r.blochTheta = 2.0 * asin(sqrt(fmin(1.0, fmax(0.0, pFinal))));
    r.blochPhi = 0.0;
    r.blochLength = exp(-pow(maxT / t2, 2.0));

    NVSequenceModel *seq = [NVSequenceModel sequenceWithTitle:@"Rabi pulse" duration:40.0 + fmax(30.0, tpi) + 70.0];
    [seq addTrack:NVTrackLaser start:0 duration:40 label:@"init"];
    [seq addTrack:NVTrackMW start:40 duration:fmax(30.0, tpi) label:@"MW drive"];
    [seq addTrack:NVTrackReadout start:40.0 + fmax(30.0, tpi) duration:60 label:@"readout"];
    r.sequence = seq;

    NSMutableString *summary = [NSMutableString string];
    [summary appendFormat:@"Ω/2π = %.3f MHz   Δ = %.3f MHz\n", omega, delta];
    [summary appendFormat:@"Generalized Rabi frequency = %.3f MHz\n", gen];
    [summary appendFormat:@"π-pulse duration = %.1f ns\n", tpi];
    [summary appendFormat:@"Rabi damping time = %.0f ns\n", t2];
    [summary appendFormat:@"Expected inversion at π pulse: %.1f%%\n", 100.0 * pPi];
    [summary appendFormat:@"Population at maximum pulse: %.1f%%\n", 100.0 * pFinal];
    if (tpi < 20.0) [summary appendString:@"Note: this pulse is shorter than the 40 ns laser rise time; initialization limits apply.\n"];
    [summary appendString:@"Signal is the normalized PL: high for |0⟩, low for |+1⟩."];
    r.summary = summary;
    r.metrics = @{@"rabi": @(omega), @"detuning": @(delta), @"piTime": @(tpi)};
    return r;
}

static NVSimulationResult *runRamsey(NSDictionary<NSString *, NSNumber *> *p) {
    NVSimulationResult *r = [NVSimulationResult new];
    seedRng(0x22C3ULL);
    double delta = MAX(0.001, p[@"detuning"].doubleValue);
    double maxT = MAX(30.0, p[@"maxTime"].doubleValue);
    double t2s = MAX(20.0, p[@"t2star"].doubleValue);
    double phase = p[@"phase"].doubleValue * M_PI / 180.0;
    double contrast = p[@"contrast"].doubleValue / 100.0;
    BOOL gaussian = p[@"envelope"].integerValue == 0;

    NVSeries *s = [NVSeries seriesWithLabel:@"Ramsey signal" color:Amber()];
    s.showsPoints = YES;
    int points = 600;
    for (int i = 0; i < points; i++) {
        double t = maxT * (double)i / (double)(points - 1);
        double env = gaussian ? exp(-pow(t / t2s, 2.0)) : exp(-t / t2s);
        double osc = 0.5 + 0.5 * cos(2.0 * M_PI * delta * t / 1000.0 + phase) * env;
        double y = 1.0 - contrast * (1.0 - osc) + 0.00014 * gaussianNoise() * noiseScale(p);
        [s addX:t y:y];
    }
    r.signalSeries = @[s];
    r.blochTheta = M_PI / 2.0;
    r.blochPhi = fmod(phase + 2.0 * M_PI * delta * maxT / 1000.0, 2.0 * M_PI);
    r.blochLength = gaussian ? exp(-pow(maxT / t2s, 2.0)) : exp(-maxT / t2s);

    double duration = 40.0 + 30.0 + maxT + 30.0 + 60.0;
    NVSequenceModel *seq = [NVSequenceModel sequenceWithTitle:@"Ramsey sequence" duration:duration];
    [seq addTrack:NVTrackLaser start:0 duration:40 label:@"init"];
    [seq addTrack:NVTrackMW start:40 duration:30 label:@"π/2"];
    [seq addTrack:NVTrackMW start:70.0 + maxT duration:30 label:@"π/2"];
    [seq addTrack:NVTrackReadout start:100.0 + maxT duration:60 label:@"readout"];
    r.sequence = seq;

    NSMutableString *summary = [NSMutableString string];
    [summary appendFormat:@"Detuning Δ = %.3f MHz\n", delta];
    [summary appendFormat:@"Fringe period = %.3f µs\n", 1.0 / delta];
    [summary appendFormat:@"T₂* = %.0f ns   envelope = %@\n", t2s, gaussian ? @"Gaussian" : @"Lorentzian"];
    [summary appendFormat:@"Final π/2 phase = %.1f°\n", p[@"phase"].doubleValue];
    [summary appendString:@"The fringe frequency directly measures the detuning; the envelope measures dephasing."];
    r.summary = summary;
    r.metrics = @{@"detuning": @(delta), @"t2star": @(t2s), @"period": @(1.0 / delta)};
    return r;
}

static NVSimulationResult *runEcho(NSDictionary<NSString *, NSNumber *> *p) {
    NVSimulationResult *r = [NVSimulationResult new];
    seedRng(0x31D4ULL);
    NSInteger mode = p[@"mode"].integerValue;
    double maxT = MAX(50.0, p[@"maxTime"].doubleValue);
    double t2 = MAX(30.0, p[@"t2"].doubleValue);
    double t2s = MAX(20.0, p[@"t2star"].doubleValue);
    BOOL idealProfile = p[@"ideal"].integerValue == 1;
    double pulseError = idealProfile ? 0.0 : p[@"pulseError"].doubleValue / 100.0;
    double contrast = p[@"contrast"].doubleValue / 100.0;
    double pulseFactor = 1.0 - 0.35 * pulseError;

    NSMutableArray<NVSeries *> *series = [NSMutableArray array];
    if (mode == 0) {
        NVSeries *echo = [NVSeries seriesWithLabel:@"Hahn echo" color:Amber()];
        echo.showsPoints = YES;
        NVSeries *ramsey = [NVSeries seriesWithLabel:@"Ramsey (T₂*)" color:Magenta()];
        ramsey.dashed = YES;
        int points = 420;
        for (int i = 0; i < points; i++) {
            double total = maxT * (double)i / (double)(points - 1);
            double tau = total / 2.0;
            double coh = NVEchoCoherence(tau, tau, t2, t2s) * pulseFactor;
            double ram = exp(-pow(total / t2s, 2.0));
            [echo addX:total y:1.0 - contrast * 0.5 * (1.0 - coh) + 0.00013 * gaussianNoise()];
            [ramsey addX:total y:1.0 - contrast * 0.5 * (1.0 - ram)];
        }
        [series addObject:echo];
        [series addObject:ramsey];
        r.summary = [NSString stringWithFormat:
            @"Symmetric Hahn echo: τ₁ = τ₂\nT₂ = %.0f ns   T₂* = %.0f ns\nImprovement factor T₂/T₂* = %.1f×\nπ-pulse error = %.1f%%\nThe echo refocuses slow noise while dynamic noise still limits T₂.",
            t2, t2s, t2 / t2s, pulseError * 100.0];
    } else {
        double tau2 = maxT * 0.25;
        NVSeries *echo = [NVSeries seriesWithLabel:@"Asymmetric echo" color:Amber()];
        echo.showsPoints = YES;
        NVSeries *marker = [NVSeries seriesWithLabel:@"τ₁ = τ₂" color:Magenta()];
        marker.showsPoints = YES;
        int points = 420;
        double peakX = tau2;
        double peakY = 1.0;
        for (int i = 0; i < points; i++) {
            double tau1 = (maxT * 0.5) * (double)i / (double)(points - 1);
            double coh = NVEchoCoherence(tau1, tau2, t2, t2s) * pulseFactor;
            double y = 1.0 - contrast * 0.5 * (1.0 - coh) + 0.00013 * gaussianNoise() * noiseScale(p);
            [echo addX:tau1 y:y];
            if (fabs(tau1 - peakX) < (maxT * 0.5 / (double)(points - 1))) {
                peakY = y;
            }
        }
        [marker addX:peakX y:peakY];
        [series addObject:echo];
        [series addObject:marker];
        r.summary = [NSString stringWithFormat:
            @"Asymmetric echo: τ₂ fixed at %.0f ns\nRefocusing maximum at τ₁ = τ₂ = %.0f ns\nT₂ = %.0f ns   T₂* = %.0f ns\nAway from τ₁ = τ₂ the static dephasing is not cancelled, so the signal falls.",
            tau2, tau2, t2, t2s];
    }
    r.signalSeries = series;

    double seqTau = mode == 0 ? maxT / 2.0 : maxT * 0.25;
    double duration = 190.0 + 2.0 * seqTau;
    NVSequenceModel *seq = [NVSequenceModel sequenceWithTitle:@"Spin echo" duration:duration];
    [seq addTrack:NVTrackLaser start:0 duration:40 label:@"init"];
    [seq addTrack:NVTrackMW start:40 duration:30 label:@"π/2"];
    [seq addTrack:NVTrackMW start:70.0 + seqTau duration:30 label:@"π"];
    [seq addTrack:NVTrackMW start:100.0 + 2.0 * seqTau duration:30 label:@"π/2"];
    [seq addTrack:NVTrackReadout start:130.0 + 2.0 * seqTau duration:60 label:@"readout"];
    r.sequence = seq;
    r.metrics = @{@"t2": @(t2), @"t2star": @(t2s)};
    return r;
}

static double cpmgFilterPeak(double tauNs, NSInteger pulses) {
    double best = 0.0;
    double bestF = 0.0;
    for (int i = 0; i < 900; i++) {
        double f = 0.05 + (20.0 - 0.05) * (double)i / 899.0;
        double v = NVCpmgFilter(f, tauNs, pulses);
        if (v > best) { best = v; bestF = f; }
    }
    return bestF;
}

static NVSimulationResult *runCPMG(NSDictionary<NSString *, NSNumber *> *p) {
    NVSimulationResult *r = [NVSimulationResult new];
    seedRng(0x44E5ULL);
    NSInteger maxN = MAX(1, p[@"pulses"].integerValue);
    double tau = MAX(5.0, p[@"tau"].doubleValue);
    double t2 = MAX(30.0, p[@"t2"].doubleValue);
    double alpha = fmax(0.1, p[@"alpha"].doubleValue);
    double acFreq = p[@"acFreq"].doubleValue;
    double acAmp = p[@"acAmp"].doubleValue / 100.0;
    double contrast = p[@"contrast"].doubleValue / 100.0;
    double total = 2.0 * (double)maxN * tau;

    NVSeries *noAC = [NVSeries seriesWithLabel:@"CPMG (no AC)" color:Cyan()];
    NVSeries *withAC = [NVSeries seriesWithLabel:@"With AC field" color:Magenta()];
    noAC.showsPoints = YES;
    withAC.showsPoints = YES;
    for (NSInteger n = 1; n <= maxN; n++) {
        double tauN = total / (2.0 * (double)n);
        double coh = exp(-pow(total / (t2 * pow((double)n, alpha)), 2.0));
        double filter = NVCpmgFilter(acFreq, tauN, n);
        double acCoh = coh * fmax(0.0, 1.0 - 0.85 * acAmp * filter);
        [noAC addX:(double)n y:1.0 - contrast * 0.5 * (1.0 - coh) + 0.00011 * gaussianNoise()];
        [withAC addX:(double)n y:1.0 - contrast * 0.5 * (1.0 - acCoh) + 0.00011 * gaussianNoise()];
    }
    r.signalSeries = @[noAC, withAC];

    NVSeries *filterSeries = [NVSeries seriesWithLabel:@"Filter function" color:Amber()];
    NVSeries *psdSeries = [NVSeries seriesWithLabel:@"1/f noise (norm.)" color:Magenta()];
    psdSeries.dashed = YES;
    double scanMax = MAX(10.0, acFreq * 1.25);
    int points = 500;
    double maxFilter = 0.0;
    double filterValues[500];
    for (int i = 0; i < points; i++) {
        double f = 0.1 + (scanMax - 0.1) * (double)i / (double)(points - 1);
        double v = NVCpmgFilter(f, tau, maxN);
        filterValues[i] = v;
        if (v > maxFilter) maxFilter = v;
    }
    double maxPsd = 1.0 / 0.1;
    for (int i = 0; i < points; i++) {
        double f = 0.1 + (scanMax - 0.1) * (double)i / (double)(points - 1);
        [filterSeries addX:f y:maxFilter > 0 ? filterValues[i] / maxFilter : 0];
        [psdSeries addX:f y:(1.0 / f) / maxPsd];
    }
    r.noiseSeries = @[filterSeries, psdSeries];

    double duration = 40.0 + 30.0 + 2.0 * (double)maxN * tau + 30.0 + 60.0;
    NSInteger shown = maxN;
    NVSequenceModel *seq = [NVSequenceModel sequenceWithTitle:@"CPMG / dynamical decoupling" duration:duration];
    [seq addTrack:NVTrackLaser start:0 duration:40 label:@"init"];
    [seq addTrack:NVTrackMW start:40 duration:30 label:@"π/2"];
    for (NSInteger i = 0; i < shown; i++) {
        double start = 70.0 + (2.0 * (double)i + 1.0) * tau;
        [seq addTrack:NVTrackMW start:start duration:18 label:@"π"];
    }
    [seq addTrack:NVTrackMW start:70.0 + 2.0 * (double)maxN * tau duration:30 label:@"π/2"];
    [seq addTrack:NVTrackReadout start:100.0 + 2.0 * (double)maxN * tau duration:60 label:@"readout"];
    r.sequence = seq;

    NSMutableString *summary = [NSMutableString string];
    [summary appendFormat:@"N = %ld π pulses   τ = %.0f ns\n", (long)maxN, tau];
    [summary appendFormat:@"Total free evolution = %.1f µs\n", total / 1000.0];
    double filterPeak = cpmgFilterPeak(tau, maxN);
    [summary appendFormat:@"Filter maximum ≈ %.3f MHz\n", filterPeak];
    [summary appendFormat:@"Coherence scaling ∝ N^%.2f\n", alpha];
    [summary appendFormat:@"AC tone: %.3f MHz, amplitude %.0f%%\n", acFreq, acAmp * 100.0];
    if (fabs(acFreq - filterPeak) < 0.15 * fmax(0.5, filterPeak)) {
        [summary appendString:@"AC frequency is near the filter maximum: the sequence is sensitive to this tone.\n"];
    } else {
        [summary appendString:@"AC frequency is away from the filter maximum: the tone is largely filtered out.\n"];
    }
    [summary appendString:@"Repeating π pulses narrows the filter and suppresses low-frequency noise."];
    r.summary = summary;
    r.metrics = @{@"pulses": @(maxN), @"tau": @(tau), @"filterPeak": @(filterPeak)};
    return r;
}

static NVSimulationResult *runQubit(NSDictionary<NSString *, NSNumber *> *p) {
    NVSimulationResult *r = [NVSimulationResult new];
    seedRng(0x9B26ULL);
    NSInteger gate = p[@"gate"].integerValue;
    double angle = p[@"angle"].doubleValue * M_PI / 180.0;
    BOOL idealProfile = p[@"ideal"].integerValue == 1;
    double eff = idealProfile ? 1.0 : p[@"initEff"].doubleValue / 100.0;
    double contrastPct = idealProfile ? 10.0 : MAX(0.2, p[@"contrast"].doubleValue);
    double readoutTime = MAX(50.0, p[@"readoutTime"].doubleValue);
    double readoutError = idealProfile ? 0.0 : 0.02 * (2.0 / contrastPct) * (300.0 / readoutTime);
    readoutError = fmin(0.35, fmax(0.0, readoutError));
    NSInteger shots = MAX(10, p[@"shots"].integerValue);
    double theta = 0.0;
    double phi = 0.0;
    NSString *gateName = @"X";
    switch (gate) {
        case 0: theta = M_PI; phi = 0.0; gateName = @"X (π)"; break;
        case 1: theta = M_PI; phi = 0.0; gateName = @"Y (π)"; break;
        case 2: theta = 0.0; phi = 0.0; gateName = @"Z (phase)"; break;
        case 3: theta = M_PI / 2.0; phi = 0.0; gateName = @"H"; break;
        case 4: theta = angle; phi = -M_PI / 2.0; gateName = @"Rx(θ)"; break;
        default: theta = angle; phi = 0.0; gateName = @"Ry(θ)"; break;
    }
    double displayedAngle = gate == 0 || gate == 1 ? 180.0 : (gate == 2 ? 0.0 : (gate == 3 ? 90.0 : p[@"angle"].doubleValue));
    double p0ideal = cos(theta / 2.0) * cos(theta / 2.0);
    double p1ideal = sin(theta / 2.0) * sin(theta / 2.0);
    double p0 = eff * p0ideal + (1.0 - eff) * 0.5;
    double p1 = 1.0 - p0;
    double p1Measured = p1 * (1.0 - readoutError) + p0 * readoutError;
    NSInteger ones = 0;
    for (NSInteger i = 0; i < shots; i++) {
        if (uniform01() < p1Measured) ones++;
    }
    r.histogram0 = shots - ones;
    r.histogram1 = ones;
    r.fidelity = fmax(0.0, fmin(1.0, eff * (1.0 - readoutError)));
    r.blochTheta = theta;
    r.blochPhi = phi;

    double duration = 40.0 + 60.0 + readoutTime;
    NVSequenceModel *seq = [NVSequenceModel sequenceWithTitle:@"Single-qubit sequence" duration:duration];
    [seq addTrack:NVTrackLaser start:0 duration:40 label:@"init"];
    [seq addTrack:NVTrackMW start:40 duration:60 label:gateName];
    [seq addTrack:NVTrackReadout start:100 duration:readoutTime label:@"readout"];
    r.sequence = seq;

    NSMutableString *summary = [NSMutableString string];
    [summary appendFormat:@"Gate: %@   rotation: %.1f°\n", gateName, displayedAngle];
    double phiDeg = fmod(phi * 180.0 / M_PI + 360.0, 360.0);
    [summary appendFormat:@"Bloch angles: θ = %.1f°, φ = %.1f°\n", theta * 180.0 / M_PI, phiDeg];
    [summary appendFormat:@"Ideal P(0) = %.3f   P(1) = %.3f\n", p0ideal, p1ideal];
    [summary appendFormat:@"Including initialization (%.0f%%): P(0) = %.3f, P(1) = %.3f\n", eff * 100.0, p0, p1];
    [summary appendFormat:@"Readout contrast = %.2f%%   integration = %.0f ns   misclassification = %.2f%%\n", contrastPct, readoutTime, readoutError * 100.0];
    [summary appendFormat:@"Measured P(1) including readout = %.3f\n", p1Measured];
    [summary appendFormat:@"Readout shots: %ld   counts |0⟩ = %ld, |1⟩ = %ld\n", (long)shots, (long)r.histogram0, (long)r.histogram1];
    [summary appendFormat:@"Readout fidelity estimate = %.3f\n", r.fidelity];
    if (gate == 2) {
        [summary appendString:@"A Z gate leaves |0⟩ unchanged; it only adds a relative phase to a superposition."];
    } else if (gate == 1) {
        [summary appendString:@"For this initial state Y differs from X only by a global phase, which is invisible on the Bloch sphere."];
    } else {
        [summary appendString:@"The optical contrast sets the separation between the |0⟩ and |1⟩ count distributions."];
    }
    r.summary = summary;
    r.metrics = @{@"p0": @(p0), @"p1": @(p1), @"readoutError": @(readoutError)};
    return r;
}

static NVSimulationResult *runRelaxation(NSDictionary<NSString *, NSNumber *> *p) {
    NVSimulationResult *r = [NVSimulationResult new];
    seedRng(0xD7A1ULL);
    double t1 = MAX(1.0, p[@"t1"].doubleValue);
    double t2s = MAX(20.0, p[@"t2star"].doubleValue);
    double requestedT2 = MAX(30.0, p[@"t2"].doubleValue);
    double t2Limit = 2.0 * t1 * 1000.0;
    double t2 = MIN(requestedT2, t2Limit);
    BOOL t2Clamped = requestedT2 > t2Limit;
    double maxUs = MAX(10.0, p[@"maxTime"].doubleValue);
    double contrast = p[@"contrast"].doubleValue / 100.0;

    NVSeries *t1s = [NVSeries seriesWithLabel:@"T₁ recovery" color:Amber()];
    t1s.showsPoints = YES;
    int n1 = 500;
    for (int i = 0; i < n1; i++) {
        double t = maxUs * (double)i / (double)(n1 - 1);
        double y = 1.0 - contrast * exp(-t / t1) + 0.00012 * gaussianNoise() * noiseScale(p);
        [t1s addX:t y:y];
    }
    r.t1Series = @[t1s];

    NVSeries *ramsey = [NVSeries seriesWithLabel:@"Ramsey (T₂*)" color:Magenta()];
    ramsey.dashed = YES;
    NVSeries *echo = [NVSeries seriesWithLabel:@"Echo (T₂)" color:Cyan()];
    echo.showsPoints = YES;
    double tmaxNs = fmax(5.0 * t2, 5.0 * t2s);
    int n2 = 500;
    for (int i = 0; i < n2; i++) {
        double t = tmaxNs * (double)i / (double)(n2 - 1);
        double ram = exp(-pow(t / t2s, 2.0));
        double ech = exp(-pow(t / t2, 2.0));
        [ramsey addX:t y:1.0 - contrast * 0.5 * (1.0 - ram)];
        [echo addX:t y:1.0 - contrast * 0.5 * (1.0 - ech) + 0.00011 * gaussianNoise()];
    }
    r.t2Series = @[echo, ramsey];

    NVSequenceModel *seq = [NVSequenceModel sequenceWithTitle:@"Relaxation protocol" duration:100.0];
    [seq addTrack:NVTrackLaser start:0 duration:40 label:@"init"];
    [seq addTrack:NVTrackMW start:40 duration:20 label:@"prepare"];
    [seq addTrack:NVTrackReadout start:80 duration:20 label:@"readout"];
    r.sequence = seq;

    NSMutableString *summary = [NSMutableString string];
    [summary appendFormat:@"T₁ = %.1f µs\n", t1];
    [summary appendFormat:@"T₂* = %.0f ns\n", t2s];
    [summary appendFormat:@"T₂ (echo) = %.0f ns\n", t2];
    [summary appendFormat:@"T₂/T₂* = %.1f×\n", t2 / t2s];
    [summary appendFormat:@"Coherence limit: T₂ ≤ 2T₁ = %.1f µs\n", 2.0 * t1];
    if (t2Clamped) {
        [summary appendFormat:@"T₂ was capped at 2T₁ = %.0f ns (requested %.0f ns).\n", t2Limit, requestedT2];
    } else {
        [summary appendString:@"The entered coherence times satisfy the physical limit T₂ ≤ 2T₁.\n"];
    }
    [summary appendString:@"T₁ is energy relaxation; T₂* is inhomogeneous dephasing; echo refocusing extends T₂."];
    r.summary = summary;
    r.metrics = @{@"t1": @(t1), @"t2star": @(t2s), @"t2": @(t2), @"t2Clamped": @(t2Clamped)};
    return r;
}

static NVSimulationResult *runAlignment(NSDictionary<NSString *, NSNumber *> *p) {
    NVSimulationResult *r = [NVSimulationResult new];
    double overlap = p[@"overlap"].doubleValue;
    double focus = p[@"focus"].doubleValue;
    double coupling = p[@"coupling"].doubleValue;
    double power = p[@"laserPower"].doubleValue;
    double gain = p[@"gain"].doubleValue;
    double score = 0.40 * overlap + 0.35 * focus + 0.25 * coupling;
    double powerFactor = power / 5.0;
    double focusFactor = 0.3 + 0.7 * focus / 100.0;
    double gainFactor = 0.4 + 0.6 * gain / 100.0;
    double couplingFactor = coupling / 100.0;
    double responseAtOverlap = 0.08 + 0.92 * (1.0 - exp(-3.0 * overlap / 100.0));
    double pl = 5000.0 * powerFactor * responseAtOverlap * focusFactor * gainFactor;
    double contrast = 0.4 + 3.0 * couplingFactor * focusFactor * responseAtOverlap;
    double snr = sqrt(fmax(1.0, pl * 0.01)) * contrast / 2.0;

    NVSeries *plSeries = [NVSeries seriesWithLabel:@"PL signal" color:Cyan()];
    NVSeries *contrastSeries = [NVSeries seriesWithLabel:@"ODMR contrast" color:Amber()];
    for (int i = 0; i <= 100; i += 2) {
        double x = i;
        double response = 0.08 + 0.92 * (1.0 - exp(-3.0 * x / 100.0));
        double plv = powerFactor * focusFactor * gainFactor * response;
        double cv = (0.4 + 3.0 * couplingFactor * focusFactor * response) / 3.4;
        [plSeries addX:x y:plv];
        [contrastSeries addX:x y:cv];
    }

    NVSeries *currentSeries = [NVSeries seriesWithLabel:@"Current setting" color:[NSColor colorWithWhite:0.92 alpha:0.95]];
    currentSeries.dashed = YES;
    currentSeries.showsPoints = YES;
    currentSeries.showsInLegend = NO;
    [currentSeries addX:overlap y:pl / 5000.0];
    [currentSeries addX:overlap y:contrast / 3.4];
    r.signalSeries = @[plSeries, contrastSeries, currentSeries];

    NSMutableString *summary = [NSMutableString string];
    [summary appendFormat:@"Alignment score: %.0f / 100\n", score];
    [summary appendFormat:@"Photoluminescence: %.0f counts/ms\n", pl];
    [summary appendFormat:@"ODMR contrast: %.2f%%\n", contrast];
    [summary appendFormat:@"Estimated SNR: %.1f\n\n", snr];
    [summary appendFormat:@"%@  Beam overlap ≥ 80%%\n", overlap >= 80 ? @"✓" : @"!"];
    [summary appendFormat:@"%@  Objective focus ≥ 70%%\n", focus >= 70 ? @"✓" : @"!"];
    [summary appendFormat:@"%@  MW antenna coupling ≥ 60%%\n", coupling >= 60 ? @"✓" : @"!"];
    [summary appendFormat:@"%@  Laser power ≤ 5 mW\n", power <= 5.0 ? @"✓" : @"!"];
    [summary appendFormat:@"%@  Detector gain in usable range\n", (gain >= 20 && gain <= 90) ? @"✓" : @"!"];
    [summary appendString:@"\nSignal tab: curves show response versus beam overlap; the dashed marker is the current setting.\n"];
    [summary appendString:@"Adjust overlap, focus and coupling until all checks pass; use laser power and gain for signal level."];
    r.summary = summary;
    r.hardwareText = NVHardwareDescription();
    r.metrics = @{@"score": @(score), @"pl": @(pl), @"contrast": @(contrast)};
    return r;
}

static NVSimulationResult *runExplorer(NSDictionary<NSString *, NSNumber *> *p) {
    NVSimulationResult *r = [NVSimulationResult new];
    double field = p[@"field"].doubleValue;
    BOOL ensemble = p[@"ensemble"].integerValue == 1;

    double Bmax = fmax(20.0, field * 1.3);
    r.levelSeries = buildLevelSeries(ensemble, Bmax, p[@"theta"].doubleValue, p[@"phi"].doubleValue, 0.0, 140);

    NSMutableString *summary = [NSMutableString string];
    [summary appendFormat:@"NV axis: ⟨111⟩   D = %.3f GHz\n", NVD_MHz / 1000.0];
    [summary appendFormat:@"B = %.1f mT   θ = %.1f°   φ = %.1f°\n", field, p[@"theta"].doubleValue, p[@"phi"].doubleValue];
    [summary appendFormat:@"Orientation view: %@\n", ensemble ? @"four ⟨111⟩ axes" : @"single NV axis"];
    [summary appendString:@"The defect consists of a substitutional nitrogen adjacent to a vacancy."];
    if (ensemble) [summary appendString:@" Ensemble mode shows the four possible NV orientations."];
    r.summary = summary;
    r.hardwareText = NVHardwareDescription();
    return r;
}

NVSimulationResult *NVRunExperiment(NVExperimentKind kind, NSDictionary<NSString *, NSNumber *> *params) {
    switch (kind) {
        case NVExperimentKindODMR: return runODMR(params);
        case NVExperimentKindRabi: return runRabi(params);
        case NVExperimentKindRamsey: return runRamsey(params);
        case NVExperimentKindEcho: return runEcho(params);
        case NVExperimentKindCPMG: return runCPMG(params);
        case NVExperimentKindQubit: return runQubit(params);
        case NVExperimentKindRelaxation: return runRelaxation(params);
        case NVExperimentKindAlignment: return runAlignment(params);
        case NVExperimentKindExplorer: return runExplorer(params);
    }
    return [NVSimulationResult new];
}

NSDictionary<NSString *, NSNumber *> *NVDiagnosticValues(void) {
    return @{@"D_MHz": @(NVD_MHz),
             @"gamma_MHzPerG": @(NVGamma_MHzPerG),
             @"hyperfine_MHz": @(NVHyperfine_MHz),
             @"zeroField_GHz": @(NVZeroFieldSplittingGHz)};
}

NSString *NVHardwareDescription(void) {
    return @"REFERENCE NV TEACHING SETUP — SIMULATED\n"
           @"\nOPTICAL CHAIN\n"
           @"  532 nm pulsed laser, < 5 mW, rise time ≈ 40 ns\n"
           @"  shutter / AOM → beam expander → dichroic → objective → diamond\n"
           @"  photoluminescence → dichroic → 650 nm long-pass → confocal pinhole → photodetector\n"
           @"  sample: diamond with NV ensemble, density ≈ 4.5 ppm, [111] orientation\n"
           @"  microwave antenna mounted close to the diamond\n"
           @"\nELECTRONIC CHAIN\n"
           @"  microwave source: 3 MHz – 5.5 GHz, 30 dBm maximum, 1 ns amplitude sampling\n"
           @"  IQ modulation, RF switch, amplifier, stripline / loop antenna\n"
           @"  timing controller: TTL pulse generation, 4 ns time-tagging resolution\n"
           @"  3-axis Helmholtz coils, current supplies, Hall probe\n"
           @"  photon counter / simulated DAQ → in-app data path\n"
           @"\nSIMULATED CONTROL & SAFETY\n"
           @"  laser interlock, shutter, emergency stop\n"
           @"  RF enable only during a sequence; amplifier watchdog\n"
           @"  magnet current ramps and maximum-field limits\n"
           @"  every run logs simulated settings, calibration and seed\n"
           @"\nSIMULATION ONLY\n  No instrument connection, device discovery, driver, or hardware I/O is used.\n  This page is a simulated reference setup for teaching and experiment design.";
}
