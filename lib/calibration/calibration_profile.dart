import 'dart:math' as math;

import '../movement/movement_measurement.dart';
import 'baseline_calibration.dart';
import 'comfortable_movement_calibration.dart';

enum CalibrationDeviceOrientation { portrait, landscape }

enum CalibrationCameraFacing { front }

class CalibrationSetupContext {
  const CalibrationSetupContext({
    required this.orientation,
    this.cameraFacing = CalibrationCameraFacing.front,
    this.previewMirrored = true,
  });

  final CalibrationDeviceOrientation orientation;
  final CalibrationCameraFacing cameraFacing;
  final bool previewMirrored;
}

enum CalibrationThresholdSource {
  automaticRecommendation,
  caregiverAdjusted,
  manualFallback,
}

enum CalibrationValidationStatus {
  valid,
  invalidNumber,
  belowNoiseFloor,
  beyondObservedComfort,
  outsideSignalRange,
}

class CalibrationProfile {
  const CalibrationProfile({
    required this.movementType,
    required this.baselineDegrees,
    required this.noiseEstimateDegrees,
    required this.noiseFloorDegrees,
    required this.comfortableAmplitudeDegrees,
    required this.thresholdDegrees,
    required this.thresholdOffsetDegrees,
    required this.direction,
    required this.thresholdSource,
    required this.sampleTimestamp,
    required this.completedAt,
    required this.setupContext,
  });

  static const unitName = 'degrees';

  final CalibrationMovementType movementType;
  final double baselineDegrees;
  final double noiseEstimateDegrees;
  final double noiseFloorDegrees;
  final double comfortableAmplitudeDegrees;
  final double thresholdDegrees;
  final double thresholdOffsetDegrees;
  final CalibrationDirection direction;
  final CalibrationThresholdSource thresholdSource;
  final Duration sampleTimestamp;
  final DateTime completedAt;
  final CalibrationSetupContext setupContext;

  String get units => unitName;
}

class CalibrationValidationResult {
  const CalibrationValidationResult({
    required this.status,
    required this.message,
    this.profile,
  });

  final CalibrationValidationStatus status;
  final String message;
  final CalibrationProfile? profile;

  bool get isReliable =>
      status == CalibrationValidationStatus.valid && profile != null;
}

class CalibrationProfileEditor {
  CalibrationProfileEditor._({
    required this.movementType,
    required this.baselineDegrees,
    required this.noiseEstimateDegrees,
    required this.noiseFloorDegrees,
    required this.comfortableAmplitudeDegrees,
    required this.initialDirection,
    required this.initialThresholdOffsetDegrees,
    required this.sampleTimestamp,
    required this.isManualFallback,
  });

  factory CalibrationProfileEditor.fromRecommendation(
    CalibrationThresholdRecommendation recommendation,
  ) {
    final values = [
      recommendation.baselineDegrees,
      recommendation.noiseEstimateDegrees,
      recommendation.noiseFloorDegrees,
      recommendation.movementAmplitudeDegrees,
      recommendation.thresholdOffsetDegrees,
    ];
    if (!recommendation.isReliable ||
        values.any((value) => !value.isFinite) ||
        recommendation.baselineDegrees <
            recommendation.movementType.minimumDegrees ||
        recommendation.baselineDegrees >
            recommendation.movementType.maximumDegrees ||
        recommendation.noiseEstimateDegrees < 0 ||
        recommendation.noiseFloorDegrees < 0) {
      throw ArgumentError('The automatic recommendation is not reliable.');
    }
    return CalibrationProfileEditor._(
      movementType: recommendation.movementType,
      baselineDegrees: recommendation.baselineDegrees,
      noiseEstimateDegrees: recommendation.noiseEstimateDegrees,
      noiseFloorDegrees: recommendation.noiseFloorDegrees,
      comfortableAmplitudeDegrees: recommendation.movementAmplitudeDegrees,
      initialDirection: recommendation.direction,
      initialThresholdOffsetDegrees: recommendation.thresholdOffsetDegrees,
      sampleTimestamp: recommendation.timestamp,
      isManualFallback: false,
    );
  }

  factory CalibrationProfileEditor.manualFallback({
    required CalibrationBaseline baseline,
    required CalibrationDirection direction,
    required double comfortableAmplitudeDegrees,
    required double noiseFloorDegrees,
    required Duration sampleTimestamp,
  }) {
    final values = [
      baseline.baselineDegrees,
      baseline.noiseEstimateDegrees,
      comfortableAmplitudeDegrees,
      noiseFloorDegrees,
    ];
    if (values.any((value) => !value.isFinite) ||
        baseline.baselineDegrees < baseline.movementType.minimumDegrees ||
        baseline.baselineDegrees > baseline.movementType.maximumDegrees ||
        baseline.noiseEstimateDegrees < 0 ||
        comfortableAmplitudeDegrees <= noiseFloorDegrees ||
        noiseFloorDegrees < 0) {
      throw ArgumentError(
        'Manual calibration needs comfortable movement above the noise floor.',
      );
    }
    return CalibrationProfileEditor._(
      movementType: baseline.movementType,
      baselineDegrees: baseline.baselineDegrees,
      noiseEstimateDegrees: baseline.noiseEstimateDegrees,
      noiseFloorDegrees: noiseFloorDegrees,
      comfortableAmplitudeDegrees: comfortableAmplitudeDegrees,
      initialDirection: direction,
      initialThresholdOffsetDegrees: math.max(
        noiseFloorDegrees,
        comfortableAmplitudeDegrees * 0.5,
      ),
      sampleTimestamp: sampleTimestamp,
      isManualFallback: true,
    );
  }

  final CalibrationMovementType movementType;
  final double baselineDegrees;
  final double noiseEstimateDegrees;
  final double noiseFloorDegrees;
  final double comfortableAmplitudeDegrees;
  final CalibrationDirection initialDirection;
  final double initialThresholdOffsetDegrees;
  final Duration sampleTimestamp;
  final bool isManualFallback;

  double get minimumThresholdOffsetDegrees => noiseFloorDegrees;
  double get maximumThresholdOffsetDegrees => comfortableAmplitudeDegrees;

  CalibrationValidationResult validate({
    required CalibrationDirection direction,
    required double thresholdOffsetDegrees,
    required DateTime completedAt,
    required CalibrationSetupContext setupContext,
  }) {
    if (!thresholdOffsetDegrees.isFinite) {
      return const CalibrationValidationResult(
        status: CalibrationValidationStatus.invalidNumber,
        message: 'Choose a valid sensitivity setting.',
      );
    }
    if (thresholdOffsetDegrees < noiseFloorDegrees) {
      return CalibrationValidationResult(
        status: CalibrationValidationStatus.belowNoiseFloor,
        message:
            'This setting is below the measured noise floor of '
            '${noiseFloorDegrees.toStringAsFixed(1)}°. Increase the threshold '
            'or retry calibration.',
      );
    }
    if (thresholdOffsetDegrees > comfortableAmplitudeDegrees) {
      return const CalibrationValidationResult(
        status: CalibrationValidationStatus.beyondObservedComfort,
        message:
            'This setting is beyond the comfortable movement that was '
            'observed. Lower the threshold or retry calibration.',
      );
    }

    final sign = direction == CalibrationDirection.increasingFlexion ? 1 : -1;
    final thresholdDegrees = baselineDegrees + sign * thresholdOffsetDegrees;
    if (thresholdDegrees < movementType.minimumDegrees ||
        thresholdDegrees > movementType.maximumDegrees) {
      return const CalibrationValidationResult(
        status: CalibrationValidationStatus.outsideSignalRange,
        message:
            'This direction and sensitivity are outside the measured signal '
            'range. Change the setting or retry calibration.',
      );
    }

    final unchangedAutomaticSetting =
        !isManualFallback &&
        direction == initialDirection &&
        (thresholdOffsetDegrees - initialThresholdOffsetDegrees).abs() < 1e-9;
    final source = isManualFallback
        ? CalibrationThresholdSource.manualFallback
        : unchangedAutomaticSetting
        ? CalibrationThresholdSource.automaticRecommendation
        : CalibrationThresholdSource.caregiverAdjusted;
    return CalibrationValidationResult(
      status: CalibrationValidationStatus.valid,
      message: 'This setting is above noise and within observed comfort.',
      profile: CalibrationProfile(
        movementType: movementType,
        baselineDegrees: baselineDegrees,
        noiseEstimateDegrees: noiseEstimateDegrees,
        noiseFloorDegrees: noiseFloorDegrees,
        comfortableAmplitudeDegrees: comfortableAmplitudeDegrees,
        thresholdDegrees: thresholdDegrees,
        thresholdOffsetDegrees: thresholdOffsetDegrees,
        direction: direction,
        thresholdSource: source,
        sampleTimestamp: sampleTimestamp,
        completedAt: completedAt,
        setupContext: setupContext,
      ),
    );
  }
}
