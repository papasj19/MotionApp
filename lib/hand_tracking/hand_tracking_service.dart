import 'package:camera/camera.dart';

import 'hand_tracking_update.dart';

abstract interface class HandTrackingService {
  Stream<HandTrackingUpdate> get updates;

  Future<void> start(CameraController controller);

  Future<void> stop();

  Future<void> dispose();
}
