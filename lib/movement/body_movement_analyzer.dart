import 'dart:math' as math;

import 'movement_measurement.dart';

enum BodyMovementValidity {
  valid,
  missingObservation,
  nonFiniteLandmarks,
  degenerateGeometry,
  outOfOrderTimestamp,
  trackingUnavailable,
}

class MovementPoint {
  const MovementPoint({
    required this.x,
    required this.y,
    this.visibility,
    this.presence,
  });

  final double x;
  final double y;
  final double? visibility;
  final double? presence;
}

class MovementFrameGeometry {
  const MovementFrameGeometry({
    required this.imageWidth,
    required this.imageHeight,
    required this.rotationDegrees,
    required this.isMirrored,
  });

  final int imageWidth;
  final int imageHeight;
  final int rotationDegrees;
  final bool isMirrored;
}

class HeadTiltObservation {
  const HeadTiltObservation({
    required this.timestamp,
    required this.firstEyeCorner,
    required this.secondEyeCorner,
    required this.frame,
  });

  final Duration timestamp;
  final MovementPoint firstEyeCorner;
  final MovementPoint secondEyeCorner;
  final MovementFrameGeometry frame;
}

class WristBendObservation {
  const WristBendObservation({
    required this.timestamp,
    required this.elbow,
    required this.poseWrist,
    required this.handWrist,
    required this.middleFingerBase,
    required this.frame,
  });

  final Duration timestamp;
  final MovementPoint elbow;
  final MovementPoint poseWrist;
  final MovementPoint handWrist;
  final MovementPoint middleFingerBase;
  final MovementFrameGeometry frame;
}

class BodyMovementReading implements MovementMeasurement {
  const BodyMovementReading({
    required this.timestamp,
    required this.validity,
    required this.movementType,
    required this.note,
    this.valueDegrees,
    this.rawValueDegrees,
    this.minimumReportedLandmarkScore,
  });

  factory BodyMovementReading.unavailable({
    required Duration timestamp,
    required CalibrationMovementType movementType,
    required BodyMovementValidity validity,
    required String note,
  }) {
    return BodyMovementReading(
      timestamp: timestamp,
      validity: validity,
      movementType: movementType,
      note: note,
    );
  }

  @override
  final Duration timestamp;
  final BodyMovementValidity validity;
  final CalibrationMovementType movementType;
  final String note;
  @override
  final double? valueDegrees;
  final double? rawValueDegrees;
  final double? minimumReportedLandmarkScore;

  @override
  bool get isValid => validity == BodyMovementValidity.valid;
}

class BodyMovementAnalyzerConfig {
  const BodyMovementAnalyzerConfig({
    this.smoothingTimeConstant = const Duration(milliseconds: 120),
    this.resetAfterGap = const Duration(milliseconds: 500),
    this.minimumSegmentPixels = 8,
    this.cautionLandmarkScore = 0.25,
  });

  final Duration smoothingTimeConstant;
  final Duration resetAfterGap;
  final double minimumSegmentPixels;
  final double cautionLandmarkScore;
}

class HeadTiltMovementAnalyzer extends _BodyAngleAnalyzer {
  HeadTiltMovementAnalyzer({super.config});

  BodyMovementReading analyze(HeadTiltObservation observation) {
    return analyzeAngle(
      timestamp: observation.timestamp,
      movementType: CalibrationMovementType.headTilt,
      points: [observation.firstEyeCorner, observation.secondEyeCorner],
      calculate: () {
        final first = _mapPoint(observation.firstEyeCorner, observation.frame);
        final second = _mapPoint(
          observation.secondEyeCorner,
          observation.frame,
        );
        final left = first.x <= second.x ? first : second;
        final right = first.x <= second.x ? second : first;
        final dx = right.x - left.x;
        final dy = right.y - left.y;
        final eyeDistance = math.sqrt(dx * dx + dy * dy);
        if (eyeDistance < config.minimumSegmentPixels) {
          return null;
        }
        return math.atan2(dy, dx) * 180 / math.pi;
      },
      degenerateNote:
          'Move the camera closer so both eyes can be tracked clearly.',
    );
  }
}

class WristBendMovementAnalyzer extends _BodyAngleAnalyzer {
  WristBendMovementAnalyzer({super.config});

  BodyMovementReading analyze(WristBendObservation observation) {
    return analyzeAngle(
      timestamp: observation.timestamp,
      movementType: CalibrationMovementType.wristBend,
      points: [
        observation.elbow,
        observation.poseWrist,
        observation.handWrist,
        observation.middleFingerBase,
      ],
      calculate: () {
        final elbow = _mapPoint(observation.elbow, observation.frame);
        final poseWrist = _mapPoint(observation.poseWrist, observation.frame);
        final handWrist = _mapPoint(observation.handWrist, observation.frame);
        final middleBase = _mapPoint(
          observation.middleFingerBase,
          observation.frame,
        );

        final forearmX = poseWrist.x - elbow.x;
        final forearmY = poseWrist.y - elbow.y;
        final handX = middleBase.x - handWrist.x;
        final handY = middleBase.y - handWrist.y;
        final forearmLength = math.sqrt(
          forearmX * forearmX + forearmY * forearmY,
        );
        final handLength = math.sqrt(handX * handX + handY * handY);
        if (forearmLength < config.minimumSegmentPixels ||
            handLength < config.minimumSegmentPixels) {
          return null;
        }

        final dot = forearmX * handX + forearmY * handY;
        final cross = forearmX * handY - forearmY * handX;
        return math.atan2(cross.abs(), dot) * 180 / math.pi;
      },
      degenerateNote:
          'Show the full hand, wrist, forearm, and elbow more clearly.',
    );
  }
}

abstract class _BodyAngleAnalyzer {
  _BodyAngleAnalyzer({BodyMovementAnalyzerConfig? config})
    : config = config ?? const BodyMovementAnalyzerConfig();

  final BodyMovementAnalyzerConfig config;
  Duration? _lastTimestamp;
  Duration? _lastValidTimestamp;
  double? _smoothedValue;

  BodyMovementReading analyzeAngle({
    required Duration timestamp,
    required CalibrationMovementType movementType,
    required List<MovementPoint> points,
    required double? Function() calculate,
    required String degenerateNote,
  }) {
    final lastTimestamp = _lastTimestamp;
    if (lastTimestamp != null && timestamp <= lastTimestamp) {
      return BodyMovementReading.unavailable(
        timestamp: timestamp,
        movementType: movementType,
        validity: BodyMovementValidity.outOfOrderTimestamp,
        note: 'A delayed tracking frame was ignored.',
      );
    }
    _lastTimestamp = timestamp;

    if (points.any((point) => !point.x.isFinite || !point.y.isFinite)) {
      _clearSmoothing();
      return BodyMovementReading.unavailable(
        timestamp: timestamp,
        movementType: movementType,
        validity: BodyMovementValidity.nonFiniteLandmarks,
        note: 'The tracker returned invalid landmark coordinates.',
      );
    }

    final rawValue = calculate();
    if (rawValue == null || !rawValue.isFinite) {
      _clearSmoothing();
      return BodyMovementReading.unavailable(
        timestamp: timestamp,
        movementType: movementType,
        validity: BodyMovementValidity.degenerateGeometry,
        note: degenerateNote,
      );
    }

    final previousTimestamp = _lastValidTimestamp;
    final previousValue = _smoothedValue;
    final gap = previousTimestamp == null
        ? null
        : timestamp - previousTimestamp;
    final reacquired =
        gap == null || gap >= config.resetAfterGap || previousValue == null;
    final smoothed = reacquired
        ? rawValue
        : previousValue +
              (1 -
                      math.exp(
                        -gap.inMicroseconds /
                            config.smoothingTimeConstant.inMicroseconds,
                      )) *
                  (rawValue - previousValue);
    _lastValidTimestamp = timestamp;
    _smoothedValue = smoothed;

    final reportedScores = points
        .expand((point) => [point.visibility, point.presence])
        .whereType<double>()
        .where((score) => score.isFinite)
        .toList();
    final minimumScore = reportedScores.isEmpty
        ? null
        : reportedScores.reduce(math.min);
    final caution =
        minimumScore != null && minimumScore < config.cautionLandmarkScore;
    return BodyMovementReading(
      timestamp: timestamp,
      validity: BodyMovementValidity.valid,
      movementType: movementType,
      note: caution
          ? 'Some landmarks have low reported visibility.'
          : 'Movement tracking is clear.',
      valueDegrees: _withoutNegativeZero(smoothed),
      rawValueDegrees: _withoutNegativeZero(rawValue),
      minimumReportedLandmarkScore: minimumScore,
    );
  }

  BodyMovementReading markMissing({
    required Duration timestamp,
    required CalibrationMovementType movementType,
    required String note,
  }) {
    final lastTimestamp = _lastTimestamp;
    if (lastTimestamp != null && timestamp <= lastTimestamp) {
      return BodyMovementReading.unavailable(
        timestamp: timestamp,
        movementType: movementType,
        validity: BodyMovementValidity.outOfOrderTimestamp,
        note: 'A delayed missing-tracking update was ignored.',
      );
    }
    _lastTimestamp = timestamp;
    _clearSmoothing();
    return BodyMovementReading.unavailable(
      timestamp: timestamp,
      movementType: movementType,
      validity: BodyMovementValidity.missingObservation,
      note: note,
    );
  }

  void reset() {
    _lastTimestamp = null;
    _clearSmoothing();
  }

  void _clearSmoothing() {
    _lastValidTimestamp = null;
    _smoothedValue = null;
  }
}

class _PixelPoint {
  const _PixelPoint(this.x, this.y);

  final double x;
  final double y;
}

_PixelPoint _mapPoint(MovementPoint point, MovementFrameGeometry frame) {
  final (rotatedX, rotatedY) = switch (frame.rotationDegrees) {
    0 => (point.x, point.y),
    90 => (1 - point.y, point.x),
    180 => (1 - point.x, 1 - point.y),
    270 => (point.y, 1 - point.x),
    _ => throw ArgumentError.value(
      frame.rotationDegrees,
      'rotationDegrees',
      'Rotation must be 0, 90, 180, or 270.',
    ),
  };
  final x = frame.isMirrored ? 1 - rotatedX : rotatedX;
  final width = frame.rotationDegrees == 90 || frame.rotationDegrees == 270
      ? frame.imageHeight
      : frame.imageWidth;
  final height = frame.rotationDegrees == 90 || frame.rotationDegrees == 270
      ? frame.imageWidth
      : frame.imageHeight;
  return _PixelPoint(x * width, rotatedY * height);
}

double _withoutNegativeZero(double value) => value == 0 ? 0 : value;
