import 'package:adaptive_motion_arcade/calibration/calibration_profile.dart';
import 'package:adaptive_motion_arcade/movement/finger_movement_analyzer.dart';
import 'package:adaptive_motion_arcade/movement/movement_measurement.dart';
import 'package:adaptive_motion_arcade/widgets/calibration_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test_support/localized_test_app.dart';

void main() {
  const setupContext = CalibrationSetupContext(
    orientation: CalibrationDeviceOrientation.portrait,
  );
  final completedAt = DateTime.utc(2026, 11, 15, 12);

  testWidgets('completes the automatic caregiver calibration flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    CalibrationProfile? requestedProfile;
    void requestControlTest(CalibrationProfile profile) {
      requestedProfile = profile;
    }

    await _pumpReading(
      tester,
      _reading(0, 20),
      setupContext,
      completedAt,
      onControlTestRequested: requestControlTest,
    );
    await tester.tap(find.text('Start rest measurement'));
    await tester.pump();

    for (var index = 1; index <= 8; index++) {
      await _pumpReading(
        tester,
        _reading(index * 250, 20),
        setupContext,
        completedAt,
        onControlTestRequested: requestControlTest,
      );
    }
    expect(find.text('Rest measurement complete'), findsOneWidget);

    await tester.tap(find.text('Measure comfortable movement'));
    await tester.pump();
    const movementAngles = [22.0, 25.0, 28.0, 30.0, 30.0, 30.0];
    for (var index = 0; index < movementAngles.length; index++) {
      await _pumpReading(
        tester,
        _reading(2250 + index * 250, movementAngles[index]),
        setupContext,
        completedAt,
        onControlTestRequested: requestControlTest,
      );
    }

    expect(find.text('Caregiver review'), findsOneWidget);
    expect(find.text('More bend'), findsOneWidget);
    expect(find.textContaining('Measured noise floor'), findsOneWidget);

    await tester.ensureVisible(find.text('Use this setting'));
    await tester.tap(find.text('Use this setting'));
    await tester.pump();

    expect(find.text('Calibration ready'), findsOneWidget);
    expect(find.textContaining('Direction: More bend'), findsOneWidget);
    expect(
      find.textContaining('not saved and clears when you leave this screen'),
      findsOneWidget,
    );
    expect(find.text('Test this control'), findsOneWidget);

    await tester.tap(find.text('Test this control'));
    expect(requestedProfile, isNotNull);
    expect(
      requestedProfile!.movementType,
      CalibrationMovementType.indexFingerBend,
    );
  });

  testWidgets('offers manual review only when movement exceeds noise', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _reachMovementStep(tester, setupContext, completedAt);
    const smallMovement = [20.5, 21.0, 21.5, 22.0, 23.0, 23.0];
    for (var index = 0; index < smallMovement.length; index++) {
      await _pumpReading(
        tester,
        _reading(2250 + index * 250, smallMovement[index]),
        setupContext,
        completedAt,
      );
    }

    expect(find.text('Retry movement'), findsOneWidget);
    expect(find.text('Review manual setting'), findsOneWidget);

    await tester.tap(find.text('Review manual setting'));
    await tester.pump();

    expect(find.text('Caregiver review'), findsOneWidget);
    expect(
      find.textContaining('Observed comfortable movement'),
      findsOneWidget,
    );
  });

  testWidgets('reports tracking loss without treating it as user failure', (
    tester,
  ) async {
    await _pumpReading(tester, _reading(0, 20), setupContext, completedAt);
    await tester.tap(find.text('Start rest measurement'));
    await tester.pump();

    await _pumpReading(
      tester,
      FingerMovementReading.unavailable(
        timestamp: const Duration(milliseconds: 250),
        validity: FingerMovementValidity.missingObservation,
        note: 'No hand observation is available.',
      ),
      setupContext,
      completedAt,
    );

    expect(
      find.text(
        'Tracking paused. Show one hand clearly, including the full index finger.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('failed'), findsNothing);
  });

  testWidgets('shows calibration guidance in Spanish', (tester) async {
    await _pumpReading(
      tester,
      _reading(0, 20),
      setupContext,
      completedAt,
      locale: const Locale('es'),
    );

    expect(find.text('Calibración del movimiento cómodo'), findsOneWidget);
    expect(find.text('Movimiento elegido: Dedo.'), findsOneWidget);
    expect(find.text('Iniciar la medición en reposo'), findsOneWidget);

    await tester.tap(find.text('Iniciar la medición en reposo'));
    await tester.pump();
    await _pumpReading(
      tester,
      FingerMovementReading.unavailable(
        timestamp: const Duration(milliseconds: 250),
        validity: FingerMovementValidity.missingObservation,
        note: 'Internal diagnostic only.',
      ),
      setupContext,
      completedAt,
      locale: const Locale('es'),
    );

    expect(
      find.textContaining('Seguimiento en pausa.'),
      findsOneWidget,
    );
    expect(find.textContaining('Internal diagnostic'), findsNothing);
  });
}

Future<void> _reachMovementStep(
  WidgetTester tester,
  CalibrationSetupContext setupContext,
  DateTime completedAt,
) async {
  await _pumpReading(tester, _reading(0, 20), setupContext, completedAt);
  await tester.tap(find.text('Start rest measurement'));
  await tester.pump();
  for (var index = 1; index <= 8; index++) {
    await _pumpReading(
      tester,
      _reading(index * 250, 20),
      setupContext,
      completedAt,
    );
  }
  await tester.tap(find.text('Measure comfortable movement'));
  await tester.pump();
}

Future<void> _pumpReading(
  WidgetTester tester,
  FingerMovementReading reading,
  CalibrationSetupContext setupContext,
  DateTime completedAt, {
  ValueChanged<CalibrationProfile>? onControlTestRequested,
  Locale locale = const Locale('en'),
}) {
  return tester.pumpWidget(
    localizedTestApp(
      locale: locale,
      home: Scaffold(
        body: SingleChildScrollView(
          child: CalibrationPanel(
            reading: reading,
            movementType: CalibrationMovementType.indexFingerBend,
            setupContext: setupContext,
            now: () => completedAt,
            onControlTestRequested: onControlTestRequested,
          ),
        ),
      ),
    ),
  );
}

FingerMovementReading _reading(int milliseconds, double angleDegrees) {
  return FingerMovementReading(
    timestamp: Duration(milliseconds: milliseconds),
    validity: FingerMovementValidity.valid,
    quality: MovementQualityMetadata(
      quality: MovementSignalQuality.good,
      notes: const [],
    ),
    state: FingerMotionState.stationary,
    flexionDegrees: angleDegrees,
    rawFlexionDegrees: angleDegrees,
    velocityDegreesPerSecond: 0,
  );
}
