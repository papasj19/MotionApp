import 'dart:math' as math;

import 'package:adaptive_motion_arcade/movement/body_movement_analyzer.dart';
import 'package:adaptive_motion_arcade/movement/movement_measurement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const frame = MovementFrameGeometry(
    imageWidth: 1000,
    imageHeight: 1000,
    rotationDegrees: 0,
    isMirrored: false,
  );

  group('HeadTiltMovementAnalyzer', () {
    test('measures signed left and right eye-line tilt', () {
      final analyzer = HeadTiltMovementAnalyzer();
      final rise = math.tan(20 * math.pi / 180) * 0.4;

      final reading = analyzer.analyze(
        HeadTiltObservation(
          timestamp: Duration.zero,
          firstEyeCorner: const MovementPoint(x: 0.3, y: 0.4),
          secondEyeCorner: MovementPoint(x: 0.7, y: 0.4 + rise),
          frame: frame,
        ),
      );

      expect(reading.isValid, isTrue);
      expect(reading.rawValueDegrees, closeTo(20, 0.001));
      expect(reading.movementType, CalibrationMovementType.headTilt);
    });

    test('mirrored preview reverses direction but preserves magnitude', () {
      final rise = math.tan(15 * math.pi / 180) * 0.4;
      final normal = HeadTiltMovementAnalyzer().analyze(
        HeadTiltObservation(
          timestamp: Duration.zero,
          firstEyeCorner: const MovementPoint(x: 0.3, y: 0.4),
          secondEyeCorner: MovementPoint(x: 0.7, y: 0.4 + rise),
          frame: frame,
        ),
      );
      final mirrored = HeadTiltMovementAnalyzer().analyze(
        HeadTiltObservation(
          timestamp: Duration.zero,
          firstEyeCorner: const MovementPoint(x: 0.3, y: 0.4),
          secondEyeCorner: MovementPoint(x: 0.7, y: 0.4 + rise),
          frame: const MovementFrameGeometry(
            imageWidth: 1000,
            imageHeight: 1000,
            rotationDegrees: 0,
            isMirrored: true,
          ),
        ),
      );

      expect(mirrored.rawValueDegrees, closeTo(-normal.rawValueDegrees!, 1e-9));
    });

    test('corrects landmark coordinates for camera rotation', () {
      final reading = HeadTiltMovementAnalyzer().analyze(
        const HeadTiltObservation(
          timestamp: Duration.zero,
          firstEyeCorner: MovementPoint(x: 0.5, y: 0.7),
          secondEyeCorner: MovementPoint(x: 0.5, y: 0.3),
          frame: MovementFrameGeometry(
            imageWidth: 1000,
            imageHeight: 600,
            rotationDegrees: 90,
            isMirrored: false,
          ),
        ),
      );

      expect(reading.rawValueDegrees, closeTo(0, 1e-9));
    });

    test('rejects eye corners that are too close to be dependable', () {
      final reading = HeadTiltMovementAnalyzer().analyze(
        const HeadTiltObservation(
          timestamp: Duration.zero,
          firstEyeCorner: MovementPoint(x: 0.5, y: 0.5),
          secondEyeCorner: MovementPoint(x: 0.501, y: 0.5),
          frame: frame,
        ),
      );

      expect(reading.isValid, isFalse);
      expect(reading.validity, BodyMovementValidity.degenerateGeometry);
    });
  });

  group('WristBendMovementAnalyzer', () {
    test('defines a straight wrist as zero degrees', () {
      final reading = WristBendMovementAnalyzer().analyze(
        const WristBendObservation(
          timestamp: Duration.zero,
          elbow: MovementPoint(x: 0.2, y: 0.5),
          poseWrist: MovementPoint(x: 0.5, y: 0.5),
          handWrist: MovementPoint(x: 0.5, y: 0.5),
          middleFingerBase: MovementPoint(x: 0.8, y: 0.5),
          frame: frame,
        ),
      );

      expect(reading.isValid, isTrue);
      expect(reading.rawValueDegrees, closeTo(0, 1e-9));
    });

    test('measures wrist bend magnitude in either direction', () {
      WristBendObservation observation(double handY) => WristBendObservation(
        timestamp: Duration.zero,
        elbow: const MovementPoint(x: 0.2, y: 0.5),
        poseWrist: const MovementPoint(x: 0.5, y: 0.5),
        handWrist: const MovementPoint(x: 0.5, y: 0.5),
        middleFingerBase: MovementPoint(x: 0.5, y: handY),
        frame: frame,
      );

      final down = WristBendMovementAnalyzer().analyze(observation(0.8));
      final up = WristBendMovementAnalyzer().analyze(observation(0.2));

      expect(down.rawValueDegrees, closeTo(90, 1e-9));
      expect(up.rawValueDegrees, closeTo(90, 1e-9));
      expect(down.movementType, CalibrationMovementType.wristBend);
    });

    test('requires visible hand and forearm segment length', () {
      final reading = WristBendMovementAnalyzer().analyze(
        const WristBendObservation(
          timestamp: Duration.zero,
          elbow: MovementPoint(x: 0.5, y: 0.5),
          poseWrist: MovementPoint(x: 0.501, y: 0.5),
          handWrist: MovementPoint(x: 0.5, y: 0.5),
          middleFingerBase: MovementPoint(x: 0.8, y: 0.5),
          frame: frame,
        ),
      );

      expect(reading.isValid, isFalse);
      expect(reading.note, contains('elbow'));
    });
  });
}
