import 'dart:async';

import 'package:adaptive_motion_arcade/hand_tracking/hand_tracking_service.dart';
import 'package:adaptive_motion_arcade/hand_tracking/hand_tracking_update.dart';
import 'package:adaptive_motion_arcade/screens/camera_screen.dart';
import 'package:adaptive_motion_arcade/services/camera_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('reports when no front camera exists', (tester) async {
    final service = _FakeCameraService([
      const CameraSetupResult(
        status: CameraSetupStatus.noFrontCamera,
        message: 'No front-facing camera was found on this device.',
      ),
    ]);
    final tracking = _FakeHandTrackingService();

    await tester.pumpWidget(
      MaterialApp(
        home: CameraScreen(
          cameraService: service,
          handTrackingService: tracking,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Front camera unavailable'), findsOneWidget);
    expect(
      find.text('No front-facing camera was found on this device.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsNothing);
    expect(service.initializeCalls, 1);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(service.disposeCalls, 1);
    expect(tracking.disposeCalls, 1);
  });

  testWidgets('shows denied permission and retries', (tester) async {
    final service = _FakeCameraService([
      const CameraSetupResult(
        status: CameraSetupStatus.permissionDenied,
        message:
            'Camera access was denied. Allow camera access in device '
            'settings, then try again.',
      ),
      const CameraSetupResult(
        status: CameraSetupStatus.failure,
        message: 'The camera could not start. Please try again.',
      ),
    ]);
    final tracking = _FakeHandTrackingService();

    await tester.pumpWidget(
      MaterialApp(
        home: CameraScreen(
          cameraService: service,
          handTrackingService: tracking,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Camera permission needed'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('Camera unavailable'), findsOneWidget);
    expect(service.initializeCalls, 2);
  });

  testWidgets('disposes on pause and initializes again on resume', (
    tester,
  ) async {
    final service = _FakeCameraService([
      const CameraSetupResult(
        status: CameraSetupStatus.noFrontCamera,
        message: 'No front-facing camera was found on this device.',
      ),
      const CameraSetupResult(
        status: CameraSetupStatus.noFrontCamera,
        message: 'No front-facing camera was found on this device.',
      ),
    ]);
    final tracking = _FakeHandTrackingService();

    await tester.pumpWidget(
      MaterialApp(
        home: CameraScreen(
          cameraService: service,
          handTrackingService: tracking,
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();

    expect(service.disposeCalls, 1);
    expect(tracking.stopCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Front camera unavailable'), findsOneWidget);
    expect(service.initializeCalls, 2);
  });

  testWidgets('restarts the camera after orientation changes', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final service = _FakeCameraService([
      const CameraSetupResult(
        status: CameraSetupStatus.noFrontCamera,
        message: 'No front-facing camera was found on this device.',
      ),
    ]);
    final tracking = _FakeHandTrackingService();

    await tester.pumpWidget(
      MaterialApp(
        home: CameraScreen(
          cameraService: service,
          handTrackingService: tracking,
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(800, 400);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(service.disposeCalls, 1);
    expect(tracking.stopCalls, 1);
    expect(service.initializeCalls, 2);
  });

  testWidgets('debounces rapid orientation changes', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final service = _FakeCameraService([
      const CameraSetupResult(
        status: CameraSetupStatus.noFrontCamera,
        message: 'No front-facing camera was found on this device.',
      ),
    ]);
    final tracking = _FakeHandTrackingService();

    await tester.pumpWidget(
      MaterialApp(
        home: CameraScreen(
          cameraService: service,
          handTrackingService: tracking,
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(800, 400);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    tester.view.physicalSize = const Size(400, 800);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(service.disposeCalls, 1);
    expect(tracking.stopCalls, 1);
    expect(service.initializeCalls, 2);
  });
}

class _FakeHandTrackingService implements HandTrackingService {
  final StreamController<HandTrackingUpdate> _updates =
      StreamController<HandTrackingUpdate>.broadcast();

  int startCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;

  @override
  Stream<HandTrackingUpdate> get updates => _updates.stream;

  @override
  Future<void> start(CameraController controller) async {
    startCalls += 1;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    _updates.add(const HandTrackingUpdate.idle());
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
    await _updates.close();
  }
}

class _FakeCameraService implements CameraService {
  _FakeCameraService(this.results);

  final List<CameraSetupResult> results;
  int initializeCalls = 0;
  int disposeCalls = 0;

  @override
  Future<CameraSetupResult> initialize() async {
    final resultIndex = initializeCalls < results.length
        ? initializeCalls
        : results.length - 1;
    initializeCalls += 1;
    return results[resultIndex];
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}
