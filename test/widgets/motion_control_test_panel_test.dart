import 'package:adaptive_motion_arcade/calibration/calibration_profile.dart';
import 'package:adaptive_motion_arcade/calibration/comfortable_movement_calibration.dart';
import 'package:adaptive_motion_arcade/movement/movement_measurement.dart';
import 'package:adaptive_motion_arcade/widgets/motion_control_test_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test_support/localized_test_app.dart';

void main() {
  final profile = _profile();

  testWidgets('shows one action for one deliberate movement and release', (
    tester,
  ) async {
    await _pumpPanel(tester, profile, _reading(0, 20));

    expect(find.text('READY'), findsOneWidget);
    expect(find.text('Actions'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    await _pumpPanel(tester, profile, _reading(100, 30));
    expect(find.text('ACTION PRESSED'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await _pumpPanel(tester, profile, _reading(200, 30));
    expect(find.text('1'), findsOneWidget);

    await _pumpPanel(tester, profile, _reading(300, 20));
    expect(find.text('READY'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('pauses safely when tracking is unavailable', (tester) async {
    await _pumpPanel(tester, profile, _reading(0, 20));
    await _pumpPanel(tester, profile, _reading(100, 30));
    await _pumpPanel(tester, profile, _reading(200, null));

    expect(find.text('TRACKING PAUSED'), findsOneWidget);
    expect(find.text('Lost'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
  });

  testWidgets('supports synthetic input and recalibration on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var recalibrated = false;

    await _pumpPanel(
      tester,
      profile,
      _reading(0, 20),
      enableSyntheticInput: true,
      onRecalibrate: () => recalibrated = true,
    );

    await tester.ensureVisible(find.text('Test press'));
    await tester.tap(find.text('Test press'));
    await tester.pump();
    expect(find.text('ACTION PRESSED'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.text('Test release'));
    await tester.pump();
    expect(find.text('READY'), findsOneWidget);

    await tester.ensureVisible(find.text('Recalibrate'));
    await tester.tap(find.text('Recalibrate'));
    expect(recalibrated, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows caregiver validation diagnostics and action timing', (
    tester,
  ) async {
    await _pumpPanel(
      tester,
      profile,
      _reading(0, 20),
      framesPerSecond: 24,
      processingLatency: const Duration(milliseconds: 42),
      droppedFrames: 3,
    );
    await _pumpPanel(
      tester,
      profile,
      _reading(100, 23),
      framesPerSecond: 24,
      processingLatency: const Duration(milliseconds: 42),
      droppedFrames: 3,
    );
    await _pumpPanel(
      tester,
      profile,
      _reading(180, 30),
      framesPerSecond: 24,
      processingLatency: const Duration(milliseconds: 42),
      droppedFrames: 3,
    );

    await tester.ensureVisible(find.text('Validation details'));
    await tester.tap(find.text('Validation details'));
    await tester.pumpAndSettle();

    expect(find.text('3/3 (100%)'), findsOneWidget);
    expect(find.text('24.0 FPS'), findsOneWidget);
    expect(find.text('42 ms'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('15.0×'), findsOneWidget);
    expect(find.text('80 ms median'), findsOneWidget);
  });

  testWidgets('uses Spanish labels and decimal formatting', (tester) async {
    await _pumpPanel(
      tester,
      profile,
      _reading(0, 20),
      locale: const Locale('es'),
      framesPerSecond: 24,
      processingLatency: const Duration(milliseconds: 42),
    );

    expect(find.text('LISTO'), findsOneWidget);
    expect(find.text('Acciones'), findsOneWidget);
    await tester.ensureVisible(find.text('Detalles de validación'));
    await tester.tap(find.text('Detalles de validación'));
    await tester.pumpAndSettle();

    expect(find.text('24,0 FPS'), findsOneWidget);
    expect(find.text('42 ms'), findsOneWidget);
    expect(find.text('Mediana del retardo de procesamiento'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpPanel(
  WidgetTester tester,
  CalibrationProfile profile,
  MovementMeasurement reading, {
  bool enableSyntheticInput = false,
  double framesPerSecond = 0,
  Duration? processingLatency,
  int droppedFrames = 0,
  VoidCallback? onRecalibrate,
  Locale locale = const Locale('en'),
}) {
  return tester.pumpWidget(
    localizedTestApp(
      locale: locale,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: MotionControlTestPanel(
            profile: profile,
            reading: reading,
            enableSyntheticInput: enableSyntheticInput,
            framesPerSecond: framesPerSecond,
            processingLatency: processingLatency,
            droppedFrames: droppedFrames,
            onRecalibrate: onRecalibrate ?? () {},
          ),
        ),
      ),
    ),
  );
}

CalibrationProfile _profile() {
  return CalibrationProfile(
    movementType: CalibrationMovementType.indexFingerBend,
    baselineDegrees: 20,
    noiseEstimateDegrees: 1,
    noiseFloorDegrees: 2,
    comfortableAmplitudeDegrees: 15,
    thresholdDegrees: 30,
    thresholdOffsetDegrees: 10,
    direction: CalibrationDirection.increasingFlexion,
    thresholdSource: CalibrationThresholdSource.automaticRecommendation,
    sampleTimestamp: Duration.zero,
    completedAt: DateTime.utc(2026, 11, 16),
    setupContext: const CalibrationSetupContext(
      orientation: CalibrationDeviceOrientation.portrait,
    ),
  );
}

class _TestReading implements MovementMeasurement {
  const _TestReading({required this.timestamp, required this.valueDegrees});

  @override
  final Duration timestamp;
  @override
  final double? valueDegrees;

  @override
  bool get isValid => valueDegrees != null;
}

_TestReading _reading(int milliseconds, double? valueDegrees) {
  return _TestReading(
    timestamp: Duration(milliseconds: milliseconds),
    valueDegrees: valueDegrees,
  );
}
