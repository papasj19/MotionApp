import 'package:flutter/foundation.dart';

import '../../calibration/calibration_profile.dart';
import '../../input_controller/calibrated_motion_controller.dart';
import '../../input_controller/motion_input_controller.dart';
import '../../movement/movement_measurement.dart';
import 'arcade_input.dart';
import 'motion_arcade_input_adapter.dart';

/// Owns the temporary link between one validated calibration and one game.
///
/// The calibration profile stays here as in-memory movement-session metadata.
/// The game receives only [arcadeInput] and [motionStatus], never measurements,
/// camera frames, landmarks, or physical thresholds.
class CalibratedArcadeInputSession {
  CalibratedArcadeInputSession({
    required this.profile,
    ArcadeInputController? arcadeInput,
  })  : arcadeInput = arcadeInput ?? ArcadeInputController(),
        _ownsArcadeInput = arcadeInput == null,
        _motionController = CalibratedMotionController(profile: profile) {
    _adapter = MotionArcadeInputAdapter(arcadeInput: this.arcadeInput);
  }

  final CalibrationProfile profile;
  final ArcadeInputController arcadeInput;
  final bool _ownsArcadeInput;
  final CalibratedMotionController _motionController;
  final ValueNotifier<ArcadeMotionInputStatus> _motionStatus =
      ValueNotifier(ArcadeMotionInputStatus.returnToRest);

  late final MotionArcadeInputAdapter _adapter;
  Duration? _lastTimestamp;
  bool _disposed = false;

  ValueListenable<ArcadeMotionInputStatus> get motionStatus => _motionStatus;

  void accept(MovementMeasurement reading) {
    if (_disposed) {
      return;
    }
    final lastTimestamp = _lastTimestamp;
    if (lastTimestamp == null || reading.timestamp > lastTimestamp) {
      _lastTimestamp = reading.timestamp;
    }
    _adapter.acceptAll(_motionController.accept(reading));
    _publishControllerStatus();
  }

  /// Suspends game input when the camera lifecycle or setup becomes invalid.
  /// A recovered source must observe rest before it can publish another action.
  void markTrackingUnavailable() {
    if (_disposed) {
      return;
    }
    final timestamp =
        (_lastTimestamp ?? Duration.zero) + const Duration(microseconds: 1);
    _lastTimestamp = timestamp;
    _adapter.acceptAll(_motionController.markTrackingLost(timestamp));
    _setStatus(ArcadeMotionInputStatus.trackingLost);
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _motionStatus.dispose();
    if (_ownsArcadeInput) {
      arcadeInput.dispose();
    }
  }

  void _publishControllerStatus() {
    if (_motionController.trackingState == MotionTrackingState.lost) {
      _setStatus(ArcadeMotionInputStatus.trackingLost);
    } else if (_motionController.isArmed) {
      _setStatus(ArcadeMotionInputStatus.ready);
    } else {
      _setStatus(ArcadeMotionInputStatus.returnToRest);
    }
  }

  void _setStatus(ArcadeMotionInputStatus status) {
    if (_motionStatus.value != status) {
      _motionStatus.value = status;
    }
  }
}
