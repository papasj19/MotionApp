import 'package:adaptive_motion_arcade/game/input/arcade_input.dart';
import 'package:adaptive_motion_arcade/game/music_maker_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cycles through the same four-note phrase for every input source',
      () async {
    final input = ArcadeInputController();
    final player = _RecordingNotePlayer();
    final session = MusicMakerSession(input: input, notePlayer: player);
    addTearDown(input.dispose);
    addTearDown(session.dispose);

    final sources = <ArcadeInputSource>[
      ArcadeInputSource.touch,
      ArcadeInputSource.keyboard,
      ArcadeInputSource.motion,
      ArcadeInputSource.touch,
      ArcadeInputSource.motion,
    ];
    for (var index = 0; index < sources.length; index += 1) {
      input.triggerPrimaryAction(
        source: sources[index],
        timestamp: Duration(milliseconds: index * 100),
      );
    }
    await Future<void>.delayed(Duration.zero);

    expect(
      player.played,
      <MusicMakerNote>[
        MusicMakerNote.doNote,
        MusicMakerNote.reNote,
        MusicMakerNote.miNote,
        MusicMakerNote.solNote,
        MusicMakerNote.doNote,
      ],
    );
    expect(session.noteCount, 5);
    expect(session.currentNote, MusicMakerNote.doNote);
    expect(session.lastInputSource, ArcadeInputSource.motion);
  });

  test('tracking suspension blocks notes and reset is deterministic', () async {
    final input = ArcadeInputController();
    final player = _RecordingNotePlayer();
    final session = MusicMakerSession(input: input, notePlayer: player);
    addTearDown(input.dispose);
    addTearDown(session.dispose);

    session.setInputSuspended(true);
    input.triggerPrimaryAction(
      source: ArcadeInputSource.motion,
      timestamp: Duration.zero,
    );
    await Future<void>.delayed(Duration.zero);
    expect(player.played, isEmpty);
    expect(session.noteCount, 0);

    session.setInputSuspended(false);
    input.triggerPrimaryAction(
      source: ArcadeInputSource.motion,
      timestamp: const Duration(milliseconds: 100),
    );
    await Future<void>.delayed(Duration.zero);
    expect(player.played, <MusicMakerNote>[MusicMakerNote.doNote]);

    session.reset();
    expect(session.noteCount, 0);
    expect(session.currentNote, isNull);

    input.triggerPrimaryAction(
      source: ArcadeInputSource.touch,
      timestamp: const Duration(milliseconds: 200),
    );
    await Future<void>.delayed(Duration.zero);
    expect(player.played.last, MusicMakerNote.doNote);
  });
}

class _RecordingNotePlayer implements MusicNotePlayer {
  final List<MusicMakerNote> played = [];

  @override
  Future<void> dispose() async {}

  @override
  Future<void> playNote(MusicMakerNote note) async {
    played.add(note);
  }

  @override
  Future<void> preload() async {}
}
