import 'package:flame/game.dart';
import 'package:material_ui/material_ui.dart';

import '../game/flap_to_fly_game.dart';
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
              onPressed: _togglePause,
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: _gameState,
              builder: (context, _) => _GameControls(
                actionCount: _gameState.actionCount,
                paused: _gameState.paused,
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
    required this.actionCount,
    required this.paused,
    required this.onPrimaryAction,
  });

  final int actionCount;
  final bool paused;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final status = paused ? localizations.gamePaused : localizations.gameReady;
    final details = Semantics(
      container: true,
      liveRegion: true,
      label: localizations.gameStatusSemantics(status, actionCount),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            localizations.gamePreviewLabel,
            style: const TextStyle(
              color: ArcadeColors.arcadeYellow,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            localizations.gameActionCount(actionCount),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(localizations.gameInputInstructions),
        ],
      ),
    );
    final actionButton = Semantics(
      key: const Key('game-primary-action'),
      button: true,
      enabled: !paused,
      label: localizations.gamePrimaryActionSemantics,
      excludeSemantics: true,
      child: FilledButton.icon(
        onPressed: paused ? null : onPrimaryAction,
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
