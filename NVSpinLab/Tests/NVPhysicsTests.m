#import <XCTest/XCTest.h>
#import "NVPhysics.h"

@interface NVPhysicsTests : XCTestCase
@end

@implementation NVPhysicsTests

- (NSArray<NSNumber *> *)sortedEigenvalues:(double[3])e {
    NSMutableArray *a = [NSMutableArray array];
    for (int i = 0; i < 3; i++) [a addObject:@(e[i])];
    [a sortUsingSelector:@selector(compare:)];
    return a;
}

- (void)testZeroFieldEigenvalues {
    double e[3];
    NVMat3 v;
    NVMat3Diagonalize(NVMat3Hamiltonian(0, 0, 0, 0), e, &v);
    NSArray *s = [self sortedEigenvalues:e];
    XCTAssertEqualWithAccuracy([s[0] doubleValue], 0.0, 1e-6);
    XCTAssertEqualWithAccuracy([s[1] doubleValue], NVD_MHz, 1e-4);
    XCTAssertEqualWithAccuracy([s[2] doubleValue], NVD_MHz, 1e-4);
}

- (void)testStrainSplitting {
    double e[3];
    NVMat3 v;
    double strain = 5.0;
    NVMat3Diagonalize(NVMat3Hamiltonian(0, 0, 0, strain), e, &v);
    NSArray *s = [self sortedEigenvalues:e];
    XCTAssertEqualWithAccuracy([s[0] doubleValue], 0.0, 1e-6);
    XCTAssertEqualWithAccuracy([s[1] doubleValue], NVD_MHz - strain, 1e-3);
    XCTAssertEqualWithAccuracy([s[2] doubleValue], NVD_MHz + strain, 1e-3);
}

- (void)testAxialZeemanSlopes {
    double e[3];
    NVMat3 v;
    double bG = 100.0;
    NVMat3Diagonalize(NVMat3Hamiltonian(0, 0, bG, 0), e, &v);
    NSArray *s = [self sortedEigenvalues:e];
    double shift = NVGamma_MHzPerG * bG;
    XCTAssertEqualWithAccuracy([s[0] doubleValue], 0.0, 1e-6);
    XCTAssertEqualWithAccuracy([s[1] doubleValue], NVD_MHz - shift, 1e-3);
    XCTAssertEqualWithAccuracy([s[2] doubleValue], NVD_MHz + shift, 1e-3);
}

- (void)testRabiPopulation {
    double omega = 4.0;
    double tPi = 1000.0 / (2.0 * omega);
    XCTAssertEqualWithAccuracy(NVRabiPopulation(omega, 0, tPi), 1.0, 1e-6);
    XCTAssertEqualWithAccuracy(NVRabiPopulation(omega, 0, 2.0 * tPi), 0.0, 1e-6);
    XCTAssertEqualWithAccuracy(NVRabiPopulation(omega, 0, 0), 0.0, 1e-9);
    double detuned = NVRabiPopulation(omega, omega, tPi);
    XCTAssertLessThan(detuned, 1.0);
}

- (void)testRamseyFringePeriod {
    double delta = 2.0; // MHz
    double period = 1.0 / delta; // µs
    double t0 = 0.0;
    double tHalf = period * 1000.0 / 2.0; // ns
    XCTAssertEqualWithAccuracy(NVRamseyPopulation(delta, 1e9, t0, 0), 1.0, 1e-9);
    XCTAssertEqualWithAccuracy(NVRamseyPopulation(delta, 1e9, tHalf, 0), 0.0, 1e-6);
}

- (void)testEchoRefocusing {
    double t2 = 1000.0;
    double t2s = 200.0;
    double sym = NVEchoCoherence(400, 400, t2, t2s);
    double asym = NVEchoCoherence(200, 600, t2, t2s);
    XCTAssertGreaterThan(sym, asym);
    XCTAssertEqualWithAccuracy(NVEchoCoherence(0, 0, t2, t2s), 1.0, 1e-9);
}

- (void)testCpmgFilterPeak {
    double tau = 200.0; // ns, passband near 2.5 MHz
    double peak = NVCpmgFilter(2.5, tau, 1);
    double low = NVCpmgFilter(0.5, tau, 1);
    double high = NVCpmgFilter(6.0, tau, 1);
    XCTAssertGreaterThan(peak, low);
    XCTAssertGreaterThan(peak, high);
}

- (void)testOdmrLinePositionsSingleNv {
    NSDictionary *p = @{@"field": @8, @"theta": @0, @"phi": @0, @"strain": @0,
                        @"linewidth": @2, @"contrast": @2, @"ensemble": @0, @"hyperfine": @0};
    NVSimulationResult *r = NVRunExperiment(NVExperimentKindODMR, p);
    XCTAssertEqual(r.signalSeries.count, 1u);
    NVSeries *s = r.signalSeries[0];
    XCTAssertGreaterThan(s.x.count, 100u);
    double minY = 1.0;
    double minX = 0;
    for (NSUInteger i = 0; i < s.x.count; i++) {
        double y = s.y[i].doubleValue;
        if (y < minY) { minY = y; minX = s.x[i].doubleValue; }
    }
    XCTAssertEqualWithAccuracy(minX, (NVD_MHz - NVGamma_MHzPerG * 80.0) / 1000.0, 0.01);
}

- (void)testOdmrSampleModeAndHyperfineDetail {
    NSDictionary *base = @{@"field": @8, @"theta": @0, @"phi": @0, @"strain": @0,
                           @"linewidth": @2, @"contrast": @2, @"hyperfine": @1};
    NSMutableDictionary *singleParams = [base mutableCopy];
    singleParams[@"ensemble"] = @0;
    NSMutableDictionary *ensembleParams = [base mutableCopy];
    ensembleParams[@"ensemble"] = @1;
    NVSimulationResult *single = NVRunExperiment(NVExperimentKindODMR, singleParams);
    NVSimulationResult *ensemble = NVRunExperiment(NVExperimentKindODMR, ensembleParams);

    XCTAssertEqual(single.levelSeries.count, 3u);
    XCTAssertEqual(ensemble.levelSeries.count, 12u);
    XCTAssertNotEqualObjects(single.signalSeries.firstObject.y, ensemble.signalSeries.firstObject.y);
    XCTAssertEqual(single.detailSeries.count, 4u);
    XCTAssertEqual(ensemble.detailSeries.count, 4u);
    XCTAssertGreaterThan(single.detailSeries.firstObject.x.count, 100u);
    XCTAssertEqualObjects(ensemble.detailTitle.length > 0 ? @YES : @NO, @YES);

    NSMutableDictionary *offParams = [ensembleParams mutableCopy];
    offParams[@"hyperfine"] = @0;
    NVSimulationResult *off = NVRunExperiment(NVExperimentKindODMR, offParams);
    XCTAssertEqual(off.detailSeries.count, 0u);
}

- (void)testRabiResultContrast {
    NSDictionary *p = @{@"rabi": @4, @"detuning": @0, @"maxTime": @300,
                        @"t2rabi": @5000, @"contrast": @2, @"shots": @500};
    NVSimulationResult *r = NVRunExperiment(NVExperimentKindRabi, p);
    NVSeries *s = r.signalSeries[0];
    double minY = 1.0;
    for (NSNumber *y in s.y) minY = MIN(minY, y.doubleValue);
    XCTAssertLessThan(minY, 0.985);
    XCTAssertGreaterThan(minY, 0.975);
}

- (void)testTraceAndPositivitySanity {
    NSDictionary *p = @{@"field": @8, @"theta": @30, @"phi": @20, @"strain": @5,
                        @"linewidth": @5, @"contrast": @2, @"ensemble": @1, @"hyperfine": @1};
    NVSimulationResult *r = NVRunExperiment(NVExperimentKindODMR, p);
    XCTAssertGreaterThan(r.signalSeries.count, 0u);
    for (NSNumber *y in r.signalSeries[0].y) {
        XCTAssertGreaterThanOrEqual(y.doubleValue, 0.0);
        XCTAssertLessThanOrEqual(y.doubleValue, 1.05);
    }
    XCTAssertGreaterThan(r.levelSeries.count, 0u);
}

- (void)testSystemAlignmentSignalRespondsToEveryControl {
    NSDictionary *base = @{@"overlap": @82, @"focus": @76, @"coupling": @72,
                           @"laserPower": @2.5, @"gain": @55};
    NVSimulationResult *r = NVRunExperiment(NVExperimentKindAlignment, base);
    XCTAssertEqual(r.signalSeries.count, 3u);
    NVSeries *pl = r.signalSeries[0];
    NVSeries *contrast = r.signalSeries[1];
    NVSeries *current = r.signalSeries[2];
    XCTAssertEqual(current.x.count, 2u);
    XCTAssertEqualWithAccuracy(current.x.firstObject.doubleValue, 82.0, 1e-9);
    XCTAssertEqualWithAccuracy(current.x.lastObject.doubleValue, 82.0, 1e-9);
    double basePL = pl.y.lastObject.doubleValue;
    double baseContrast = contrast.y.lastObject.doubleValue;
    double baseMarkerPL = current.y.firstObject.doubleValue;
    double baseMarkerContrast = current.y.lastObject.doubleValue;

    NSMutableDictionary *higherPower = [base mutableCopy];
    higherPower[@"laserPower"] = @5.0;
    NVSimulationResult *powerResult = NVRunExperiment(NVExperimentKindAlignment, higherPower);
    XCTAssertGreaterThan(powerResult.signalSeries[0].y.lastObject.doubleValue, basePL);
    XCTAssertEqualWithAccuracy(powerResult.signalSeries[1].y.lastObject.doubleValue, baseContrast, 1e-12);
    XCTAssertGreaterThan(powerResult.signalSeries[2].y.firstObject.doubleValue, baseMarkerPL);
    XCTAssertEqualWithAccuracy(powerResult.signalSeries[2].y.lastObject.doubleValue, baseMarkerContrast, 1e-12);

    NSMutableDictionary *higherGain = [base mutableCopy];
    higherGain[@"gain"] = @90;
    NVSimulationResult *gainResult = NVRunExperiment(NVExperimentKindAlignment, higherGain);
    XCTAssertGreaterThan(gainResult.signalSeries[0].y.lastObject.doubleValue, basePL);
    XCTAssertEqualWithAccuracy(gainResult.signalSeries[1].y.lastObject.doubleValue, baseContrast, 1e-12);

    NSMutableDictionary *higherCoupling = [base mutableCopy];
    higherCoupling[@"coupling"] = @95;
    NVSimulationResult *couplingResult = NVRunExperiment(NVExperimentKindAlignment, higherCoupling);
    XCTAssertGreaterThan(couplingResult.signalSeries[1].y.lastObject.doubleValue, baseContrast);
    XCTAssertEqualWithAccuracy(couplingResult.signalSeries[0].y.lastObject.doubleValue, basePL, 1e-12);
    XCTAssertGreaterThan(couplingResult.signalSeries[2].y.lastObject.doubleValue, baseMarkerContrast);

    NSMutableDictionary *betterFocus = [base mutableCopy];
    betterFocus[@"focus"] = @95;
    NVSimulationResult *focusResult = NVRunExperiment(NVExperimentKindAlignment, betterFocus);
    XCTAssertGreaterThan(focusResult.signalSeries[0].y.lastObject.doubleValue, basePL);
    XCTAssertGreaterThan(focusResult.signalSeries[1].y.lastObject.doubleValue, baseContrast);

    NSMutableDictionary *lowerOverlap = [base mutableCopy];
    lowerOverlap[@"overlap"] = @30;
    NVSimulationResult *overlapResult = NVRunExperiment(NVExperimentKindAlignment, lowerOverlap);
    XCTAssertEqualWithAccuracy(overlapResult.signalSeries[2].x.firstObject.doubleValue, 30.0, 1e-9);
    XCTAssertLessThan(overlapResult.signalSeries[2].y.firstObject.doubleValue, baseMarkerPL);
    XCTAssertLessThan(overlapResult.signalSeries[2].y.lastObject.doubleValue, baseMarkerContrast);
}

@end
