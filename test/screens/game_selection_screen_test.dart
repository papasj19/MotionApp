import 'package:adaptive_motion_arcade/game/input/arcade_input.dart';
import 'package:adaptive_motion_arcade/screens/game_selection_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test_support/localized_test_app.dart';

void main() {
  testWidgets('shows one playable game and one upcoming music game', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: GameSelectionScreen(
          skySprintBuilder: (_) =>
              const Scaffold(body: Text('Injected Sky Sprint')),
        ),
      ),
    );

    expect(find.text('Choose a game'), findsOneWidget);
    expect(find.text('Sky Sprint'), findsOneWidget);
    expect(find.text('Music Maker'), findsOneWidget);
    expect(find.text('COMING NEXT'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(const Key('music-game-cartridge')),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('sky-sprint-cartridge')),
        matching: find.text('PLAY'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Injected Sky Sprint'), findsOneWidget);

    Navigator.of(tester.element(find.text('Injected Sky Sprint'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Music Maker'), findsOneWidget);
  });

  testWidgets('shows live calibrated-control status', (tester) async {
    final input = ArcadeInputController();
    final status = ValueNotifier(ArcadeMotionInputStatus.returnToRest);
    addTearDown(input.dispose);
    addTearDown(status.dispose);

    await tester.pumpWidget(
      localizedTestApp(
        home: GameSelectionScreen(
          inputController: input,
          motionInputStatus: status,
        ),
      ),
    );

    expect(find.text('Return comfortably to rest'), findsOneWidget);

    status.value = ArcadeMotionInputStatus.ready;
    await tester.pump();
    expect(find.text('Motion control ready'), findsOneWidget);

    status.value = ArcadeMotionInputStatus.trackingLost;
    await tester.pump();
    expect(find.text('Tracking paused'), findsOneWidget);
  });

  testWidgets('Spanish game cartridges fit a narrow phone', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 720);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('es'),
        home: const GameSelectionScreen(),
      ),
    );

    expect(find.text('Elegir un juego'), findsOneWidget);
    expect(find.text('Carrera Celeste'), findsOneWidget);
    expect(find.text('Creador musical'), findsOneWidget);
    expect(find.text('PRÓXIMO JUEGO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('uses two cartridge columns on a tablet', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 768);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      localizedTestApp(home: const GameSelectionScreen()),
    );

    final skyTop = tester.getTopLeft(
      find.byKey(const Key('sky-sprint-cartridge')),
    );
    final musicTop = tester.getTopLeft(
      find.byKey(const Key('music-game-cartridge')),
    );
    expect(skyTop.dy, musicTop.dy);
    expect(musicTop.dx, greaterThan(skyTop.dx));
    expect(tester.takeException(), isNull);
  });
}
