import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';

import '../game/flap_to_fly_game.dart';
import '../game/flap_to_fly_mechanics.dart';
import '../game/input/arcade_input.dart';
import '../l10n/app_localizations.dart';
import '../theme/arcade_theme.dart';

class FlapToFlyScreen extends StatefulWidget {
  const FlapToFlyScreen({super.key});

  @override
  State<FlapToFlyScreen> createState() => _FlapToFlyScreenState();
}

class _FlapToFlyScreenState extends State<FlapToFlyScreen> {
  late final ArcadeInputController _input;
  late final FlapToFlyGameState _gameState;
  late final FlapToFlyGame _game;
  final Stopwatch _inputClock = Stopwatch();

  @override
  void initState() {
    super.initState();
    _input = ArcadeInputController();
    _gameState = FlapToFlyGameState();
    _game = FlapToFlyGame(input: _input, gameState: _gameState);
    _inputClock.start();
  }

  @override
  void dispose() {
    _inputClock.stop();
    _input.dispose();
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
              onPressed: _gameState.runStatus == FlapToFlyRunStatus.gameOver
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
                runStatus: _gameState.runStatus,
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
}

class _GameControls extends StatelessWidget {
  const _GameControls({
    required this.score,
    required this.paused,
    required this.runStatus,
    required this.onPrimaryAction,
  });

  final int score;
  final bool paused;
  final FlapToFlyRunStatus runStatus;
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
    final inputEnabled = !paused && runStatus != FlapToFlyRunStatus.gameOver;
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
