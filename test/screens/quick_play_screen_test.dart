import 'package:adaptive_motion_arcade/screens/quick_play_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test_support/localized_test_app.dart';

void main() {
  testWidgets('shows three supported movements and a disabled leg tile', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      localizedTestApp(home: const QuickPlayScreen()),
    );

    expect(find.text('Head'), findsOneWidget);
    expect(find.text('Hand / Wrist'), findsOneWidget);
    expect(find.text('Finger'), findsOneWidget);
    expect(find.text('Leg'), findsOneWidget);
    expect(find.text('COMING LATER'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const Key('movement-head'))).label,
      contains('Head. Tilt left or right.'),
    );

    await tester.ensureVisible(find.byKey(const Key('movement-leg')));
    await tester.tap(find.byKey(const Key('movement-leg')));
    await tester.pumpAndSettle();

    expect(find.byType(QuickPlayScreen), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('a supported movement opens calibration', (tester) async {
    await tester.pumpWidget(
      localizedTestApp(
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

  testWidgets('opens the first game preview without camera setup', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: QuickPlayScreen(
          gamePreviewScreenBuilder: (_) =>
              const Scaffold(body: Text('Injected game preview')),
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('open-game-preview')));
    await tester.tap(find.byKey(const Key('open-game-preview')));
    await tester.pumpAndSettle();

    expect(find.text('Injected game preview'), findsOneWidget);
  });

  testWidgets('default games button opens the game selection screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(home: const QuickPlayScreen()),
    );

    await tester.ensureVisible(find.byKey(const Key('open-game-preview')));
    await tester.tap(find.byKey(const Key('open-game-preview')));
    await tester.pumpAndSettle();

    expect(find.text('Pick your next game'), findsOneWidget);
    expect(find.text('Sky Sprint'), findsOneWidget);
    expect(find.text('Music Maker'), findsOneWidget);
  });

  testWidgets('movement tiles reflow on a narrow portrait phone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      localizedTestApp(home: const QuickPlayScreen()),
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
      localizedTestApp(home: const QuickPlayScreen()),
    );

    final headTop = tester.getTopLeft(find.byKey(const Key('movement-head')));
    final legTop = tester.getTopLeft(find.byKey(const Key('movement-leg')));
    expect(headTop.dy, legTop.dy);
    expect(legTop.dx, greaterThan(headTop.dx));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Spanish copy and semantics fit a narrow phone', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('es'),
        home: const QuickPlayScreen(),
      ),
    );

    expect(find.text('Juego rápido'), findsOneWidget);
    expect(find.text('¿Qué movimiento te resulta cómodo hoy?'), findsOneWidget);
    expect(find.text('Mano / Muñeca'), findsOneWidget);
    expect(find.text('PRÓXIMAMENTE'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const Key('movement-head'))).label,
      contains('Cabeza. Inclínala a la izquierda o a la derecha.'),
    );
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
