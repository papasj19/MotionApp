import 'package:adaptive_motion_arcade/screens/flap_to_fly_screen.dart';
import 'package:adaptive_motion_arcade/game/input/arcade_input.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test_support/localized_test_app.dart';

void main() {
  testWidgets('touch action starts play and restart restores ready state', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      localizedTestApp(home: const FlapToFlyScreen()),
    );
    await tester.pump();

    expect(find.text('Sky Sprint'), findsOneWidget);
    expect(find.text('Score: 0'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);
    expect(
      tester.getSemantics(find.byKey(const Key('game-primary-action'))).label,
      contains('Make Joybit fly'),
    );

    await tester.tap(find.byKey(const Key('game-primary-action')));
    await tester.pump();
    expect(find.text('FLYING'), findsOneWidget);

    await tester.tap(find.byKey(const Key('game-pause-button')));
    await tester.pump();
    expect(find.text('Paused'), findsOneWidget);

    await tester.tap(find.byKey(const Key('game-restart-button')));
    await tester.pump();
    expect(find.text('Score: 0'), findsOneWidget);
    expect(find.text('READY'), findsOneWidget);
    expect(find.text('Paused'), findsNothing);
    semantics.dispose();
  });

  testWidgets('Space sends the same primary game action', (tester) async {
    await tester.pumpWidget(
      localizedTestApp(home: const FlapToFlyScreen()),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(find.text('FLYING'), findsOneWidget);
  });

  testWidgets('collision shows game over and play again restarts', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(home: const FlapToFlyScreen()),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('game-primary-action')));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('Game over'), findsOneWidget);
    expect(
      find.byKey(const Key('game-over-restart-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('game-over-restart-button')));
    await tester.pump();

    expect(find.text('Game over'), findsNothing);
    expect(find.text('READY'), findsOneWidget);
    expect(find.text('Score: 0'), findsOneWidget);
  });

  testWidgets('calibrated motion drives play and loss suspends safely', (
    tester,
  ) async {
    final input = ArcadeInputController();
    final motionStatus = ValueNotifier(
      ArcadeMotionInputStatus.returnToRest,
    );
    addTearDown(input.dispose);
    addTearDown(motionStatus.dispose);

    await tester.pumpWidget(
      localizedTestApp(
        home: FlapToFlyScreen(
          inputController: input,
          motionInputStatus: motionStatus,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Return comfortably to rest'), findsOneWidget);

    motionStatus.value = ArcadeMotionInputStatus.ready;
    await tester.pump();
    expect(find.text('Motion control ready'), findsOneWidget);

    input.triggerPrimaryAction(
      source: ArcadeInputSource.motion,
      timestamp: const Duration(milliseconds: 100),
    );
    await tester.pump();
    expect(find.text('FLYING'), findsOneWidget);

    motionStatus.value = ArcadeMotionInputStatus.trackingLost;
    await tester.pump();
    expect(find.text('Tracking paused'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.descendant(
              of: find.byKey(const Key('game-primary-action')),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );

    motionStatus.value = ArcadeMotionInputStatus.returnToRest;
    await tester.pump();
    expect(find.text('Return comfortably to rest'), findsOneWidget);

    motionStatus.value = ArcadeMotionInputStatus.ready;
    await tester.pump();
    expect(find.text('Tracking paused'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(() => input.addListener((_) {}), returnsNormally);
  });

  testWidgets('Spanish game shell fits a narrow screen', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final input = ArcadeInputController();
    final motionStatus = ValueNotifier(ArcadeMotionInputStatus.ready);
    addTearDown(input.dispose);
    addTearDown(motionStatus.dispose);

    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('es'),
        home: FlapToFlyScreen(
          inputController: input,
          motionInputStatus: motionStatus,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Carrera Celeste'), findsOneWidget);
    expect(find.text('Puntos: 0'), findsOneWidget);
    expect(find.text('VOLAR'), findsOneWidget);
    expect(find.text('Control por movimiento listo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('large Spanish text fits compact landscape', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(640, 360);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('es'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: const FlapToFlyScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Carrera Celeste'), findsOneWidget);
    expect(find.text('VOLAR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
