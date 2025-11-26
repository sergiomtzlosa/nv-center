#import <Foundation/Foundation.h>
#import "NVModels.h"

NS_ASSUME_NONNULL_BEGIN

typedef struct {
    double re;
    double im;
} NVComplex;

typedef struct {
    NVComplex m[9]; // row-major 3x3
} NVMat3;

FOUNDATION_EXPORT const double NVD_MHz;
FOUNDATION_EXPORT const double NVGamma_MHzPerG;
FOUNDATION_EXPORT const double NVHyperfine_MHz;
FOUNDATION_EXPORT const double NVZeroFieldSplittingGHz;

NVMat3 NVMat3Zero(void);
NVMat3 NVMat3Identity(void);
NVMat3 NVMat3Hamiltonian(double BxG, double ByG, double BzG, double E_MHz);
void NVMat3Diagonalize(NVMat3 H, double eigenvalues[_Nonnull 3], NVMat3 * _Nullable eigenvectors);
double NVRabiPopulation(double omegaMHz, double detuningMHz, double timeNs);
double NVRamseyPopulation(double detuningMHz, double t2starNs, double timeNs, double phaseRad);
double NVEchoCoherence(double tau1Ns, double tau2Ns, double t2Ns, double t2starNs);
double NVCpmgFilter(double frequencyMHz, double tauNs, NSInteger pulses);
NSDictionary<NSString *, NSNumber *> *NVDiagnosticValues(void);
NVSimulationResult *NVRunExperiment(NVExperimentKind kind, NSDictionary<NSString *, NSNumber *> *params);
NSString *NVHardwareDescription(void);

NS_ASSUME_NONNULL_END
