import 'package:adaptive_motion_arcade/game/input/arcade_input.dart';
import 'package:adaptive_motion_arcade/game/music_maker_session.dart';
import 'package:adaptive_motion_arcade/screens/music_maker_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test_support/localized_test_app.dart';

void main() {
  testWidgets('touch and keyboard play the visible four-note phrase', (
    tester,
  ) async {
    final player = _RecordingNotePlayer();
    await tester.pumpWidget(
      localizedTestApp(home: MusicMakerScreen(notePlayer: player)),
    );
    await tester.pump();

    expect(find.text('Play Joybit\'s trumpet'), findsOneWidget);
    expect(find.text('Notes played: 0'), findsOneWidget);
    expect(player.preloadCount, 1);

    await tester.ensureVisible(
      find.byKey(const Key('music-game-primary-action')),
    );
    await tester.tap(find.byKey(const Key('music-game-primary-action')));
    await tester.pump();
    expect(find.text('DO!'), findsOneWidget);
    expect(find.text('Note played: 1'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(find.text('RE!'), findsOneWidget);
    expect(find.text('Notes played: 2'), findsOneWidget);
    expect(
      player.played,
      <MusicMakerNote>[MusicMakerNote.doNote, MusicMakerNote.reNote],
    );

    await tester.tap(find.byKey(const Key('music-game-reset-button')));
    await tester.pump();
    expect(find.text('Notes played: 0'), findsOneWidget);
    expect(find.text('Ready for your first note'), findsOneWidget);
  });

  testWidgets('motion loss pauses notes until calibrated input is ready', (
    tester,
  ) async {
    final input = ArcadeInputController();
    final status = ValueNotifier(ArcadeMotionInputStatus.trackingLost);
    final player = _RecordingNotePlayer();
    addTearDown(input.dispose);
    addTearDown(status.dispose);

    await tester.pumpWidget(
      localizedTestApp(
        home: MusicMakerScreen(
          inputController: input,
          motionInputStatus: status,
          notePlayer: player,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Tracking paused'), findsOneWidget);
    input.triggerPrimaryAction(
      source: ArcadeInputSource.motion,
      timestamp: Duration.zero,
    );
    await tester.pump();
    expect(player.played, isEmpty);

    status.value = ArcadeMotionInputStatus.ready;
    await tester.pump();
    expect(find.text('Motion control ready'), findsOneWidget);
    input.triggerPrimaryAction(
      source: ArcadeInputSource.motion,
      timestamp: const Duration(milliseconds: 100),
    );
    await tester.pump();
    expect(player.played, <MusicMakerNote>[MusicMakerNote.doNote]);
    expect(find.text('Note played: 1'), findsOneWidget);

    status.value = ArcadeMotionInputStatus.returnToRest;
    await tester.pump();
    expect(find.text('Return comfortably to rest'), findsOneWidget);
  });

  testWidgets('audio failure keeps visual note play available', (tester) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: MusicMakerScreen(notePlayer: _FailingNotePlayer()),
      ),
    );
    await tester.pump();

    expect(find.text('Sound unavailable'), findsOneWidget);
    expect(
      find.text(
        'The visual notes still work. Check the device volume and try again '
        'later.',
      ),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('music-game-primary-action')),
    );
    await tester.tap(find.byKey(const Key('music-game-primary-action')));
    await tester.pump();
    expect(find.text('DO!'), findsOneWidget);
    expect(find.text('Note played: 1'), findsOneWidget);
  });

  testWidgets('Spanish music game fits a narrow phone', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      localizedTestApp(
        locale: const Locale('es'),
        home: MusicMakerScreen(notePlayer: _RecordingNotePlayer()),
      ),
    );
    await tester.pump();

    expect(find.text('Creador musical'), findsOneWidget);
    expect(find.text('Toca la trompeta de Joybit'), findsOneWidget);
    expect(find.text('Notas tocadas: 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _RecordingNotePlayer implements MusicNotePlayer {
  final List<MusicMakerNote> played = [];
  int preloadCount = 0;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> playNote(MusicMakerNote note) async {
    played.add(note);
  }

  @override
  Future<void> preload() async {
    preloadCount += 1;
  }
}

class _FailingNotePlayer implements MusicNotePlayer {
  @override
  Future<void> dispose() async {}

  @override
  Future<void> playNote(MusicMakerNote note) async {
    throw StateError('Audio unavailable in test.');
  }

  @override
  Future<void> preload() async {
    throw StateError('Audio unavailable in test.');
  }
}
