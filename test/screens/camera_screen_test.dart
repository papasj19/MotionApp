import 'package:adaptive_motion_arcade/screens/camera_screen.dart';
import 'package:adaptive_motion_arcade/services/camera_service.dart';
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

    await tester.pumpWidget(
      MaterialApp(home: CameraScreen(cameraService: service)),
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
    expect(service.disposeCalls, 1);
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

    await tester.pumpWidget(
      MaterialApp(home: CameraScreen(cameraService: service)),
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

    await tester.pumpWidget(
      MaterialApp(home: CameraScreen(cameraService: service)),
    );
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();

    expect(service.disposeCalls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Front camera unavailable'), findsOneWidget);
    expect(service.initializeCalls, 2);
  });
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
