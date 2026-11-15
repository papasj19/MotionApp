import 'package:adaptive_motion_arcade/screens/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('shows the Stage 5 home screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Adaptive Motion Arcade'), findsOneWidget);
    expect(find.text('Move in your way. Play in your way.'), findsOneWidget);
    expect(find.text('Comfortable calibration ready'), findsOneWidget);
    expect(find.text('Start comfortable calibration'), findsOneWidget);
    expect(
      find.text('Camera video stays in the live preview and is not saved.'),
      findsOneWidget,
    );
  });

  testWidgets('opens the camera route from the home screen', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          cameraScreenBuilder: (_) =>
              const Scaffold(body: Text('Injected camera screen')),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Start comfortable calibration'));
    await tester.tap(find.text('Start comfortable calibration'));
    await tester.pumpAndSettle();

    expect(find.text('Injected camera screen'), findsOneWidget);
  });
}
