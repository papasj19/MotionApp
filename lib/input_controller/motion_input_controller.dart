enum MotionInputEventType {
  primaryAction,
  actionDown,
  actionUp,
  trackingLost,
  trackingRecovered,
}

enum MotionActionState { released, pressed }

class MotionInputEvent {
  const MotionInputEvent({required this.type, required this.timestamp});

  final MotionInputEventType type;
  final Duration timestamp;
}

/// Thresholds use a direction-normalized movement signal: larger values always
/// mean further into the movement selected during calibration.
class MotionInputControllerConfig {
  MotionInputControllerConfig({
    required this.activationThreshold,
    required this.releaseThreshold,
  }) {
    if (!activationThreshold.isFinite || activationThreshold <= 0) {
      throw ArgumentError(
        'The activation threshold must be finite and positive.',
      );
    }
    if (!releaseThreshold.isFinite || releaseThreshold < 0) {
      throw ArgumentError(
        'The release threshold must be finite and non-negative.',
      );
    }
    if (releaseThreshold >= activationThreshold) {
      throw ArgumentError(
        'The release threshold must be below the activation threshold.',
      );
    }
  }

  final double activationThreshold;
  final double releaseThreshold;
}

/// Converts a normalized movement signal into game-independent actions.
///
/// Activation emits [MotionInputEventType.actionDown] followed by the one-shot
/// [MotionInputEventType.primaryAction]. The controller must observe release
/// before another activation can occur.
class MotionInputController {
  MotionInputController({required this.config});

  final MotionInputControllerConfig config;

  MotionActionState _state = MotionActionState.released;

  MotionActionState get state => _state;
  bool get isPressed => _state == MotionActionState.pressed;

  List<MotionInputEvent> accept({
    required double signal,
    required Duration timestamp,
  }) {
    if (!signal.isFinite) {
      throw ArgumentError.value(signal, 'signal', 'Signal must be finite.');
    }

    if (_state == MotionActionState.released &&
        signal >= config.activationThreshold) {
      _state = MotionActionState.pressed;
      return [
        MotionInputEvent(
          type: MotionInputEventType.actionDown,
          timestamp: timestamp,
        ),
        MotionInputEvent(
          type: MotionInputEventType.primaryAction,
          timestamp: timestamp,
        ),
      ];
    }

    if (_state == MotionActionState.pressed &&
        signal <= config.releaseThreshold) {
      _state = MotionActionState.released;
      return [
        MotionInputEvent(
          type: MotionInputEventType.actionUp,
          timestamp: timestamp,
        ),
      ];
    }

    return const [];
  }
}
