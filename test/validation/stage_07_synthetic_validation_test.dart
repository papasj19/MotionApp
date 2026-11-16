import 'package:adaptive_motion_arcade/calibration/calibration_profile.dart';
import 'package:adaptive_motion_arcade/calibration/comfortable_movement_calibration.dart';
import 'package:adaptive_motion_arcade/input_controller/calibrated_motion_controller.dart';
import 'package:adaptive_motion_arcade/input_controller/motion_input_controller.dart';
import 'package:adaptive_motion_arcade/movement/movement_measurement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Stage 7 synthetic gate rejects jitter and accepts ten movements', () {
    final controller = CalibratedMotionController(profile: _profile());
    final events = <MotionInputEvent>[];

    events.addAll(controller.accept(_reading(0, 20)));
    for (var index = 1; index <= 300; index++) {
      final jitter = switch (index % 4) {
        0 => -1.0,
        1 => -0.3,
        2 => 0.4,
        _ => 1.0,
      };
      events.addAll(controller.accept(_reading(index * 100, 20 + jitter)));
    }

    expect(_primaryActions(events), 0);

    var timestamp = 30100;
    for (var repetition = 0; repetition < 10; repetition++) {
      events.addAll(controller.accept(_reading(timestamp, 23)));
      timestamp += 80;
      events.addAll(controller.accept(_reading(timestamp, 31)));
      timestamp += 120;
      events.addAll(controller.accept(_reading(timestamp, 32)));
      timestamp += 100;
      events.addAll(controller.accept(_reading(timestamp, 20)));
      timestamp += 100;
    }

    expect(_primaryActions(events), 10);
    expect(
      events.where((event) => event.type == MotionInputEventType.actionDown),
      hasLength(10),
    );
    expect(
      events.where((event) => event.type == MotionInputEventType.actionUp),
      hasLength(10),
    );
  });

  test('Stage 7 synthetic gate recovers without a phantom action', () {
    final controller = CalibratedMotionController(profile: _profile());
    final events = <MotionInputEvent>[];

    events.addAll(controller.accept(_reading(0, 20)));
    events.addAll(controller.accept(_reading(100, 31)));
    events.addAll(controller.accept(_reading(200, null)));
    events.addAll(controller.accept(_reading(300, 31)));

    expect(_primaryActions(events), 1);
    expect(
      events.map((event) => event.type),
      containsAllInOrder([
        MotionInputEventType.actionDown,
        MotionInputEventType.primaryAction,
        MotionInputEventType.actionUp,
        MotionInputEventType.trackingLost,
        MotionInputEventType.trackingRecovered,
      ]),
    );

    events.addAll(controller.accept(_reading(400, 20)));
    events.addAll(controller.accept(_reading(500, 31)));

    expect(_primaryActions(events), 2);
  });
}

int _primaryActions(Iterable<MotionInputEvent> events) {
  return events
      .where((event) => event.type == MotionInputEventType.primaryAction)
      .length;
}

CalibrationProfile _profile() {
  return CalibrationProfile(
    movementType: CalibrationMovementType.indexFingerBend,
    baselineDegrees: 20,
    noiseEstimateDegrees: 1,
    noiseFloorDegrees: 3,
    comfortableAmplitudeDegrees: 15,
    thresholdDegrees: 30,
    thresholdOffsetDegrees: 10,
    direction: CalibrationDirection.increasingFlexion,
    thresholdSource: CalibrationThresholdSource.automaticRecommendation,
    sampleTimestamp: Duration.zero,
    completedAt: DateTime.utc(2026, 11, 16),
    setupContext: const CalibrationSetupContext(
      orientation: CalibrationDeviceOrientation.portrait,
    ),
  );
}

class _ValidationReading implements MovementMeasurement {
  const _ValidationReading({
    required this.timestamp,
    required this.valueDegrees,
  });

  @override
  final Duration timestamp;
  @override
  final double? valueDegrees;

  @override
  bool get isValid => valueDegrees != null;
}

_ValidationReading _reading(int milliseconds, double? valueDegrees) {
  return _ValidationReading(
    timestamp: Duration(milliseconds: milliseconds),
    valueDegrees: valueDegrees,
  );
}
