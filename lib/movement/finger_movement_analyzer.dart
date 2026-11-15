import 'dart:math' as math;

import '../hand_tracking/hand_observation.dart';

enum FingerMovementValidity {
  valid,
  trackingUnavailable,
  missingObservation,
  nonFiniteLandmarks,
  degenerateGeometry,
  outOfOrderTimestamp,
}

enum MovementSignalQuality { good, caution, invalid }

enum FingerMotionState { stationary, flexing, extending, unavailable }

class FingerMovementAnalyzerConfig {
  FingerMovementAnalyzerConfig({
    this.smoothingTimeConstant = const Duration(milliseconds: 120),
    this.resetAfterGap = const Duration(milliseconds: 500),
    this.minimumBoneToPalmRatio = 0.03,
    this.cautionBoneToPalmRatio = 0.08,
    this.motionDeadbandDegreesPerSecond = 5,
    this.cautionReportedLandmarkScore = 0.25,
  }) {
    if (smoothingTimeConstant <= Duration.zero ||
        resetAfterGap <= Duration.zero) {
      throw ArgumentError('Smoothing and gap durations must be positive.');
    }
    if (!minimumBoneToPalmRatio.isFinite ||
        minimumBoneToPalmRatio <= 0 ||
        !cautionBoneToPalmRatio.isFinite ||
        cautionBoneToPalmRatio < minimumBoneToPalmRatio) {
      throw ArgumentError('Bone-to-palm ratio limits are invalid.');
    }
    if (!motionDeadbandDegreesPerSecond.isFinite ||
        motionDeadbandDegreesPerSecond < 0) {
      throw ArgumentError(
        'The motion deadband must be finite and nonnegative.',
      );
    }
    if (!cautionReportedLandmarkScore.isFinite ||
        cautionReportedLandmarkScore < 0 ||
        cautionReportedLandmarkScore > 1) {
      throw ArgumentError('The landmark score threshold must be from 0 to 1.');
    }
  }

  final Duration smoothingTimeConstant;
  final Duration resetAfterGap;
  final double minimumBoneToPalmRatio;
  final double cautionBoneToPalmRatio;
  final double motionDeadbandDegreesPerSecond;
  final double cautionReportedLandmarkScore;
}

class MovementQualityMetadata {
  MovementQualityMetadata({
    required this.quality,
    required List<String> notes,
    this.sampleInterval,
    this.minimumBoneToPalmRatio,
    this.minimumReportedLandmarkScore,
    this.smoothingApplied = false,
    this.reacquired = false,
  }) : notes = List.unmodifiable(notes);

  final MovementSignalQuality quality;
  final List<String> notes;
  final Duration? sampleInterval;
  final double? minimumBoneToPalmRatio;
  final double? minimumReportedLandmarkScore;
  final bool smoothingApplied;
  final bool reacquired;
}

class FingerMovementReading {
  const FingerMovementReading({
    required this.timestamp,
    required this.validity,
    required this.quality,
    required this.state,
    this.flexionDegrees,
    this.rawFlexionDegrees,
    this.velocityDegreesPerSecond,
  });

  factory FingerMovementReading.unavailable({
    required Duration timestamp,
    required FingerMovementValidity validity,
    required String note,
  }) {
    return FingerMovementReading(
      timestamp: timestamp,
      validity: validity,
      quality: MovementQualityMetadata(
        quality: MovementSignalQuality.invalid,
        notes: [note],
      ),
      state: FingerMotionState.unavailable,
    );
  }

  static const unitName = 'degrees';

  final Duration timestamp;
  final FingerMovementValidity validity;
  final MovementQualityMetadata quality;
  final FingerMotionState state;
  final double? flexionDegrees;
  final double? rawFlexionDegrees;
  final double? velocityDegreesPerSecond;

  bool get isValid => validity == FingerMovementValidity.valid;
  String get units => unitName;
}

class IndexFingerMovementAnalyzer {
  IndexFingerMovementAnalyzer({FingerMovementAnalyzerConfig? config})
    : config = config ?? FingerMovementAnalyzerConfig();

  static const wristIndex = 0;
  static const indexMcpIndex = 5;
  static const indexPipIndex = 6;
  static const indexDipIndex = 7;
  static const middleMcpIndex = 9;

  final FingerMovementAnalyzerConfig config;

  Duration? _lastEventTimestamp;
  Duration? _lastValidTimestamp;
  double? _smoothedFlexionDegrees;
  bool _needsReacquisition = true;

  FingerMovementReading analyze(HandObservation observation) {
    final timestamp = observation.timestamp;
    if (!_isTimestampOrdered(timestamp)) {
      return FingerMovementReading.unavailable(
        timestamp: timestamp,
        validity: FingerMovementValidity.outOfOrderTimestamp,
        note: 'This frame arrived out of timestamp order and was ignored.',
      );
    }
    _lastEventTimestamp = timestamp;

    final geometry = _analyzeGeometry(observation);
    if (!geometry.isValid) {
      _clearTemporalState();
      return FingerMovementReading.unavailable(
        timestamp: timestamp,
        validity: geometry.validity,
        note: geometry.note,
      );
    }

    final previousTimestamp = _lastValidTimestamp;
    final previousSmoothed = _smoothedFlexionDegrees;
    final sampleInterval = previousTimestamp == null
        ? null
        : timestamp - previousTimestamp;
    final reacquired =
        _needsReacquisition ||
        previousTimestamp == null ||
        previousSmoothed == null ||
        sampleInterval! >= config.resetAfterGap;

    final rawFlexion = geometry.flexionDegrees!;
    final double smoothedFlexion;
    final double? velocity;
    if (reacquired) {
      smoothedFlexion = rawFlexion;
      velocity = null;
    } else {
      final intervalSeconds =
          sampleInterval.inMicroseconds / Duration.microsecondsPerSecond;
      final timeConstantSeconds =
          config.smoothingTimeConstant.inMicroseconds /
          Duration.microsecondsPerSecond;
      final alpha = 1 - math.exp(-intervalSeconds / timeConstantSeconds);
      smoothedFlexion =
          previousSmoothed + alpha * (rawFlexion - previousSmoothed);
      velocity = (smoothedFlexion - previousSmoothed) / intervalSeconds;
    }

    _lastValidTimestamp = timestamp;
    _smoothedFlexionDegrees = smoothedFlexion;
    _needsReacquisition = false;

    final notes = <String>[];
    if (reacquired) {
      notes.add(
        'Temporal smoothing restarted because tracking began or resumed.',
      );
    }
    if (geometry.minimumBoneToPalmRatio! < config.cautionBoneToPalmRatio) {
      notes.add('Finger landmarks are close together relative to the palm.');
    }
    final reportedScore = geometry.minimumReportedLandmarkScore;
    if (reportedScore != null &&
        reportedScore < config.cautionReportedLandmarkScore) {
      notes.add(
        'The detector reported a low landmark visibility or presence value.',
      );
    }

    final quality = notes.isEmpty
        ? MovementSignalQuality.good
        : MovementSignalQuality.caution;
    return FingerMovementReading(
      timestamp: timestamp,
      validity: FingerMovementValidity.valid,
      quality: MovementQualityMetadata(
        quality: quality,
        notes: notes,
        sampleInterval: sampleInterval,
        minimumBoneToPalmRatio: geometry.minimumBoneToPalmRatio,
        minimumReportedLandmarkScore: geometry.minimumReportedLandmarkScore,
        smoothingApplied: !reacquired,
        reacquired: reacquired,
      ),
      state: _motionStateFor(velocity),
      flexionDegrees: _withoutNegativeZero(smoothedFlexion),
      rawFlexionDegrees: _withoutNegativeZero(rawFlexion),
      velocityDegreesPerSecond: velocity,
    );
  }

  FingerMovementReading markMissing(Duration timestamp) {
    if (!_isTimestampOrdered(timestamp)) {
      return FingerMovementReading.unavailable(
        timestamp: timestamp,
        validity: FingerMovementValidity.outOfOrderTimestamp,
        note: 'This missing-hand update arrived out of timestamp order.',
      );
    }
    _lastEventTimestamp = timestamp;
    _clearTemporalState();
    return FingerMovementReading.unavailable(
      timestamp: timestamp,
      validity: FingerMovementValidity.missingObservation,
      note: 'No hand observation is available.',
    );
  }

  void reset() {
    _lastEventTimestamp = null;
    _clearTemporalState();
  }

  bool _isTimestampOrdered(Duration timestamp) {
    final lastTimestamp = _lastEventTimestamp;
    return lastTimestamp == null || timestamp > lastTimestamp;
  }

  void _clearTemporalState() {
    _lastValidTimestamp = null;
    _smoothedFlexionDegrees = null;
    _needsReacquisition = true;
  }

  FingerMotionState _motionStateFor(double? velocity) {
    if (velocity == null ||
        velocity.abs() < config.motionDeadbandDegreesPerSecond) {
      return FingerMotionState.stationary;
    }
    return velocity > 0
        ? FingerMotionState.flexing
        : FingerMotionState.extending;
  }

  _GeometryAnalysis _analyzeGeometry(HandObservation observation) {
    final indexes = [
      wristIndex,
      indexMcpIndex,
      indexPipIndex,
      indexDipIndex,
      middleMcpIndex,
    ];
    final points = <int, _Vector3>{};
    final scores = <double>[];
    final yScale = observation.imageHeight / observation.imageWidth;

    for (final index in indexes) {
      final landmark = observation.landmarks[index];
      final values = [
        landmark.x,
        landmark.y,
        landmark.z,
        landmark.visibility,
        landmark.presence,
      ];
      if (values.whereType<double>().any((value) => !value.isFinite)) {
        return const _GeometryAnalysis.invalid(
          FingerMovementValidity.nonFiniteLandmarks,
          'A required landmark contains a nonfinite value.',
        );
      }
      points[index] = _Vector3(landmark.x, landmark.y * yScale, landmark.z);
      if (landmark.visibility != null) {
        scores.add(landmark.visibility!);
      }
      if (landmark.presence != null) {
        scores.add(landmark.presence!);
      }
    }

    final palmScale = (points[middleMcpIndex]! - points[wristIndex]!).length;
    final proximal = points[indexMcpIndex]! - points[indexPipIndex]!;
    final distal = points[indexDipIndex]! - points[indexPipIndex]!;
    if (!palmScale.isFinite || palmScale <= 1e-9) {
      return const _GeometryAnalysis.invalid(
        FingerMovementValidity.degenerateGeometry,
        'The palm reference has zero or unusable length.',
      );
    }

    final proximalRatio = proximal.length / palmScale;
    final distalRatio = distal.length / palmScale;
    final minimumRatio = math.min(proximalRatio, distalRatio);
    if (!minimumRatio.isFinite ||
        minimumRatio < config.minimumBoneToPalmRatio) {
      return const _GeometryAnalysis.invalid(
        FingerMovementValidity.degenerateGeometry,
        'The index-finger joint vectors are too short for a stable angle.',
      );
    }

    final denominator = proximal.length * distal.length;
    final cosine = (proximal.dot(distal) / denominator).clamp(-1.0, 1.0);
    final jointAngleDegrees = math.acos(cosine) * 180 / math.pi;
    final flexionDegrees = 180 - jointAngleDegrees;
    if (!flexionDegrees.isFinite) {
      return const _GeometryAnalysis.invalid(
        FingerMovementValidity.nonFiniteLandmarks,
        'The index-finger angle could not be calculated.',
      );
    }

    return _GeometryAnalysis.valid(
      flexionDegrees: flexionDegrees.clamp(0, 180),
      minimumBoneToPalmRatio: minimumRatio,
      minimumReportedLandmarkScore: scores.isEmpty
          ? null
          : scores.reduce(math.min),
    );
  }

  double _withoutNegativeZero(double value) {
    return value.abs() < 1e-9 ? 0 : value;
  }
}

class _GeometryAnalysis {
  const _GeometryAnalysis.valid({
    required this.flexionDegrees,
    required this.minimumBoneToPalmRatio,
    required this.minimumReportedLandmarkScore,
  }) : isValid = true,
       validity = FingerMovementValidity.valid,
       note = '';

  const _GeometryAnalysis.invalid(this.validity, this.note)
    : isValid = false,
      flexionDegrees = null,
      minimumBoneToPalmRatio = null,
      minimumReportedLandmarkScore = null;

  final bool isValid;
  final FingerMovementValidity validity;
  final String note;
  final double? flexionDegrees;
  final double? minimumBoneToPalmRatio;
  final double? minimumReportedLandmarkScore;
}

class _Vector3 {
  const _Vector3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  _Vector3 operator -(_Vector3 other) {
    return _Vector3(x - other.x, y - other.y, z - other.z);
  }

  double dot(_Vector3 other) => x * other.x + y * other.y + z * other.z;

  double get length => math.sqrt(dot(this));
}
