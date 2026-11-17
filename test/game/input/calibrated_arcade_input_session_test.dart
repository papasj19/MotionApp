import 'package:adaptive_motion_arcade/calibration/calibration_profile.dart';
import 'package:adaptive_motion_arcade/calibration/comfortable_movement_calibration.dart';
import 'package:adaptive_motion_arcade/game/input/arcade_input.dart';
import 'package:adaptive_motion_arcade/game/input/calibrated_arcade_input_session.dart';
import 'package:adaptive_motion_arcade/movement/movement_measurement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('forwards one motion action per movement and preserves metadata', () {
    final profile = _profile();
    final session = CalibratedArcadeInputSession(profile: profile);
    final actions = <ArcadeInputEvent>[];
    session.arcadeInput.addListener(actions.add);

    expect(session.profile, same(profile));
    expect(
      session.motionStatus.value,
      ArcadeMotionInputStatus.returnToRest,
    );

    session.accept(_reading(0, 20));
    expect(session.motionStatus.value, ArcadeMotionInputStatus.ready);

    session.accept(_reading(100, 30));
    session.accept(_reading(200, 32));
    expect(actions, hasLength(1));
    expect(actions.single.source, ArcadeInputSource.motion);

    session.accept(_reading(300, 20));
    session.accept(_reading(400, 30));
    expect(actions, hasLength(2));

    session.dispose();
  });

  test('tracking recovery requires a return to rest before another action', () {
    final session = CalibratedArcadeInputSession(profile: _profile());
    final actions = <ArcadeInputEvent>[];
    session.arcadeInput.addListener(actions.add);

    session.accept(_reading(0, 20));
    session.accept(_reading(100, 30));
    session.accept(_reading(200, null));
    expect(session.motionStatus.value, ArcadeMotionInputStatus.trackingLost);
    expect(actions, hasLength(1));

    session.accept(_reading(300, 30));
    expect(
      session.motionStatus.value,
      ArcadeMotionInputStatus.returnToRest,
    );
    session.accept(_reading(400, 30));
    expect(actions, hasLength(1));

    session.accept(_reading(500, 20));
    expect(session.motionStatus.value, ArcadeMotionInputStatus.ready);
    session.accept(_reading(600, 30));
    expect(actions, hasLength(2));

    session.dispose();
  });

  test('camera lifecycle suspension cannot create an action', () {
    final session = CalibratedArcadeInputSession(profile: _profile());
    final actions = <ArcadeInputEvent>[];
    session.arcadeInput.addListener(actions.add);
    session.accept(_reading(0, 20));

    session.markTrackingUnavailable();

    expect(session.motionStatus.value, ArcadeMotionInputStatus.trackingLost);
    expect(actions, isEmpty);
    session.dispose();
  });

  test('disposal respects ownership of the arcade controller', () {
    final owned = CalibratedArcadeInputSession(profile: _profile());
    final ownedInput = owned.arcadeInput;
    owned.dispose();
    expect(() => ownedInput.addListener((_) {}), throwsStateError);

    final externalInput = ArcadeInputController();
    final borrowed = CalibratedArcadeInputSession(
      profile: _profile(),
      arcadeInput: externalInput,
    );
    borrowed.dispose();
    expect(() => externalInput.addListener((_) {}), returnsNormally);
    externalInput.dispose();
  });
}

CalibrationProfile _profile() {
  return CalibrationProfile(
    movementType: CalibrationMovementType.indexFingerBend,
    baselineDegrees: 20,
    noiseEstimateDegrees: 1,
    noiseFloorDegrees: 2,
    comfortableAmplitudeDegrees: 15,
    thresholdDegrees: 30,
    thresholdOffsetDegrees: 10,
    direction: CalibrationDirection.increasingFlexion,
    thresholdSource: CalibrationThresholdSource.automaticRecommendation,
    sampleTimestamp: Duration.zero,
    completedAt: DateTime.utc(2026, 11, 17),
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
