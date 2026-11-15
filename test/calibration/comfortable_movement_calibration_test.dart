import 'package:adaptive_motion_arcade/calibration/baseline_calibration.dart';
import 'package:adaptive_motion_arcade/calibration/comfortable_movement_calibration.dart';
import 'package:adaptive_motion_arcade/movement/finger_movement_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComfortableMovementConfig', () {
    test('rejects unsafe tuning values', () {
      expect(
        () => ComfortableMovementConfig(minimumSamples: 1),
        throwsArgumentError,
      );
      expect(
        () => ComfortableMovementConfig(noiseMultiplier: 0),
        throwsArgumentError,
      );
      expect(
        () => ComfortableMovementConfig(thresholdFraction: 1),
        throwsArgumentError,
      );
    });
  });

  group('ComfortableMovementCalibrationSession', () {
    test('recommends an increasing-flexion threshold above noise', () {
      final session = ComfortableMovementCalibrationSession(
        baseline: _baseline(angle: 20, noise: 1),
      );

      final assessment = _completeAttempt(session, const [
        20,
        22,
        25,
        28,
        30,
        30,
        30,
      ]);

      expect(assessment.status, ComfortableMovementStatus.recommendationReady);
      expect(assessment.hasReliableRecommendation, isTrue);
      final recommendation = assessment.recommendation!;
      expect(recommendation.direction, CalibrationDirection.increasingFlexion);
      expect(recommendation.movementAmplitudeDegrees, closeTo(10, 0.01));
      expect(recommendation.noiseFloorDegrees, closeTo(3, 0.01));
      expect(recommendation.thresholdOffsetDegrees, closeTo(5, 0.01));
      expect(recommendation.thresholdDegrees, closeTo(25, 0.01));
      expect(recommendation.comfortableValueDegrees, closeTo(30, 0.01));
      expect(recommendation.units, 'degrees');
      expect(assessment.message, contains('does not require a larger'));
    });

    test('detects decreasing flexion and preserves the threshold sign', () {
      final session = ComfortableMovementCalibrationSession(
        baseline: _baseline(angle: 40, noise: 1),
      );

      final assessment = _completeAttempt(session, const [
        40,
        38,
        35,
        32,
        30,
        30,
        30,
      ]);

      final recommendation = assessment.recommendation!;
      expect(recommendation.direction, CalibrationDirection.decreasingFlexion);
      expect(recommendation.movementAmplitudeDegrees, closeTo(10, 0.01));
      expect(recommendation.thresholdOffsetDegrees, closeTo(5, 0.01));
      expect(recommendation.thresholdDegrees, closeTo(35, 0.01));
      expect(recommendation.comfortableValueDegrees, closeTo(30, 0.01));
      expect(recommendation.isReliable, isTrue);
    });

    test('does not recommend a threshold for a tiny movement', () {
      final session = ComfortableMovementCalibrationSession(
        baseline: _baseline(angle: 20, noise: 0.5),
      );

      final assessment = _completeAttempt(session, const [
        20,
        20.5,
        21,
        21.5,
        22,
        22,
        22,
      ]);

      expect(
        assessment.status,
        ComfortableMovementStatus.movementNotSeparatedFromNoise,
      );
      expect(assessment.hasReliableRecommendation, isFalse);
      expect(assessment.recommendation, isNull);
      expect(assessment.observedAmplitudeDegrees, closeTo(2, 0.01));
      expect(assessment.noiseFloorDegrees, closeTo(1.5, 0.01));
      expect(assessment.reliableOffsetFloorDegrees, closeTo(4, 0.01));
    });

    test('does not recommend movement hidden by baseline noise', () {
      final session = ComfortableMovementCalibrationSession(
        baseline: _baseline(angle: 20, noise: 4),
      );

      final assessment = _completeAttempt(session, const [
        20,
        22,
        25,
        28,
        30,
        30,
        30,
      ]);

      expect(
        assessment.status,
        ComfortableMovementStatus.movementNotSeparatedFromNoise,
      );
      expect(assessment.observedAmplitudeDegrees, closeTo(10, 0.01));
      expect(assessment.noiseFloorDegrees, closeTo(12, 0.01));
      expect(assessment.reliableOffsetFloorDegrees, closeTo(12, 0.01));
      expect(assessment.recommendation, isNull);
    });

    test('reports no signal and clears a partial movement attempt', () {
      final session = ComfortableMovementCalibrationSession(
        baseline: _baseline(angle: 20, noise: 1),
      );
      session.accept(_reading(3000, 20));
      session.accept(_reading(3250, 25));

      final lost = session.accept(
        FingerMovementReading.unavailable(
          timestamp: Duration.zero,
          validity: FingerMovementValidity.missingObservation,
          note: 'No hand observation is available.',
        ),
      );
      final reacquired = session.accept(_reading(3750, 30));

      expect(lost.status, ComfortableMovementStatus.trackingUnavailable);
      expect(lost.stableSampleCount, 0);
      expect(lost.message, isNot(contains('failed')));
      expect(reacquired.status, ComfortableMovementStatus.collecting);
      expect(reacquired.stableSampleCount, 1);
      expect(reacquired.stableDuration, Duration.zero);
    });

    test('ignores an out-of-order sample without changing direction data', () {
      final session = ComfortableMovementCalibrationSession(
        baseline: _baseline(angle: 20, noise: 1),
      );
      session.accept(_reading(3000, 20));
      session.accept(_reading(3250, 24));

      final delayed = session.accept(_reading(3100, 5));
      final continued = session.accept(_reading(3500, 28));

      expect(delayed.status, ComfortableMovementStatus.outOfOrderSample);
      expect(delayed.stableSampleCount, 2);
      expect(continued.stableSampleCount, 3);
      expect(continued.stableDuration, const Duration(milliseconds: 500));
    });

    test('keeps a completed recommendation fixed until reset', () {
      final session = ComfortableMovementCalibrationSession(
        baseline: _baseline(angle: 20, noise: 1),
      );
      final completed = _completeAttempt(session, const [
        20,
        22,
        25,
        28,
        30,
        30,
        30,
      ]);

      final later = session.accept(_reading(5000, 80));

      expect(later, same(completed));
      expect(later.recommendation!.thresholdDegrees, closeTo(25, 0.01));
    });

    test('rejects a nonfinite or negative-noise baseline', () {
      expect(
        () => ComfortableMovementCalibrationSession(
          baseline: _baseline(angle: double.nan, noise: 1),
        ),
        throwsArgumentError,
      );
      expect(
        () => ComfortableMovementCalibrationSession(
          baseline: _baseline(angle: 20, noise: -1),
        ),
        throwsArgumentError,
      );
    });
  });
}

ComfortableMovementAssessment _completeAttempt(
  ComfortableMovementCalibrationSession session,
  List<double> angles,
) {
  ComfortableMovementAssessment? assessment;
  for (var index = 0; index < angles.length; index++) {
    assessment = session.accept(_reading(3000 + index * 250, angles[index]));
  }
  return assessment!;
}

CalibrationBaseline _baseline({required double angle, required double noise}) {
  return CalibrationBaseline(
    movementType: CalibrationMovementType.indexFingerPipFlexion,
    baselineDegrees: angle,
    noiseEstimateDegrees: noise,
    sampleCount: 9,
    stableDuration: const Duration(seconds: 2),
    startedAt: Duration.zero,
    completedAt: const Duration(seconds: 2),
  );
}

FingerMovementReading _reading(int milliseconds, double angleDegrees) {
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
