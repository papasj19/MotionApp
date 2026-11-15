import '../movement/finger_movement_analyzer.dart';

enum CalibrationMovementType { indexFingerPipFlexion }

enum BaselineCalibrationStatus {
  collecting,
  ready,
  trackingUnavailable,
  signalTooVariable,
  outOfOrderSample,
}

class BaselineCalibrationConfig {
  BaselineCalibrationConfig({
    this.minimumStableDuration = const Duration(seconds: 2),
    this.maximumSampleGap = const Duration(milliseconds: 350),
    this.minimumSamples = 8,
    this.maximumNoiseDegrees = 6,
  }) {
    if (minimumStableDuration <= Duration.zero ||
        maximumSampleGap <= Duration.zero) {
      throw ArgumentError('Calibration durations must be positive.');
    }
    if (minimumSamples < 2) {
      throw ArgumentError('At least two baseline samples are required.');
    }
    if (!maximumNoiseDegrees.isFinite || maximumNoiseDegrees <= 0) {
      throw ArgumentError('The noise limit must be finite and positive.');
    }
  }

  final Duration minimumStableDuration;
  final Duration maximumSampleGap;
  final int minimumSamples;
  final double maximumNoiseDegrees;
}

class CalibrationBaseline {
  const CalibrationBaseline({
    required this.movementType,
    required this.baselineDegrees,
    required this.noiseEstimateDegrees,
    required this.sampleCount,
    required this.stableDuration,
    required this.startedAt,
    required this.completedAt,
  });

  static const unitName = FingerMovementReading.unitName;

  final CalibrationMovementType movementType;
  final double baselineDegrees;
  final double noiseEstimateDegrees;
  final int sampleCount;
  final Duration stableDuration;
  final Duration startedAt;
  final Duration completedAt;

  String get units => unitName;
}

class BaselineCalibrationAssessment {
  const BaselineCalibrationAssessment({
    required this.timestamp,
    required this.status,
    required this.message,
    required this.stableSampleCount,
    required this.stableDuration,
    this.baseline,
  });

  final Duration timestamp;
  final BaselineCalibrationStatus status;
  final String message;
  final int stableSampleCount;
  final Duration stableDuration;
  final CalibrationBaseline? baseline;

  bool get isReady => status == BaselineCalibrationStatus.ready;
}

/// Collects a continuous, time-bounded rest sample without retaining camera
/// frames or hand landmarks.
class BaselineCalibrationSession {
  BaselineCalibrationSession({BaselineCalibrationConfig? config})
    : config = config ?? BaselineCalibrationConfig();

  final BaselineCalibrationConfig config;

  final List<_BaselineSample> _samples = [];
  Duration? _lastEventTimestamp;
  BaselineCalibrationAssessment? _completedAssessment;

  BaselineCalibrationAssessment accept(FingerMovementReading reading) {
    final completedAssessment = _completedAssessment;
    if (completedAssessment != null) {
      return completedAssessment;
    }

    final timestamp = reading.timestamp;
    final lastEventTimestamp = _lastEventTimestamp;
    if (lastEventTimestamp != null && timestamp <= lastEventTimestamp) {
      return _assessment(
        timestamp: timestamp,
        status: BaselineCalibrationStatus.outOfOrderSample,
        message: 'A delayed tracking sample was ignored.',
      );
    }
    _lastEventTimestamp = timestamp;

    final angle = reading.flexionDegrees;
    if (!reading.isValid || angle == null || !angle.isFinite) {
      _samples.clear();
      return _assessment(
        timestamp: timestamp,
        status: BaselineCalibrationStatus.trackingUnavailable,
        message:
            'Tracking paused. Reposition the camera or hand when comfortable.',
      );
    }

    final previousTimestamp = _samples.isEmpty ? null : _samples.last.timestamp;
    if (previousTimestamp != null &&
        timestamp - previousTimestamp > config.maximumSampleGap) {
      _samples.clear();
    }
    _samples.add(_BaselineSample(timestamp: timestamp, angleDegrees: angle));

    final stableDuration = _stableDuration;
    if (_samples.length < config.minimumSamples ||
        stableDuration < config.minimumStableDuration) {
      return _assessment(
        timestamp: timestamp,
        status: BaselineCalibrationStatus.collecting,
        message:
            'Keep the hand comfortably at rest while the baseline is measured.',
      );
    }

    final angles = _samples.map((sample) => sample.angleDegrees).toList();
    final baselineDegrees = _median(angles);
    final absoluteDeviations = angles
        .map((angle) => (angle - baselineDegrees).abs())
        .toList();
    final noiseEstimateDegrees = 1.4826 * _median(absoluteDeviations);
    final baseline = CalibrationBaseline(
      movementType: CalibrationMovementType.indexFingerPipFlexion,
      baselineDegrees: baselineDegrees,
      noiseEstimateDegrees: noiseEstimateDegrees,
      sampleCount: _samples.length,
      stableDuration: stableDuration,
      startedAt: _samples.first.timestamp,
      completedAt: timestamp,
    );

    if (noiseEstimateDegrees > config.maximumNoiseDegrees) {
      final assessment = _assessment(
        timestamp: timestamp,
        status: BaselineCalibrationStatus.signalTooVariable,
        message:
            'The resting signal is too variable for an automatic setting. '
            'Try again or use a caregiver-adjusted setting.',
        baseline: baseline,
      );
      _completedAssessment = assessment;
      return assessment;
    }

    final assessment = _assessment(
      timestamp: timestamp,
      status: BaselineCalibrationStatus.ready,
      message: 'The resting signal is stable enough to continue.',
      baseline: baseline,
    );
    _completedAssessment = assessment;
    return assessment;
  }

  void reset() {
    _samples.clear();
    _lastEventTimestamp = null;
    _completedAssessment = null;
  }

  BaselineCalibrationAssessment _assessment({
    required Duration timestamp,
    required BaselineCalibrationStatus status,
    required String message,
    CalibrationBaseline? baseline,
  }) {
    return BaselineCalibrationAssessment(
      timestamp: timestamp,
      status: status,
      message: message,
      stableSampleCount: _samples.length,
      stableDuration: _stableDuration,
      baseline: baseline,
    );
  }

  Duration get _stableDuration {
    if (_samples.length < 2) {
      return Duration.zero;
    }
    return _samples.last.timestamp - _samples.first.timestamp;
  }

  double _median(List<double> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length ~/ 2;
    if (sorted.length.isOdd) {
      return sorted[middle];
    }
    return (sorted[middle - 1] + sorted[middle]) / 2;
  }
}

class _BaselineSample {
  const _BaselineSample({required this.timestamp, required this.angleDegrees});

  final Duration timestamp;
  final double angleDegrees;
}
