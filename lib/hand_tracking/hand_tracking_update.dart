import 'hand_observation.dart';

enum HandTrackingStatus { idle, starting, searching, tracking, failure }

class HandTrackingUpdate {
  const HandTrackingUpdate({
    required this.status,
    required this.message,
    this.observation,
    this.framesPerSecond = 0,
    this.processingLatency,
    this.droppedFrames = 0,
  });

  const HandTrackingUpdate.idle()
    : this(status: HandTrackingStatus.idle, message: 'Hand tracking is idle.');

  const HandTrackingUpdate.starting()
    : this(
        status: HandTrackingStatus.starting,
        message: 'Starting hand tracking…',
      );

  const HandTrackingUpdate.failure(String message)
    : this(status: HandTrackingStatus.failure, message: message);

  final HandTrackingStatus status;
  final String message;
  final HandObservation? observation;
  final double framesPerSecond;
  final Duration? processingLatency;
  final int droppedFrames;
}

class HandPresenceMonitor {
  HandPresenceMonitor({this.staleAfter = const Duration(milliseconds: 750)});

  final Duration staleAfter;

  Duration? _lastResultAt;
  HandObservation? _observation;

  HandTrackingUpdate acceptResult({
    required HandObservation? observation,
    required Duration receivedAt,
    required double framesPerSecond,
    required Duration processingLatency,
    required int droppedFrames,
  }) {
    _lastResultAt = receivedAt;
    _observation = observation;

    return HandTrackingUpdate(
      status: observation == null
          ? HandTrackingStatus.searching
          : HandTrackingStatus.tracking,
      message: observation == null
          ? 'Show one hand to begin tracking.'
          : 'One hand detected.',
      observation: observation,
      framesPerSecond: framesPerSecond,
      processingLatency: processingLatency,
      droppedFrames: droppedFrames,
    );
  }

  HandTrackingUpdate? markStale({
    required Duration now,
    required double framesPerSecond,
    required int droppedFrames,
  }) {
    final lastResultAt = _lastResultAt;
    if (_observation == null ||
        lastResultAt == null ||
        now - lastResultAt < staleAfter) {
      return null;
    }

    _observation = null;
    return HandTrackingUpdate(
      status: HandTrackingStatus.searching,
      message: 'Tracking paused. Show one hand to continue.',
      framesPerSecond: framesPerSecond,
      droppedFrames: droppedFrames,
    );
  }

  void reset() {
    _lastResultAt = null;
    _observation = null;
  }
}
