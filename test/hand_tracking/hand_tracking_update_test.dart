import 'package:adaptive_motion_arcade/hand_tracking/hand_observation.dart';
import 'package:adaptive_motion_arcade/hand_tracking/hand_tracking_update.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reports searching when no hand is present', () {
    final monitor = HandPresenceMonitor();

    final update = monitor.acceptResult(
      observation: null,
      receivedAt: Duration.zero,
      framesPerSecond: 12,
      processingLatency: const Duration(milliseconds: 45),
      droppedFrames: 2,
    );

    expect(update.status, HandTrackingStatus.searching);
    expect(update.observation, isNull);
    expect(update.message, contains('Show one hand'));
  });

  test('reports tracking and clears a stale observation', () {
    final monitor = HandPresenceMonitor(
      staleAfter: const Duration(milliseconds: 750),
    );
    final observation = _observation();

    final tracking = monitor.acceptResult(
      observation: observation,
      receivedAt: const Duration(milliseconds: 100),
      framesPerSecond: 15,
      processingLatency: const Duration(milliseconds: 30),
      droppedFrames: 0,
    );
    final stillFresh = monitor.markStale(
      now: const Duration(milliseconds: 849),
      framesPerSecond: 15,
      droppedFrames: 0,
    );
    final stale = monitor.markStale(
      now: const Duration(milliseconds: 850),
      framesPerSecond: 14,
      droppedFrames: 1,
    );

    expect(tracking.status, HandTrackingStatus.tracking);
    expect(tracking.observation, same(observation));
    expect(stillFresh, isNull);
    expect(stale?.status, HandTrackingStatus.searching);
    expect(stale?.observation, isNull);
    expect(stale?.message, contains('paused'));
  });

  test('tracking can be reacquired after a stale result', () {
    final monitor = HandPresenceMonitor(
      staleAfter: const Duration(milliseconds: 10),
    );
    final observation = _observation();
    monitor.acceptResult(
      observation: observation,
      receivedAt: Duration.zero,
      framesPerSecond: 10,
      processingLatency: Duration.zero,
      droppedFrames: 0,
    );
    monitor.markStale(
      now: const Duration(milliseconds: 10),
      framesPerSecond: 10,
      droppedFrames: 0,
    );

    final reacquired = monitor.acceptResult(
      observation: observation,
      receivedAt: const Duration(milliseconds: 20),
      framesPerSecond: 10,
      processingLatency: Duration.zero,
      droppedFrames: 0,
    );

    expect(reacquired.status, HandTrackingStatus.tracking);
    expect(reacquired.observation, same(observation));
  });

  test('hand observation requires exactly 21 landmarks', () {
    expect(
      () => HandObservation(
        timestamp: Duration.zero,
        landmarks: const [HandLandmark(x: 0, y: 0, z: 0)],
        imageWidth: 1,
        imageHeight: 1,
        rotationDegrees: 0,
        isMirrored: false,
        handedness: Handedness.unknown,
      ),
      throwsArgumentError,
    );
  });
}

HandObservation _observation() {
  return HandObservation(
    timestamp: Duration.zero,
    landmarks: List.generate(
      21,
      (_) => const HandLandmark(x: 0.5, y: 0.5, z: 0),
    ),
    imageWidth: 640,
    imageHeight: 480,
    rotationDegrees: 0,
    isMirrored: true,
    handedness: Handedness.right,
  );
}
