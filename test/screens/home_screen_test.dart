import 'package:adaptive_motion_arcade/screens/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('shows the Stage 3 home screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Adaptive Motion Arcade'), findsOneWidget);
    expect(find.text('Move in your way. Play in your way.'), findsOneWidget);
    expect(find.text('Hand tracking ready to test'), findsOneWidget);
    expect(find.text('Open hand tracking preview'), findsOneWidget);
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

    await tester.tap(find.text('Open hand tracking preview'));
    await tester.pumpAndSettle();

    expect(find.text('Injected camera screen'), findsOneWidget);
  });
}
