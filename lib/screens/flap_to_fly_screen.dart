import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../game/flap_to_fly_game.dart';
import '../game/flap_to_fly_mechanics.dart';
import '../game/input/arcade_input.dart';
import '../l10n/app_localizations.dart';
import '../theme/arcade_theme.dart';

class FlapToFlyScreen extends StatefulWidget {
  const FlapToFlyScreen({
    this.inputController,
    this.motionInputStatus,
    super.key,
  });

  final ArcadeInputController? inputController;
  final ValueListenable<ArcadeMotionInputStatus>? motionInputStatus;

  @override
  State<FlapToFlyScreen> createState() => _FlapToFlyScreenState();
}

class _FlapToFlyScreenState extends State<FlapToFlyScreen> {
  late final ArcadeInputController _input;
  late final FlapToFlyGameState _gameState;
  late final FlapToFlyGame _game;
  late final bool _ownsInput;
  final Stopwatch _inputClock = Stopwatch();
  ArcadeMotionInputStatus? _motionStatus;

  @override
  void initState() {
    super.initState();
    _ownsInput = widget.inputController == null;
    _input = widget.inputController ?? ArcadeInputController();
    _gameState = FlapToFlyGameState();
    _game = FlapToFlyGame(input: _input, gameState: _gameState);
    final motionInputStatus = widget.motionInputStatus;
    if (motionInputStatus != null) {
      _motionStatus = motionInputStatus.value;
      motionInputStatus.addListener(_handleMotionStatusChanged);
      _applyMotionStatus(_motionStatus!);
    }
    _inputClock.start();
  }

  @override
  void dispose() {
    _inputClock.stop();
    widget.motionInputStatus?.removeListener(_handleMotionStatusChanged);
    if (_ownsInput) {
      _input.dispose();
    }
    _gameState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('game-exit-button'),
          tooltip: localizations.gameExitTooltip,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(localizations.gameTitle),
        actions: [
          AnimatedBuilder(
            animation: _gameState,
            builder: (context, _) => IconButton(
              key: const Key('game-pause-button'),
              tooltip: _gameState.paused
                  ? localizations.gameResumeTooltip
                  : localizations.gamePauseTooltip,
              onPressed: _gameState.runStatus == FlapToFlyRunStatus.gameOver ||
                      _gameState.inputSuspended
                  ? null
                  : _togglePause,
              icon: Icon(
                _gameState.paused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
              ),
            ),
          ),
          IconButton(
            key: const Key('game-restart-button'),
            tooltip: localizations.gameRestartTooltip,
            onPressed: _game.restartGame,
            icon: const Icon(Icons.replay_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: ArcadeColors.electricCyan,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ExcludeSemantics(
                          child: GameWidget<FlapToFlyGame>(
                            key: const Key('flap-to-fly-game'),
                            game: _game,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _gameState,
                          builder: (context, _) {
                            if (!_gameState.paused) {
                              return const SizedBox.shrink();
                            }
                            return ColoredBox(
                              color: ArcadeColors.background.withValues(
                                alpha: 0.82,
                              ),
                              child: Center(
                                child: Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    localizations.gamePaused,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        if (_motionStatus case final status?)
                          if (status != ArcadeMotionInputStatus.ready)
                            _MotionInputOverlay(status: status),
                        AnimatedBuilder(
                          animation: _gameState,
                          builder: (context, _) {
                            if (_gameState.runStatus !=
                                FlapToFlyRunStatus.gameOver) {
                              return const SizedBox.shrink();
                            }
                            return ColoredBox(
                              color: ArcadeColors.background.withValues(
                                alpha: 0.88,
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Semantics(
                                    liveRegion: true,
                                    container: true,
                                    label: localizations.gameOverSemantics(
                                      _gameState.score,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          localizations.gameOver,
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineMedium
                                              ?.copyWith(
                                                color:
                                                    ArcadeColors.arcadeYellow,
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          localizations.gameScore(
                                            _gameState.score,
                                          ),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                        const SizedBox(height: 14),
                                        FilledButton.icon(
                                          key: const Key(
                                            'game-over-restart-button',
                                          ),
                                          onPressed: _game.restartGame,
                                          icon: const Icon(
                                            Icons.replay_rounded,
                                          ),
                                          label: Text(
                                            localizations.gameRestartAction,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _gameState,
              builder: (context, _) => _GameControls(
                score: _gameState.score,
                paused: _gameState.paused,
                inputSuspended: _gameState.inputSuspended,
                runStatus: _gameState.runStatus,
                motionInputStatus: _motionStatus,
                onPrimaryAction: _triggerTouchAction,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _togglePause() {
    if (_gameState.paused) {
      _game.resumeGame();
    } else {
      _game.pauseGame();
    }
  }

  void _triggerTouchAction() {
    _input.triggerPrimaryAction(
      source: ArcadeInputSource.touch,
      timestamp: _inputClock.elapsed,
    );
  }

  void _handleMotionStatusChanged() {
    final status = widget.motionInputStatus?.value;
    if (!mounted || status == null) {
      return;
    }
    _motionStatus = status;
    _applyMotionStatus(status);
    setState(() {});
  }

  void _applyMotionStatus(ArcadeMotionInputStatus status) {
    if (status == ArcadeMotionInputStatus.ready) {
      _game.resumeAfterInput();
    } else {
      _game.suspendForInput();
    }
  }
}

class _MotionInputOverlay extends StatelessWidget {
  const _MotionInputOverlay({required this.status});

  final ArcadeMotionInputStatus status;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final (title, instruction) = switch (status) {
      ArcadeMotionInputStatus.ready => (
          localizations.gameMotionControlReady,
          localizations.gameMotionReadyInstruction,
        ),
      ArcadeMotionInputStatus.returnToRest => (
          localizations.gameMotionReturnToRest,
          localizations.gameMotionReturnToRestInstruction,
        ),
      ArcadeMotionInputStatus.trackingLost => (
          localizations.gameMotionTrackingPaused,
          localizations.gameMotionTrackingPausedInstruction,
        ),
    };
    return ColoredBox(
      color: ArcadeColors.background.withValues(alpha: 0.88),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Semantics(
            liveRegion: true,
            container: true,
            label: '$title. $instruction',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.accessibility_new_rounded,
                  color: ArcadeColors.electricCyan,
                  size: 46,
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: ArcadeColors.arcadeYellow,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(instruction, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameControls extends StatelessWidget {
  const _GameControls({
    required this.score,
    required this.paused,
    required this.inputSuspended,
    required this.runStatus,
    required this.motionInputStatus,
    required this.onPrimaryAction,
  });

  final int score;
  final bool paused;
  final bool inputSuspended;
  final FlapToFlyRunStatus runStatus;
  final ArcadeMotionInputStatus? motionInputStatus;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final status = paused
        ? localizations.gamePaused
        : switch (runStatus) {
            FlapToFlyRunStatus.ready => localizations.gameReady,
            FlapToFlyRunStatus.running => localizations.gameFlying,
            FlapToFlyRunStatus.gameOver => localizations.gameOver,
          };
    final instruction = switch (runStatus) {
      FlapToFlyRunStatus.ready => localizations.gameReadyInstruction,
      FlapToFlyRunStatus.running => localizations.gameFlyingInstruction,
      FlapToFlyRunStatus.gameOver => localizations.gameOverInstruction,
    };
    final inputEnabled =
        !paused && !inputSuspended && runStatus != FlapToFlyRunStatus.gameOver;
    final details = Semantics(
      container: true,
      liveRegion: true,
      label: localizations.gameStatusSemantics(status, score, instruction),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status.toUpperCase(),
            style: const TextStyle(
              color: ArcadeColors.arcadeYellow,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            localizations.gameScore(score),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(instruction),
          if (motionInputStatus == ArcadeMotionInputStatus.ready) ...[
            const SizedBox(height: 4),
            Text(
              localizations.gameMotionControlReady,
              style: const TextStyle(
                color: ArcadeColors.electricCyan,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
    final actionButton = Semantics(
      key: const Key('game-primary-action'),
      button: true,
      enabled: inputEnabled,
      label: localizations.gamePrimaryActionSemantics,
      excludeSemantics: true,
      child: FilledButton.icon(
        onPressed: inputEnabled ? onPrimaryAction : null,
        icon: const Icon(Icons.keyboard_double_arrow_up_rounded, size: 30),
        label: Text(localizations.gamePrimaryAction),
        style: FilledButton.styleFrom(
          minimumSize: const Size(190, 72),
          textStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: ArcadeColors.deepViolet,
        border: Border(
          top: BorderSide(color: ArcadeColors.royalPurple, width: 2),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 620) {
            return Row(
              children: [
                Expanded(child: details),
                const SizedBox(width: 16),
                actionButton,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              details,
              const SizedBox(height: 10),
              actionButton,
            ],
          );
        },
      ),
    );
  }
}
