import 'dart:async';

import 'package:camera/camera.dart';

import '../hand_tracking/hand_tracking_service.dart';
import '../hand_tracking/hand_tracking_update.dart';
import '../movement/finger_movement_analyzer.dart';
import '../movement/movement_measurement.dart';
import 'movement_tracking_service.dart';

class HandMovementTrackingAdapter implements MovementTrackingService {
  HandMovementTrackingAdapter(
    this._handTrackingService, {
    IndexFingerMovementAnalyzer? analyzer,
  }) : _analyzer = analyzer ?? IndexFingerMovementAnalyzer() {
    _subscription = _handTrackingService.updates.listen(_handleUpdate);
  }

  final HandTrackingService _handTrackingService;
  final IndexFingerMovementAnalyzer _analyzer;
  final StreamController<MovementTrackingUpdate> _updates =
      StreamController<MovementTrackingUpdate>.broadcast();
  StreamSubscription<HandTrackingUpdate>? _subscription;
  bool _disposed = false;

  @override
  CalibrationMovementType get movementType =>
      CalibrationMovementType.indexFingerBend;

  @override
  Stream<MovementTrackingUpdate> get updates => _updates.stream;

  void _handleUpdate(HandTrackingUpdate update) {
    final observation = update.observation;
    final reading = observation != null
        ? _analyzer.analyze(observation)
        : _readingWithoutObservation(update);
    _emit(
      MovementTrackingUpdate(
        status: _statusFor(update.status),
        message: update.message,
        reading: reading,
        handObservation: observation,
        framesPerSecond: update.framesPerSecond,
        processingLatency: update.processingLatency,
        droppedFrames: update.droppedFrames,
      ),
    );
  }

  FingerMovementReading _readingWithoutObservation(HandTrackingUpdate update) {
    final timestamp = update.timestamp;
    if (update.status == HandTrackingStatus.searching && timestamp != null) {
      return _analyzer.markMissing(timestamp);
    }
    _analyzer.reset();
    return FingerMovementReading.unavailable(
      timestamp: timestamp ?? Duration.zero,
      validity: update.status == HandTrackingStatus.searching
          ? FingerMovementValidity.missingObservation
          : FingerMovementValidity.trackingUnavailable,
      note: update.message,
    );
  }

  MovementTrackingStatus _statusFor(HandTrackingStatus status) =>
      switch (status) {
        HandTrackingStatus.idle => MovementTrackingStatus.idle,
        HandTrackingStatus.starting => MovementTrackingStatus.starting,
        HandTrackingStatus.searching => MovementTrackingStatus.searching,
        HandTrackingStatus.tracking => MovementTrackingStatus.tracking,
        HandTrackingStatus.failure => MovementTrackingStatus.failure,
      };

  void _emit(MovementTrackingUpdate update) {
    if (!_disposed && !_updates.isClosed) {
      _updates.add(update);
    }
  }

  @override
  Future<void> start(CameraController controller) =>
      _handTrackingService.start(controller);

  @override
  Future<void> stop() async {
    _analyzer.reset();
    await _handTrackingService.stop();
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _handTrackingService.dispose();
    await _subscription?.cancel();
    _subscription = null;
    await _updates.close();
  }
}
