import '../calibration/calibration_profile.dart';
import '../calibration/comfortable_movement_calibration.dart';
import '../movement/movement_measurement.dart';
import 'motion_input_controller.dart';

/// Maps any calibrated movement into one direction-normalized controller
/// signal. Camera and landmark types remain outside this boundary.
class CalibratedMotionController {
  CalibratedMotionController({
    required this.profile,
    this.releaseThresholdRatio = 0.6,
    Duration cooldown = Duration.zero,
    Duration maximumTrackingGap = const Duration(milliseconds: 500),
  }) : _controller = MotionInputController(
          config: MotionInputControllerConfig(
            activationThreshold: profile.thresholdOffsetDegrees,
            releaseThreshold:
                profile.thresholdOffsetDegrees * releaseThresholdRatio,
            cooldown: cooldown,
            maximumTrackingGap: maximumTrackingGap,
          ),
          // Calibration commonly ends while the movement is still held.
          // Requiring rest first prevents an action when the test opens.
          initiallyArmed: false,
        ) {
    if (!releaseThresholdRatio.isFinite ||
        releaseThresholdRatio < 0 ||
        releaseThresholdRatio >= 1) {
      throw ArgumentError(
        'The release threshold ratio must be finite and between 0 and 1.',
      );
    }
  }

  final CalibrationProfile profile;
  final double releaseThresholdRatio;
  final MotionInputController _controller;

  double get activationThreshold => profile.thresholdOffsetDegrees;
  double get releaseThreshold =>
      profile.thresholdOffsetDegrees * releaseThresholdRatio;
  MotionActionState get actionState => _controller.state;
  MotionTrackingState get trackingState => _controller.trackingState;
  bool get isArmed => _controller.isArmed;

  double? signalFor(MovementMeasurement reading) {
    final value = reading.valueDegrees;
    if (!reading.isValid || value == null || !value.isFinite) {
      return null;
    }
    return profile.direction == CalibrationDirection.increasingFlexion
        ? value - profile.baselineDegrees
        : profile.baselineDegrees - value;
  }

  List<MotionInputEvent> accept(MovementMeasurement reading) {
    final signal = signalFor(reading);
    if (signal == null) {
      return _controller.markTrackingLost(timestamp: reading.timestamp);
    }
    return _controller.accept(signal: signal, timestamp: reading.timestamp);
  }

  List<MotionInputEvent> checkForStaleTracking(Duration timestamp) {
    return _controller.checkForStaleTracking(timestamp: timestamp);
  }

  List<MotionInputEvent> markTrackingLost(Duration timestamp) {
    return _controller.markTrackingLost(timestamp: timestamp);
  }
}
