import 'package:adaptive_motion_arcade/movement/finger_movement_analyzer.dart';
import 'package:adaptive_motion_arcade/widgets/finger_movement_diagnostic.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('shows a rounded diagnostic angle and movement state', (
    tester,
  ) async {
    final reading = FingerMovementReading(
      timestamp: const Duration(milliseconds: 100),
      validity: FingerMovementValidity.valid,
      quality: MovementQualityMetadata(
        quality: MovementSignalQuality.good,
        notes: const [],
      ),
      state: FingerMotionState.flexing,
      flexionDegrees: 42.4,
      rawFlexionDegrees: 44,
      velocityDegreesPerSecond: 30,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FingerMovementDiagnostic(reading: reading)),
      ),
    );

    expect(find.text('Index finger flexion'), findsOneWidget);
    expect(find.text('~42°'), findsOneWidget);
    expect(find.text('Bending'), findsOneWidget);
    expect(find.textContaining('0° is straight'), findsOneWidget);
  });

  testWidgets('does not retain a number when the hand is missing', (
    tester,
  ) async {
    final reading = FingerMovementReading.unavailable(
      timestamp: const Duration(milliseconds: 200),
      validity: FingerMovementValidity.missingObservation,
      note: 'No hand observation is available.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FingerMovementDiagnostic(reading: reading)),
      ),
    );

    expect(find.text('—'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.textContaining('Show one hand'), findsOneWidget);
  });
}
