import 'dart:async';

import 'package:flutter/foundation.dart';

import 'input/arcade_input.dart';

enum MusicMakerNote { doNote, reNote, miNote, solNote }

abstract interface class MusicNotePlayer {
  Future<void> preload();

  Future<void> playNote(MusicMakerNote note);

  Future<void> dispose();
}

typedef MusicAudioErrorHandler = void Function(
  Object error,
  StackTrace stackTrace,
);

/// Camera-free state for the one-action Music Maker game.
///
/// Each accepted primary action advances a fixed four-note phrase. There is no
/// timer, failure state, or physical-performance score.
class MusicMakerSession extends ChangeNotifier {
  factory MusicMakerSession({
    required ArcadeInputController input,
    required MusicNotePlayer notePlayer,
    MusicAudioErrorHandler? onAudioError,
  }) {
    return MusicMakerSession._(input, notePlayer, onAudioError);
  }

  MusicMakerSession._(
    this._input,
    this._notePlayer,
    this._onAudioError,
  ) {
    _input.addListener(_handleInput);
  }

  static const noteSequence = <MusicMakerNote>[
    MusicMakerNote.doNote,
    MusicMakerNote.reNote,
    MusicMakerNote.miNote,
    MusicMakerNote.solNote,
  ];

  final ArcadeInputController _input;
  final MusicNotePlayer _notePlayer;
  final MusicAudioErrorHandler? _onAudioError;

  int _noteCount = 0;
  MusicMakerNote? _currentNote;
  ArcadeInputSource? _lastInputSource;
  bool _inputSuspended = false;
  bool _disposed = false;

  int get noteCount => _noteCount;
  MusicMakerNote? get currentNote => _currentNote;
  ArcadeInputSource? get lastInputSource => _lastInputSource;
  bool get inputSuspended => _inputSuspended;

  void setInputSuspended(bool suspended) {
    if (_inputSuspended == suspended) {
      return;
    }
    _inputSuspended = suspended;
    notifyListeners();
  }

  void reset() {
    _noteCount = 0;
    _currentNote = null;
    _lastInputSource = null;
    notifyListeners();
  }

  void _handleInput(ArcadeInputEvent event) {
    if (_inputSuspended || event.action != ArcadeInputAction.primaryAction) {
      return;
    }
    final note = noteSequence[_noteCount % noteSequence.length];
    _noteCount += 1;
    _currentNote = note;
    _lastInputSource = event.source;
    notifyListeners();
    unawaited(_playNote(note));
  }

  Future<void> _playNote(MusicMakerNote note) async {
    try {
      await _notePlayer.playNote(note);
    } on Object catch (error, stackTrace) {
      _onAudioError?.call(error, stackTrace);
    }
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _input.removeListener(_handleInput);
    super.dispose();
  }
}
