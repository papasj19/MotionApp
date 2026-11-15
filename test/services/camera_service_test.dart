import 'dart:async';

import 'package:adaptive_motion_arcade/services/camera_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('selectFrontCamera chooses the first front-facing camera', () {
    const backCamera = CameraDescription(
      name: 'back',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    );
    const frontCamera = CameraDescription(
      name: 'front',
      lensDirection: CameraLensDirection.front,
      sensorOrientation: 270,
    );

    expect(selectFrontCamera([backCamera, frontCamera]), frontCamera);
  });

  test('selectFrontCamera returns null when no front camera exists', () {
    const backCamera = CameraDescription(
      name: 'back',
      lensDirection: CameraLensDirection.back,
      sensorOrientation: 90,
    );

    expect(selectFrontCamera([backCamera]), isNull);
  });

  test('initialize shares an in-progress camera lookup', () async {
    final cameras = Completer<List<CameraDescription>>();
    var lookupCalls = 0;
    final service = DeviceCameraService(
      cameraListLoader: () {
        lookupCalls += 1;
        return cameras.future;
      },
    );

    final firstInitialization = service.initialize();
    final secondInitialization = service.initialize();
    cameras.complete(const []);

    final results = await Future.wait([
      firstInitialization,
      secondInitialization,
    ]);

    expect(lookupCalls, 1);
    expect(
      results.map((result) => result.status),
      everyElement(CameraSetupStatus.noFrontCamera),
    );
  });

  test('initialize maps denied camera permission', () async {
    final service = DeviceCameraService(
      cameraListLoader: () async {
        throw CameraException('CameraAccessDenied', 'Denied for test');
      },
    );

    final result = await service.initialize();

    expect(result.status, CameraSetupStatus.permissionDenied);
    expect(result.message, contains('device settings'));
  });

  test('initialize maps restricted camera permission', () async {
    final service = DeviceCameraService(
      cameraListLoader: () async {
        throw CameraException('CameraAccessRestricted', 'Restricted for test');
      },
    );

    final result = await service.initialize();

    expect(result.status, CameraSetupStatus.permissionRestricted);
    expect(result.message, contains('restricted'));
  });
}
