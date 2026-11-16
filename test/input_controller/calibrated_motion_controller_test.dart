import 'package:adaptive_motion_arcade/calibration/calibration_profile.dart';
import 'package:adaptive_motion_arcade/calibration/comfortable_movement_calibration.dart';
import 'package:adaptive_motion_arcade/input_controller/calibrated_motion_controller.dart';
import 'package:adaptive_motion_arcade/input_controller/motion_input_controller.dart';
import 'package:adaptive_motion_arcade/movement/movement_measurement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalibratedMotionController', () {
    test('maps increasing movement away from the calibrated baseline', () {
      final controller = CalibratedMotionController(
        profile: _profile(
          movementType: CalibrationMovementType.indexFingerBend,
          baseline: 20,
          direction: CalibrationDirection.increasingFlexion,
        ),
      );

      expect(controller.accept(_reading(0, 20)), isEmpty);
      final events = controller.accept(_reading(100, 30));

      expect(controller.signalFor(_reading(100, 30)), 10);
      expect(events.map((event) => event.type), [
        MotionInputEventType.actionDown,
        MotionInputEventType.primaryAction,
      ]);
    });

    test('maps decreasing head movement into the same positive signal', () {
      final controller = CalibratedMotionController(
        profile: _profile(
          movementType: CalibrationMovementType.headTilt,
          baseline: 5,
          direction: CalibrationDirection.decreasingFlexion,
        ),
      );

      controller.accept(_reading(0, 5));
      final events = controller.accept(_reading(100, -5));

      expect(controller.signalFor(_reading(100, -5)), 10);
      expect(events.map((event) => event.type), [
        MotionInputEventType.actionDown,
        MotionInputEventType.primaryAction,
      ]);
    });

    test('requires rest before the first action', () {
      final controller = CalibratedMotionController(
        profile: _profile(
          movementType: CalibrationMovementType.wristBend,
          baseline: 20,
          direction: CalibrationDirection.increasingFlexion,
        ),
      );

      final openedWhileHeld = controller.accept(_reading(0, 30));
      final stillHeld = controller.accept(_reading(100, 30));
      controller.accept(_reading(200, 20));
      final deliberateAction = controller.accept(_reading(300, 30));

      expect(openedWhileHeld, isEmpty);
      expect(stillHeld, isEmpty);
      expect(deliberateAction.map((event) => event.type), [
        MotionInputEventType.actionDown,
        MotionInputEventType.primaryAction,
      ]);
    });

    test('turns an invalid reading into safe tracking loss', () {
      final controller = CalibratedMotionController(
        profile: _profile(
          movementType: CalibrationMovementType.indexFingerBend,
          baseline: 20,
          direction: CalibrationDirection.increasingFlexion,
        ),
      );
      controller.accept(_reading(0, 20));
      controller.accept(_reading(100, 30));

      final events = controller.accept(_reading(200, null));

      expect(events.map((event) => event.type), [
        MotionInputEventType.actionUp,
        MotionInputEventType.trackingLost,
      ]);
      expect(controller.trackingState, MotionTrackingState.lost);
    });

    test('rejects an unsafe release threshold ratio', () {
      expect(
        () => CalibratedMotionController(
          profile: _profile(
            movementType: CalibrationMovementType.indexFingerBend,
            baseline: 20,
            direction: CalibrationDirection.increasingFlexion,
          ),
          releaseThresholdRatio: 1,
        ),
        throwsArgumentError,
      );
    });
  });
}

CalibrationProfile _profile({
  required CalibrationMovementType movementType,
  required double baseline,
  required CalibrationDirection direction,
}) {
  final sign = direction == CalibrationDirection.increasingFlexion ? 1 : -1;
  return CalibrationProfile(
    movementType: movementType,
    baselineDegrees: baseline,
    noiseEstimateDegrees: 1,
    noiseFloorDegrees: 2,
    comfortableAmplitudeDegrees: 15,
    thresholdDegrees: baseline + sign * 10,
    thresholdOffsetDegrees: 10,
    direction: direction,
    thresholdSource: CalibrationThresholdSource.automaticRecommendation,
    sampleTimestamp: Duration.zero,
    completedAt: DateTime.utc(2026, 11, 16),
    setupContext: const CalibrationSetupContext(
      orientation: CalibrationDeviceOrientation.portrait,
    ),
  );
}

class _Reading implements MovementMeasurement {
  const _Reading({required this.timestamp, required this.valueDegrees});

  @override
  final Duration timestamp;
  @override
  final double? valueDegrees;

  @override
  bool get isValid => valueDegrees != null;
}

_Reading _reading(int milliseconds, double? valueDegrees) {
  return _Reading(
    timestamp: Duration(milliseconds: milliseconds),
    valueDegrees: valueDegrees,
  );
}
