import 'package:audioplayers/audioplayers.dart';

import 'music_maker_session.dart';

/// Plays the four original bundled Music Maker tones with a preloaded pool.
class AssetMusicNotePlayer implements MusicNotePlayer {
  static const _assetPaths = <MusicMakerNote, String>{
    MusicMakerNote.doNote: 'arcade/music_note_do.wav',
    MusicMakerNote.reNote: 'arcade/music_note_re.wav',
    MusicMakerNote.miNote: 'arcade/music_note_mi.wav',
    MusicMakerNote.solNote: 'arcade/music_note_sol.wav',
  };

  Future<Map<MusicMakerNote, AudioPool>>? _pools;
  bool _disposed = false;

  @override
  Future<void> preload() async {
    await _loadPools();
  }

  @override
  Future<void> playNote(MusicMakerNote note) async {
    if (_disposed) {
      return;
    }
    final pools = await _loadPools();
    if (_disposed) {
      return;
    }
    await pools[note]!.start(volume: 0.85);
  }

  Future<Map<MusicMakerNote, AudioPool>> _loadPools() {
    return _pools ??= Future.wait(
      _assetPaths.entries.map(
        (entry) async => MapEntry(
          entry.key,
          await AudioPool.createFromAsset(
            path: entry.value,
            minPlayers: 1,
            maxPlayers: 2,
            playerMode: PlayerMode.lowLatency,
          ),
        ),
      ),
    ).then(Map.fromEntries);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    final pools = _pools;
    if (pools == null) {
      return;
    }
    try {
      final loadedPools = await pools;
      await Future.wait(loadedPools.values.map((pool) => pool.dispose()));
    } on Object {
      // Loading failures are reported by the screen. There is nothing to
      // release when the native audio pool was not created.
    }
  }
}
