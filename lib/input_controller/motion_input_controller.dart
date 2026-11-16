enum MotionInputEventType {
  primaryAction,
  actionDown,
  actionUp,
  trackingLost,
  trackingRecovered,
}

enum MotionActionState { released, pressed }

enum MotionTrackingState { available, lost }

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
    this.cooldown = Duration.zero,
    this.maximumTrackingGap = const Duration(milliseconds: 500),
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
    if (cooldown.isNegative) {
      throw ArgumentError('The cooldown cannot be negative.');
    }
    if (maximumTrackingGap <= Duration.zero) {
      throw ArgumentError('The maximum tracking gap must be positive.');
    }
  }

  final double activationThreshold;
  final double releaseThreshold;
  final Duration cooldown;
  final Duration maximumTrackingGap;
}

/// Converts a normalized movement signal into game-independent actions.
///
/// Activation emits [MotionInputEventType.actionDown] followed by the one-shot
/// [MotionInputEventType.primaryAction]. The controller must observe release
/// before another activation can occur.
class MotionInputController {
  MotionInputController({required this.config, bool initiallyArmed = true})
    : _requiresReleaseBeforeActivation = !initiallyArmed;

  final MotionInputControllerConfig config;

  MotionActionState _state = MotionActionState.released;
  MotionTrackingState _trackingState = MotionTrackingState.available;
  Duration? _lastInputTimestamp;
  Duration? _lastValidTimestamp;
  Duration? _lastActivationTimestamp;
  bool _requiresReleaseBeforeActivation;

  MotionActionState get state => _state;
  bool get isPressed => _state == MotionActionState.pressed;
  MotionTrackingState get trackingState => _trackingState;
  bool get isArmed =>
      _trackingState == MotionTrackingState.available &&
      !_requiresReleaseBeforeActivation;

  List<MotionInputEvent> accept({
    required double signal,
    required Duration timestamp,
  }) {
    if (!signal.isFinite) {
      throw ArgumentError.value(signal, 'signal', 'Signal must be finite.');
    }
    if (!_recordTimestamp(timestamp)) {
      return const [];
    }

    final events = <MotionInputEvent>[];
    final previousValidTimestamp = _lastValidTimestamp;
    if (previousValidTimestamp != null &&
        timestamp - previousValidTimestamp > config.maximumTrackingGap) {
      events.addAll(_loseTracking(timestamp));
    }
    _lastValidTimestamp = timestamp;

    if (_trackingState == MotionTrackingState.lost) {
      _trackingState = MotionTrackingState.available;
      events.add(
        MotionInputEvent(
          type: MotionInputEventType.trackingRecovered,
          timestamp: timestamp,
        ),
      );
      if (signal <= config.releaseThreshold) {
        _requiresReleaseBeforeActivation = false;
      }
      return events;
    }

    if (_requiresReleaseBeforeActivation) {
      if (signal <= config.releaseThreshold) {
        _requiresReleaseBeforeActivation = false;
      }
      return events;
    }

    if (_state == MotionActionState.released &&
        signal >= config.activationThreshold) {
      final lastActivationTimestamp = _lastActivationTimestamp;
      if (lastActivationTimestamp != null &&
          timestamp - lastActivationTimestamp < config.cooldown) {
        _requiresReleaseBeforeActivation = true;
        return events;
      }
      _state = MotionActionState.pressed;
      _lastActivationTimestamp = timestamp;
      events.addAll([
        MotionInputEvent(
          type: MotionInputEventType.actionDown,
          timestamp: timestamp,
        ),
        MotionInputEvent(
          type: MotionInputEventType.primaryAction,
          timestamp: timestamp,
        ),
      ]);
      return events;
    }

    if (_state == MotionActionState.pressed &&
        signal <= config.releaseThreshold) {
      _state = MotionActionState.released;
      events.add(
        MotionInputEvent(
          type: MotionInputEventType.actionUp,
          timestamp: timestamp,
        ),
      );
      return events;
    }

    return events;
  }

  /// Safely releases a held action when tracking reports an invalid sample.
  List<MotionInputEvent> markTrackingLost({required Duration timestamp}) {
    if (!_recordTimestamp(timestamp)) {
      return const [];
    }
    return _loseTracking(timestamp);
  }

  /// Emits tracking loss when no valid sample has arrived within the allowed
  /// gap. [timestamp] must use the same monotonic clock as movement samples.
  List<MotionInputEvent> checkForStaleTracking({required Duration timestamp}) {
    if (!_recordTimestamp(timestamp)) {
      return const [];
    }
    final lastValidTimestamp = _lastValidTimestamp;
    if (_trackingState == MotionTrackingState.lost ||
        lastValidTimestamp == null ||
        timestamp - lastValidTimestamp <= config.maximumTrackingGap) {
      return const [];
    }
    return _loseTracking(timestamp);
  }

  bool _recordTimestamp(Duration timestamp) {
    final lastInputTimestamp = _lastInputTimestamp;
    if (lastInputTimestamp != null && timestamp <= lastInputTimestamp) {
      return false;
    }
    _lastInputTimestamp = timestamp;
    return true;
  }

  List<MotionInputEvent> _loseTracking(Duration timestamp) {
    if (_trackingState == MotionTrackingState.lost) {
      return const [];
    }

    final events = <MotionInputEvent>[];
    if (_state == MotionActionState.pressed) {
      _state = MotionActionState.released;
      events.add(
        MotionInputEvent(
          type: MotionInputEventType.actionUp,
          timestamp: timestamp,
        ),
      );
    }
    _trackingState = MotionTrackingState.lost;
    _lastValidTimestamp = null;
    _requiresReleaseBeforeActivation = true;
    events.add(
      MotionInputEvent(
        type: MotionInputEventType.trackingLost,
        timestamp: timestamp,
      ),
    );
    return events;
  }
}
