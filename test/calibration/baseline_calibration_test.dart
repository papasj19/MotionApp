import 'package:adaptive_motion_arcade/calibration/baseline_calibration.dart';
import 'package:adaptive_motion_arcade/movement/finger_movement_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BaselineCalibrationConfig', () {
    test('rejects unsafe tuning values', () {
      expect(
        () => BaselineCalibrationConfig(minimumSamples: 1),
        throwsArgumentError,
      );
      expect(
        () => BaselineCalibrationConfig(maximumNoiseDegrees: 0),
        throwsArgumentError,
      );
      expect(
        () => BaselineCalibrationConfig(minimumStableDuration: Duration.zero),
        throwsArgumentError,
      );
    });
  });

  group('BaselineCalibrationSession', () {
    test('measures a stable rest baseline over elapsed time', () {
      final session = BaselineCalibrationSession();
      const angles = [20.0, 20.2, 19.8, 20.1, 19.9, 20.0, 20.2, 19.8, 20.0];

      BaselineCalibrationAssessment? assessment;
      for (var index = 0; index < angles.length; index++) {
        assessment = session.accept(_validReading(index * 250, angles[index]));
      }

      expect(assessment!.status, BaselineCalibrationStatus.ready);
      expect(assessment.isReady, isTrue);
      expect(assessment.stableDuration, const Duration(seconds: 2));
      expect(assessment.baseline!.baselineDegrees, closeTo(20, 0.01));
      expect(assessment.baseline!.noiseEstimateDegrees, lessThan(0.3));
      expect(assessment.baseline!.sampleCount, angles.length);
      expect(assessment.baseline!.units, 'degrees');
      expect(
        assessment.baseline!.movementType,
        CalibrationMovementType.indexFingerPipFlexion,
      );

      final afterCompletion = session.accept(_validReading(2250, 80));
      expect(afterCompletion, same(assessment));
      expect(afterCompletion.baseline!.baselineDegrees, closeTo(20, 0.01));
    });

    test('reports unavailable tracking without blaming the user', () {
      final session = BaselineCalibrationSession();

      final assessment = session.accept(
        FingerMovementReading.unavailable(
          timestamp: const Duration(milliseconds: 100),
          validity: FingerMovementValidity.missingObservation,
          note: 'No hand observation is available.',
        ),
      );

      expect(assessment.status, BaselineCalibrationStatus.trackingUnavailable);
      expect(assessment.baseline, isNull);
      expect(assessment.stableSampleCount, 0);
      expect(assessment.message, isNot(contains('failed')));
    });

    test('does not label a noisy baseline ready', () {
      final session = BaselineCalibrationSession();
      const angles = [10.0, 15.0, 20.0, 25.0, 30.0, 35.0, 40.0, 45.0, 50.0];

      BaselineCalibrationAssessment? assessment;
      for (var index = 0; index < angles.length; index++) {
        assessment = session.accept(_validReading(index * 250, angles[index]));
      }

      expect(assessment!.status, BaselineCalibrationStatus.signalTooVariable);
      expect(assessment.isReady, isFalse);
      expect(assessment.baseline!.noiseEstimateDegrees, greaterThan(6));
      expect(assessment.message, contains('caregiver-adjusted'));
    });

    test('tracking loss clears the partial stable interval', () {
      final session = BaselineCalibrationSession();
      for (var index = 0; index < 7; index++) {
        session.accept(_validReading(index * 250, 25));
      }

      final lost = session.accept(
        FingerMovementReading.unavailable(
          timestamp: const Duration(milliseconds: 1750),
          validity: FingerMovementValidity.missingObservation,
          note: 'No hand observation is available.',
        ),
      );
      final reacquired = session.accept(_validReading(2000, 25));

      expect(lost.status, BaselineCalibrationStatus.trackingUnavailable);
      expect(lost.stableSampleCount, 0);
      expect(reacquired.status, BaselineCalibrationStatus.collecting);
      expect(reacquired.stableSampleCount, 1);
      expect(reacquired.stableDuration, Duration.zero);
    });

    test('a long sample gap starts a new stable interval', () {
      final session = BaselineCalibrationSession();
      session.accept(_validReading(0, 25));
      session.accept(_validReading(250, 25));

      final assessment = session.accept(_validReading(1000, 25));

      expect(assessment.status, BaselineCalibrationStatus.collecting);
      expect(assessment.stableSampleCount, 1);
      expect(assessment.stableDuration, Duration.zero);
    });

    test('an out-of-order sample is ignored without corrupting progress', () {
      final session = BaselineCalibrationSession();
      session.accept(_validReading(0, 25));
      session.accept(_validReading(250, 25));

      final delayed = session.accept(_validReading(100, 80));
      final continued = session.accept(_validReading(500, 25));

      expect(delayed.status, BaselineCalibrationStatus.outOfOrderSample);
      expect(delayed.stableSampleCount, 2);
      expect(continued.stableSampleCount, 3);
      expect(continued.stableDuration, const Duration(milliseconds: 500));
    });

    test('reset removes all prior timing and baseline samples', () {
      final session = BaselineCalibrationSession();
      session.accept(_validReading(1000, 25));

      session.reset();
      final assessment = session.accept(_validReading(100, 30));

      expect(assessment.status, BaselineCalibrationStatus.collecting);
      expect(assessment.stableSampleCount, 1);
      expect(assessment.stableDuration, Duration.zero);
    });
  });
}

FingerMovementReading _validReading(int milliseconds, double angleDegrees) {
  return FingerMovementReading(
    timestamp: Duration(milliseconds: milliseconds),
    validity: FingerMovementValidity.valid,
    quality: MovementQualityMetadata(
      quality: MovementSignalQuality.good,
      notes: const [],
    ),
    state: FingerMotionState.stationary,
    flexionDegrees: angleDegrees,
    rawFlexionDegrees: angleDegrees,
    velocityDegreesPerSecond: 0,
  );
}
