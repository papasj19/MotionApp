import 'package:camera/camera.dart';

import '../hand_tracking/hand_observation.dart';
import '../movement/movement_measurement.dart';

enum MovementTrackingStatus { idle, starting, searching, tracking, failure }

class MovementTrackingUpdate {
  const MovementTrackingUpdate({
    required this.status,
    required this.message,
    required this.reading,
    this.handObservation,
    this.framesPerSecond = 0,
    this.processingLatency,
    this.droppedFrames = 0,
  });

  final MovementTrackingStatus status;
  final String message;
  final MovementMeasurement reading;
  final HandObservation? handObservation;
  final double framesPerSecond;
  final Duration? processingLatency;
  final int droppedFrames;
}

abstract interface class MovementTrackingService {
  CalibrationMovementType get movementType;

  Stream<MovementTrackingUpdate> get updates;

  Future<void> start(CameraController controller);

  Future<void> stop();

  Future<void> dispose();
}
