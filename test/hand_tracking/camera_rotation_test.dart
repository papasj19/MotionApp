import 'package:adaptive_motion_arcade/hand_tracking/mediapipe_hand_tracking_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('front camera rotation adds device rotation', () {
    expect(
      cameraImageRotationDegrees(
        sensorOrientation: 270,
        deviceOrientation: DeviceOrientation.portraitUp,
        lensDirection: CameraLensDirection.front,
      ),
      270,
    );
    expect(
      cameraImageRotationDegrees(
        sensorOrientation: 270,
        deviceOrientation: DeviceOrientation.landscapeLeft,
        lensDirection: CameraLensDirection.front,
      ),
      0,
    );
    expect(
      cameraImageRotationDegrees(
        sensorOrientation: 270,
        deviceOrientation: DeviceOrientation.landscapeRight,
        lensDirection: CameraLensDirection.front,
      ),
      180,
    );
  });

  test('rear camera rotation subtracts device rotation', () {
    expect(
      cameraImageRotationDegrees(
        sensorOrientation: 90,
        deviceOrientation: DeviceOrientation.landscapeLeft,
        lensDirection: CameraLensDirection.back,
      ),
      0,
    );
    expect(
      cameraImageRotationDegrees(
        sensorOrientation: 90,
        deviceOrientation: DeviceOrientation.landscapeRight,
        lensDirection: CameraLensDirection.back,
      ),
      180,
    );
  });
}
