import 'dart:math' as math;

import '../movement/finger_movement_analyzer.dart';
import 'baseline_calibration.dart';

enum CalibrationDirection { increasingFlexion, decreasingFlexion }

enum ComfortableMovementStatus {
  collecting,
  recommendationReady,
  movementNotSeparatedFromNoise,
  trackingUnavailable,
  outOfOrderSample,
}

class ComfortableMovementConfig {
  ComfortableMovementConfig({
    this.minimumStableDuration = const Duration(milliseconds: 1500),
    this.maximumSampleGap = const Duration(milliseconds: 350),
    this.minimumSamples = 6,
    this.noiseMultiplier = 3,
    this.minimumMovementDegrees = 4,
    this.thresholdFraction = 0.5,
  }) {
    if (minimumStableDuration <= Duration.zero ||
        maximumSampleGap <= Duration.zero) {
      throw ArgumentError('Calibration durations must be positive.');
    }
    if (minimumSamples < 2) {
      throw ArgumentError('At least two movement samples are required.');
    }
    if (!noiseMultiplier.isFinite || noiseMultiplier <= 0) {
      throw ArgumentError('The noise multiplier must be finite and positive.');
    }
    if (!minimumMovementDegrees.isFinite || minimumMovementDegrees <= 0) {
      throw ArgumentError('The minimum movement must be finite and positive.');
    }
    if (!thresholdFraction.isFinite ||
        thresholdFraction <= 0 ||
        thresholdFraction >= 1) {
      throw ArgumentError('The threshold fraction must be between 0 and 1.');
    }
  }

  final Duration minimumStableDuration;
  final Duration maximumSampleGap;
  final int minimumSamples;
  final double noiseMultiplier;
  final double minimumMovementDegrees;
  final double thresholdFraction;
}

class CalibrationThresholdRecommendation {
  const CalibrationThresholdRecommendation({
    required this.movementType,
    required this.direction,
    required this.baselineDegrees,
    required this.noiseEstimateDegrees,
    required this.noiseFloorDegrees,
    required this.comfortableValueDegrees,
    required this.movementAmplitudeDegrees,
    required this.thresholdDegrees,
    required this.thresholdOffsetDegrees,
    required this.timestamp,
  });

  static const unitName = FingerMovementReading.unitName;

  final CalibrationMovementType movementType;
  final CalibrationDirection direction;
  final double baselineDegrees;
  final double noiseEstimateDegrees;
  final double noiseFloorDegrees;
  final double comfortableValueDegrees;
  final double movementAmplitudeDegrees;
  final double thresholdDegrees;
  final double thresholdOffsetDegrees;
  final Duration timestamp;

  String get units => unitName;

  bool get isReliable =>
      thresholdOffsetDegrees >= noiseFloorDegrees &&
      thresholdOffsetDegrees < movementAmplitudeDegrees;
}

class ComfortableMovementAssessment {
  const ComfortableMovementAssessment({
    required this.timestamp,
    required this.status,
    required this.message,
    required this.stableSampleCount,
    required this.stableDuration,
    this.detectedDirection,
    this.observedAmplitudeDegrees,
    this.noiseFloorDegrees,
    this.reliableOffsetFloorDegrees,
    this.recommendation,
  });

  final Duration timestamp;
  final ComfortableMovementStatus status;
  final String message;
  final int stableSampleCount;
  final Duration stableDuration;
  final CalibrationDirection? detectedDirection;
  final double? observedAmplitudeDegrees;
  final double? noiseFloorDegrees;
  final double? reliableOffsetFloorDegrees;
  final CalibrationThresholdRecommendation? recommendation;

  bool get hasReliableRecommendation =>
      status == ComfortableMovementStatus.recommendationReady &&
      recommendation?.isReliable == true;
}

/// Observes one comfortable movement attempt and compares it with an already
/// accepted rest baseline. It stores angles and timestamps only.
class ComfortableMovementCalibrationSession {
  ComfortableMovementCalibrationSession({
    required this.baseline,
    ComfortableMovementConfig? config,
  }) : config = config ?? ComfortableMovementConfig() {
    if (!baseline.baselineDegrees.isFinite ||
        !baseline.noiseEstimateDegrees.isFinite ||
        baseline.noiseEstimateDegrees < 0) {
      throw ArgumentError('The accepted baseline contains invalid values.');
    }
  }

  final CalibrationBaseline baseline;
  final ComfortableMovementConfig config;

  final List<_MovementSample> _samples = [];
  Duration? _lastEventTimestamp;
  ComfortableMovementAssessment? _completedAssessment;

  ComfortableMovementAssessment accept(FingerMovementReading reading) {
    final completedAssessment = _completedAssessment;
    if (completedAssessment != null) {
      return completedAssessment;
    }

    final timestamp = reading.timestamp;
    final lastEventTimestamp = _lastEventTimestamp;
    final angle = reading.flexionDegrees;
    if (!reading.isValid || angle == null || !angle.isFinite) {
      if (lastEventTimestamp == null || timestamp > lastEventTimestamp) {
        _lastEventTimestamp = timestamp;
      }
      _samples.clear();
      return _assessment(
        timestamp: timestamp,
        status: ComfortableMovementStatus.trackingUnavailable,
        message:
            'Tracking paused. Reposition the camera or hand when comfortable.',
      );
    }

    if (lastEventTimestamp != null && timestamp <= lastEventTimestamp) {
      return _assessment(
        timestamp: timestamp,
        status: ComfortableMovementStatus.outOfOrderSample,
        message: 'A delayed tracking sample was ignored.',
      );
    }
    _lastEventTimestamp = timestamp;

    final previousTimestamp = _samples.isEmpty ? null : _samples.last.timestamp;
    if (previousTimestamp != null &&
        timestamp - previousTimestamp > config.maximumSampleGap) {
      _samples.clear();
    }
    _samples.add(_MovementSample(timestamp: timestamp, angleDegrees: angle));

    final stableDuration = _stableDuration;
    if (_samples.length < config.minimumSamples ||
        stableDuration < config.minimumStableDuration) {
      return _assessment(
        timestamp: timestamp,
        status: ComfortableMovementStatus.collecting,
        message:
            'Make one comfortable movement when ready. Do not push farther.',
      );
    }

    final deviations = _samples
        .map((sample) => sample.angleDegrees - baseline.baselineDegrees)
        .toList();
    final increasingAmplitude = math.max(0.0, _percentile(deviations, 0.9));
    final decreasingAmplitude = math.max(0.0, -_percentile(deviations, 0.1));
    final direction = increasingAmplitude >= decreasingAmplitude
        ? CalibrationDirection.increasingFlexion
        : CalibrationDirection.decreasingFlexion;
    final amplitude = direction == CalibrationDirection.increasingFlexion
        ? increasingAmplitude
        : decreasingAmplitude;
    final noiseFloor = baseline.noiseEstimateDegrees * config.noiseMultiplier;
    final reliableOffsetFloor = math.max(
      noiseFloor,
      config.minimumMovementDegrees,
    );

    if (amplitude <= reliableOffsetFloor) {
      final assessment = _assessment(
        timestamp: timestamp,
        status: ComfortableMovementStatus.movementNotSeparatedFromNoise,
        message:
            'This comfortable movement was not clearly separated from normal '
            'signal variation. Retry or use a caregiver-adjusted setting.',
        detectedDirection: direction,
        observedAmplitudeDegrees: amplitude,
        noiseFloorDegrees: noiseFloor,
        reliableOffsetFloorDegrees: reliableOffsetFloor,
      );
      _completedAssessment = assessment;
      return assessment;
    }

    final thresholdOffset = math.max(
      reliableOffsetFloor,
      amplitude * config.thresholdFraction,
    );
    final sign = direction == CalibrationDirection.increasingFlexion ? 1 : -1;
    final recommendation = CalibrationThresholdRecommendation(
      movementType: baseline.movementType,
      direction: direction,
      baselineDegrees: baseline.baselineDegrees,
      noiseEstimateDegrees: baseline.noiseEstimateDegrees,
      noiseFloorDegrees: noiseFloor,
      comfortableValueDegrees: baseline.baselineDegrees + sign * amplitude,
      movementAmplitudeDegrees: amplitude,
      thresholdDegrees: baseline.baselineDegrees + sign * thresholdOffset,
      thresholdOffsetDegrees: thresholdOffset,
      timestamp: timestamp,
    );
    final assessment = _assessment(
      timestamp: timestamp,
      status: ComfortableMovementStatus.recommendationReady,
      message:
          'A starting threshold is available for caregiver review. It does '
          'not require a larger movement.',
      detectedDirection: direction,
      observedAmplitudeDegrees: amplitude,
      noiseFloorDegrees: noiseFloor,
      reliableOffsetFloorDegrees: reliableOffsetFloor,
      recommendation: recommendation,
    );
    _completedAssessment = assessment;
    return assessment;
  }

  void reset() {
    _samples.clear();
    _lastEventTimestamp = null;
    _completedAssessment = null;
  }

  ComfortableMovementAssessment _assessment({
    required Duration timestamp,
    required ComfortableMovementStatus status,
    required String message,
    CalibrationDirection? detectedDirection,
    double? observedAmplitudeDegrees,
    double? noiseFloorDegrees,
    double? reliableOffsetFloorDegrees,
    CalibrationThresholdRecommendation? recommendation,
  }) {
    return ComfortableMovementAssessment(
      timestamp: timestamp,
      status: status,
      message: message,
      stableSampleCount: _samples.length,
      stableDuration: _stableDuration,
      detectedDirection: detectedDirection,
      observedAmplitudeDegrees: observedAmplitudeDegrees,
      noiseFloorDegrees: noiseFloorDegrees,
      reliableOffsetFloorDegrees: reliableOffsetFloorDegrees,
      recommendation: recommendation,
    );
  }

  Duration get _stableDuration {
    if (_samples.length < 2) {
      return Duration.zero;
    }
    return _samples.last.timestamp - _samples.first.timestamp;
  }

  double _percentile(List<double> values, double fraction) {
    final sorted = [...values]..sort();
    final position = (sorted.length - 1) * fraction;
    final lowerIndex = position.floor();
    final upperIndex = position.ceil();
    if (lowerIndex == upperIndex) {
      return sorted[lowerIndex];
    }
    final weight = position - lowerIndex;
    return sorted[lowerIndex] * (1 - weight) + sorted[upperIndex] * weight;
  }
}

class _MovementSample {
  const _MovementSample({required this.timestamp, required this.angleDegrees});

  final Duration timestamp;
  final double angleDegrees;
}
