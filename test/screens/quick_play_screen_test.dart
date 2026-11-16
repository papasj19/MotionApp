import 'package:adaptive_motion_arcade/screens/quick_play_screen.dart';
import 'package:adaptive_motion_arcade/theme/arcade_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('shows three supported movements and a disabled leg tile', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(theme: buildArcadeTheme(), home: const QuickPlayScreen()),
    );

    expect(find.text('Head'), findsOneWidget);
    expect(find.text('Hand / Wrist'), findsOneWidget);
    expect(find.text('Finger'), findsOneWidget);
    expect(find.text('Leg'), findsOneWidget);
    expect(find.text('COMING LATER'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('movement-leg')));
    await tester.tap(find.byKey(const Key('movement-leg')));
    await tester.pumpAndSettle();

    expect(find.byType(QuickPlayScreen), findsOneWidget);
  });

  testWidgets('a supported movement opens calibration', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildArcadeTheme(),
        home: QuickPlayScreen(
          cameraScreenBuilder: (_) =>
              const Scaffold(body: Text('Calibration route')),
        ),
      ),
    );

    await tester.ensureVisible(find.text('Head'));
    await tester.tap(find.text('Head'));
    await tester.pumpAndSettle();

    expect(find.text('Calibration route'), findsOneWidget);
  });

  testWidgets('movement tiles reflow on a narrow portrait phone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(theme: buildArcadeTheme(), home: const QuickPlayScreen()),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('What feels comfortable today?'), findsOneWidget);
    expect(find.text('Head'), findsOneWidget);
  });

  testWidgets('movement tiles use four columns on a tablet', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 768);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(theme: buildArcadeTheme(), home: const QuickPlayScreen()),
    );

    final headTop = tester.getTopLeft(find.byKey(const Key('movement-head')));
    final legTop = tester.getTopLeft(find.byKey(const Key('movement-leg')));
    expect(headTop.dy, legTop.dy);
    expect(legTop.dx, greaterThan(headTop.dx));
    expect(tester.takeException(), isNull);
  });
}
