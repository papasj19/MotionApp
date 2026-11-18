import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../game/asset_music_note_player.dart';
import '../game/input/arcade_input.dart';
import '../game/music_maker_session.dart';
import '../l10n/app_localizations.dart';
import '../theme/arcade_theme.dart';

class MusicMakerScreen extends StatefulWidget {
  const MusicMakerScreen({
    this.inputController,
    this.motionInputStatus,
    this.notePlayer,
    super.key,
  });

  final ArcadeInputController? inputController;
  final ValueListenable<ArcadeMotionInputStatus>? motionInputStatus;
  final MusicNotePlayer? notePlayer;

  @override
  State<MusicMakerScreen> createState() => _MusicMakerScreenState();
}

class _MusicMakerScreenState extends State<MusicMakerScreen> {
  late final ArcadeInputController _input;
  late final MusicNotePlayer _notePlayer;
  late final MusicMakerSession _session;
  late final bool _ownsInput;
  late final bool _ownsNotePlayer;
  final Stopwatch _inputClock = Stopwatch();

  ArcadeMotionInputStatus? _motionStatus;
  bool _audioUnavailable = false;

  @override
  void initState() {
    super.initState();
    _ownsInput = widget.inputController == null;
    _ownsNotePlayer = widget.notePlayer == null;
    _input = widget.inputController ?? ArcadeInputController();
    _notePlayer = widget.notePlayer ?? AssetMusicNotePlayer();
    _session = MusicMakerSession(
      input: _input,
      notePlayer: _notePlayer,
      onAudioError: _handleAudioError,
    );

    final motionInputStatus = widget.motionInputStatus;
    if (motionInputStatus != null) {
      _motionStatus = motionInputStatus.value;
      motionInputStatus.addListener(_handleMotionStatusChanged);
      _session.setInputSuspended(
        _motionStatus != ArcadeMotionInputStatus.ready,
      );
    }
    _inputClock.start();
    unawaited(_preloadAudio());
  }

  @override
  void dispose() {
    _inputClock.stop();
    widget.motionInputStatus?.removeListener(_handleMotionStatusChanged);
    _session.dispose();
    if (_ownsInput) {
      _input.dispose();
    }
    if (_ownsNotePlayer) {
      unawaited(_notePlayer.dispose());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('music-game-exit-button'),
          tooltip: localizations.gameExitTooltip,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(localizations.musicGameTitle),
        actions: [
          AnimatedBuilder(
            animation: _session,
            builder: (context, _) => IconButton(
              key: const Key('music-game-reset-button'),
              tooltip: localizations.musicGameResetTooltip,
              onPressed: _session.noteCount == 0 ? null : _session.reset,
              icon: const Icon(Icons.replay_rounded),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Focus(
          autofocus: true,
          onKeyEvent: _handleKeyEvent,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: AnimatedBuilder(
                    animation: _session,
                    builder: (context, _) => _buildGame(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGame(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final currentNote = _session.currentNote;
    final currentNoteName =
        currentNote == null ? null : _localizedNote(localizations, currentNote);
    final announcement = currentNoteName == null
        ? localizations.musicGameReady
        : localizations.musicGameNotePlayed(currentNoteName);
    final instruction = widget.motionInputStatus == null
        ? localizations.musicGameKeyboardInstruction
        : localizations.musicGameMotionInstruction;
    final inputEnabled = !_session.inputSuspended;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            localizations.musicGameHeading,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: ArcadeColors.arcadeYellow,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        const SizedBox(height: 6),
        Text(instruction, textAlign: TextAlign.center),
        if (_motionStatus case final status?) ...[
          const SizedBox(height: 14),
          _MusicMotionBanner(status: status),
        ],
        if (_audioUnavailable) ...[
          const SizedBox(height: 14),
          _AudioUnavailableBanner(),
        ],
        const SizedBox(height: 18),
        Semantics(
          liveRegion: true,
          container: true,
          label: localizations.musicGameStatusSemantics(
            announcement,
            _session.noteCount,
            instruction,
          ),
          child: _MusicInstrumentStage(
            actionCount: _session.noteCount,
            currentNote: currentNote,
            currentNoteName: currentNoteName,
            announcement: announcement,
          ),
        ),
        const SizedBox(height: 18),
        _NoteSequence(
          currentNote: currentNote,
          localizeNote: (note) => _localizedNote(localizations, note),
        ),
        const SizedBox(height: 16),
        Text(
          localizations.musicGameNotesPlayed(_session.noteCount),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 14),
        Semantics(
          key: const Key('music-game-primary-action'),
          button: true,
          enabled: inputEnabled,
          label: localizations.musicGameActionSemantics,
          excludeSemantics: true,
          child: FilledButton.icon(
            onPressed: inputEnabled ? _triggerTouchAction : null,
            icon: const Icon(Icons.music_note_rounded, size: 30),
            label: Text(localizations.musicGameAction),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(72),
              textStyle: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _preloadAudio() async {
    try {
      await _notePlayer.preload();
    } on Object catch (error, stackTrace) {
      _handleAudioError(error, stackTrace);
    }
  }

  void _handleAudioError(Object error, StackTrace stackTrace) {
    if (!mounted || _audioUnavailable) {
      return;
    }
    setState(() => _audioUnavailable = true);
  }

  void _handleMotionStatusChanged() {
    final status = widget.motionInputStatus?.value;
    if (!mounted || status == null) {
      return;
    }
    _motionStatus = status;
    _session.setInputSuspended(status != ArcadeMotionInputStatus.ready);
    setState(() {});
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final isPrimaryKey = event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (event is KeyDownEvent && isPrimaryKey) {
      _input.triggerPrimaryAction(
        source: ArcadeInputSource.keyboard,
        timestamp: event.timeStamp,
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _triggerTouchAction() {
    _input.triggerPrimaryAction(
      source: ArcadeInputSource.touch,
      timestamp: _inputClock.elapsed,
    );
  }

  String _localizedNote(
    AppLocalizations localizations,
    MusicMakerNote note,
  ) {
    return switch (note) {
      MusicMakerNote.doNote => localizations.musicNoteDo,
      MusicMakerNote.reNote => localizations.musicNoteRe,
      MusicMakerNote.miNote => localizations.musicNoteMi,
      MusicMakerNote.solNote => localizations.musicNoteSol,
    };
  }
}

class _MusicInstrumentStage extends StatelessWidget {
  const _MusicInstrumentStage({
    required this.actionCount,
    required this.currentNote,
    required this.currentNoteName,
    required this.announcement,
  });

  final int actionCount;
  final MusicMakerNote? currentNote;
  final String? currentNoteName;
  final String announcement;

  @override
  Widget build(BuildContext context) {
    final accent = _noteColor(currentNote);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ArcadeColors.deepViolet,
        border: Border.all(color: accent, width: 3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            key: ValueKey(actionCount),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 520),
            builder: (context, progress, child) {
              final pulse = actionCount == 0
                  ? 0.0
                  : math.sin(progress * math.pi).clamp(0.0, 1.0);
              return SizedBox(
                height: 170,
                width: double.infinity,
                child: CustomPaint(
                  painter: _PixelTrumpetPainter(
                    accent: accent,
                    pulse: pulse,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              currentNoteName == null ? announcement : '$currentNoteName!',
              key: ValueKey(actionCount),
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteSequence extends StatelessWidget {
  const _NoteSequence({
    required this.currentNote,
    required this.localizeNote,
  });

  final MusicMakerNote? currentNote;
  final String Function(MusicMakerNote note) localizeNote;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: MusicMakerSession.noteSequence.map((note) {
        final selected = note == currentNote;
        final color = _noteColor(note);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 68,
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? color
                : ArcadeColors.deepViolet.withValues(alpha: 0.82),
            border: Border.all(color: color, width: selected ? 4 : 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            localizeNote(note),
            style: TextStyle(
              color:
                  selected ? ArcadeColors.background : ArcadeColors.warmCream,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _MusicMotionBanner extends StatelessWidget {
  const _MusicMotionBanner({required this.status});

  final ArcadeMotionInputStatus status;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final (title, instruction, accent) = switch (status) {
      ArcadeMotionInputStatus.ready => (
          localizations.gameMotionControlReady,
          localizations.musicGameMotionReadyInstruction,
          ArcadeColors.electricCyan,
        ),
      ArcadeMotionInputStatus.returnToRest => (
          localizations.gameMotionReturnToRest,
          localizations.gameMotionReturnToRestInstruction,
          ArcadeColors.arcadeYellow,
        ),
      ArcadeMotionInputStatus.trackingLost => (
          localizations.gameMotionTrackingPaused,
          localizations.gameMotionTrackingPausedInstruction,
          ArcadeColors.softPink,
        ),
    };
    return Semantics(
      liveRegion: true,
      container: true,
      label: '$title. $instruction',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ArcadeColors.deepViolet,
          border: Border.all(color: accent, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(Icons.accessibility_new_rounded, color: accent, size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(instruction),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AudioUnavailableBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ArcadeColors.deepViolet,
          border: Border.all(color: ArcadeColors.softPink, width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.volume_off_rounded,
              color: ArcadeColors.softPink,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.musicGameSoundUnavailableTitle,
                    style: const TextStyle(
                      color: ArcadeColors.softPink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(localizations.musicGameSoundUnavailableDescription),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _noteColor(MusicMakerNote? note) {
  return switch (note) {
    MusicMakerNote.doNote => ArcadeColors.softPink,
    MusicMakerNote.reNote => ArcadeColors.electricCyan,
    MusicMakerNote.miNote => ArcadeColors.arcadeYellow,
    MusicMakerNote.solNote => ArcadeColors.lavender,
    null => ArcadeColors.electricCyan,
  };
}

class _PixelTrumpetPainter extends CustomPainter {
  const _PixelTrumpetPainter({required this.accent, required this.pulse});

  final Color accent;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = math.min(size.width / 14, size.height / 7);
    final centerY = size.height * 0.52;
    final startX = (size.width - unit * 11.5) / 2;
    final outline = Paint()..color = ArcadeColors.background;
    final brass = Paint()..color = ArcadeColors.arcadeYellow;
    final shine = Paint()..color = ArcadeColors.warmCream;
    final accentPaint = Paint()..color = accent;

    canvas.drawRect(
      Rect.fromLTWH(startX, centerY - unit * 0.35, unit, unit * 0.7),
      accentPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        startX + unit * 0.8,
        centerY - unit * 0.55,
        unit * 6.8,
        unit * 1.1,
      ),
      outline,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        startX + unit,
        centerY - unit * 0.38,
        unit * 6.6,
        unit * 0.76,
      ),
      brass,
    );

    final bell = Path()
      ..moveTo(startX + unit * 7.2, centerY - unit * 0.65)
      ..lineTo(startX + unit * 10.4, centerY - unit * 2.15)
      ..lineTo(startX + unit * 10.4, centerY + unit * 2.15)
      ..lineTo(startX + unit * 7.2, centerY + unit * 0.65)
      ..close();
    canvas.drawPath(bell, outline);
    final innerBell = Path()
      ..moveTo(startX + unit * 7.45, centerY - unit * 0.48)
      ..lineTo(startX + unit * 10.05, centerY - unit * 1.72)
      ..lineTo(startX + unit * 10.05, centerY + unit * 1.72)
      ..lineTo(startX + unit * 7.45, centerY + unit * 0.48)
      ..close();
    canvas.drawPath(innerBell, brass);

    for (var index = 0; index < 3; index += 1) {
      final valveX = startX + unit * (3.2 + index * 1.05);
      canvas.drawRect(
        Rect.fromLTWH(
          valveX,
          centerY - unit * 1.55,
          unit * 0.56,
          unit * 2.45,
        ),
        outline,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          valveX + unit * 0.12,
          centerY - unit * 1.35,
          unit * 0.32,
          unit * 2.0,
        ),
        accentPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          valveX - unit * 0.1,
          centerY - unit * 1.85,
          unit * 0.76,
          unit * 0.34,
        ),
        shine,
      );
    }

    if (pulse > 0) {
      final ringPaint = Paint()
        ..color = accent.withValues(alpha: 0.75 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      final bellX = startX + unit * (10.7 + pulse * 0.8);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(bellX, centerY),
          width: unit * (0.8 + pulse * 0.8),
          height: unit * (2.0 + pulse * 1.7),
        ),
        ringPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_PixelTrumpetPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.pulse != pulse;
  }
}
