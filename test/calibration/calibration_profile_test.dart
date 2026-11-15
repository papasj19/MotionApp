import 'package:adaptive_motion_arcade/calibration/baseline_calibration.dart';
import 'package:adaptive_motion_arcade/calibration/calibration_profile.dart';
import 'package:adaptive_motion_arcade/calibration/comfortable_movement_calibration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const portraitContext = CalibrationSetupContext(
    orientation: CalibrationDeviceOrientation.portrait,
  );
  final completedAt = DateTime.utc(2026, 11, 15, 12);

  test('accepts an unchanged reliable automatic recommendation', () {
    final editor = CalibrationProfileEditor.fromRecommendation(
      _recommendation(),
    );

    final result = editor.validate(
      direction: editor.initialDirection,
      thresholdOffsetDegrees: editor.initialThresholdOffsetDegrees,
      completedAt: completedAt,
      setupContext: portraitContext,
    );

    expect(result.isReliable, isTrue);
    expect(result.profile!.thresholdDegrees, 25);
    expect(result.profile!.thresholdOffsetDegrees, 5);
    expect(result.profile!.noiseFloorDegrees, 3);
    expect(result.profile!.units, 'degrees');
    expect(
      result.profile!.thresholdSource,
      CalibrationThresholdSource.automaticRecommendation,
    );
    expect(result.profile!.completedAt, completedAt);
    expect(result.profile!.setupContext.previewMirrored, isTrue);
  });

  test('records caregiver direction and sensitivity adjustments', () {
    final editor = CalibrationProfileEditor.fromRecommendation(
      _recommendation(),
    );

    final result = editor.validate(
      direction: CalibrationDirection.decreasingFlexion,
      thresholdOffsetDegrees: 4,
      completedAt: completedAt,
      setupContext: const CalibrationSetupContext(
        orientation: CalibrationDeviceOrientation.landscape,
      ),
    );

    expect(result.isReliable, isTrue);
    expect(result.profile!.thresholdDegrees, 16);
    expect(result.profile!.direction, CalibrationDirection.decreasingFlexion);
    expect(
      result.profile!.thresholdSource,
      CalibrationThresholdSource.caregiverAdjusted,
    );
    expect(
      result.profile!.setupContext.orientation,
      CalibrationDeviceOrientation.landscape,
    );
  });

  test('never labels a threshold below the noise floor reliable', () {
    final editor = CalibrationProfileEditor.fromRecommendation(
      _recommendation(),
    );

    final result = editor.validate(
      direction: CalibrationDirection.increasingFlexion,
      thresholdOffsetDegrees: 2.9,
      completedAt: completedAt,
      setupContext: portraitContext,
    );

    expect(result.status, CalibrationValidationStatus.belowNoiseFloor);
    expect(result.isReliable, isFalse);
    expect(result.profile, isNull);
    expect(result.message, contains('noise floor'));
  });

  test('rejects a threshold beyond observed comfortable movement', () {
    final editor = CalibrationProfileEditor.fromRecommendation(
      _recommendation(),
    );

    final result = editor.validate(
      direction: CalibrationDirection.increasingFlexion,
      thresholdOffsetDegrees: 10.1,
      completedAt: completedAt,
      setupContext: portraitContext,
    );

    expect(result.status, CalibrationValidationStatus.beyondObservedComfort);
    expect(result.isReliable, isFalse);
    expect(result.profile, isNull);
  });

  test('supports a caregiver-validated manual fallback above noise', () {
    final editor = CalibrationProfileEditor.manualFallback(
      baseline: _baseline(),
      direction: CalibrationDirection.increasingFlexion,
      comfortableAmplitudeDegrees: 3,
      noiseFloorDegrees: 1.5,
      sampleTimestamp: const Duration(seconds: 4),
    );

    final result = editor.validate(
      direction: editor.initialDirection,
      thresholdOffsetDegrees: editor.initialThresholdOffsetDegrees,
      completedAt: completedAt,
      setupContext: portraitContext,
    );

    expect(result.isReliable, isTrue);
    expect(result.profile!.thresholdOffsetDegrees, 1.5);
    expect(
      result.profile!.thresholdSource,
      CalibrationThresholdSource.manualFallback,
    );
  });

  test('manual fallback requires movement above measured noise', () {
    expect(
      () => CalibrationProfileEditor.manualFallback(
        baseline: _baseline(),
        direction: CalibrationDirection.increasingFlexion,
        comfortableAmplitudeDegrees: 2,
        noiseFloorDegrees: 2,
        sampleTimestamp: const Duration(seconds: 4),
      ),
      throwsArgumentError,
    );
  });

  test('rejects direction settings outside the 0 to 180 degree signal', () {
    final editor = CalibrationProfileEditor.manualFallback(
      baseline: _baseline(angle: 2),
      direction: CalibrationDirection.decreasingFlexion,
      comfortableAmplitudeDegrees: 5,
      noiseFloorDegrees: 1,
      sampleTimestamp: const Duration(seconds: 4),
    );

    final result = editor.validate(
      direction: CalibrationDirection.decreasingFlexion,
      thresholdOffsetDegrees: 3,
      completedAt: completedAt,
      setupContext: portraitContext,
    );

    expect(result.status, CalibrationValidationStatus.outsideSignalRange);
    expect(result.isReliable, isFalse);
  });
}

CalibrationThresholdRecommendation _recommendation() {
  return const CalibrationThresholdRecommendation(
    movementType: CalibrationMovementType.indexFingerPipFlexion,
    direction: CalibrationDirection.increasingFlexion,
    baselineDegrees: 20,
    noiseEstimateDegrees: 1,
    noiseFloorDegrees: 3,
    comfortableValueDegrees: 30,
    movementAmplitudeDegrees: 10,
    thresholdDegrees: 25,
    thresholdOffsetDegrees: 5,
    timestamp: Duration(seconds: 4),
  );
}

CalibrationBaseline _baseline({double angle = 20}) {
  return CalibrationBaseline(
    movementType: CalibrationMovementType.indexFingerPipFlexion,
    baselineDegrees: angle,
    noiseEstimateDegrees: 0.5,
    sampleCount: 9,
    stableDuration: const Duration(seconds: 2),
    startedAt: Duration.zero,
    completedAt: const Duration(seconds: 2),
  );
}
