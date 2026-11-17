import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../game/input/arcade_input.dart';
import '../l10n/app_localizations.dart';
import '../theme/arcade_theme.dart';
import 'flap_to_fly_screen.dart';

class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({
    this.inputController,
    this.motionInputStatus,
    this.skySprintBuilder,
    super.key,
  });

  final ArcadeInputController? inputController;
  final ValueListenable<ArcadeMotionInputStatus>? motionInputStatus;
  final WidgetBuilder? skySprintBuilder;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: localizations.donePlaying,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(localizations.gameSelectionTitle),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        localizations.gameSelectionHeading,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      motionInputStatus == null
                          ? localizations.gameSelectionKeyboardDescription
                          : localizations.gameSelectionMotionDescription,
                      textAlign: TextAlign.center,
                    ),
                    if (motionInputStatus != null) ...[
                      const SizedBox(height: 14),
                      _MotionStatusBanner(status: motionInputStatus!),
                    ],
                    const SizedBox(height: 22),
                    _GameCartridgeGrid(
                      onPlaySkySprint: () => _openSkySprint(context),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      key: const Key('done-playing-button'),
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.home_rounded),
                      label: Text(localizations.donePlaying),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openSkySprint(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (routeContext) =>
            skySprintBuilder?.call(routeContext) ??
            FlapToFlyScreen(
              inputController: inputController,
              motionInputStatus: motionInputStatus,
            ),
      ),
    );
  }
}

class _GameCartridgeGrid extends StatelessWidget {
  const _GameCartridgeGrid({required this.onPlaySkySprint});

  final VoidCallback onPlaySkySprint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 18.0;
        final columns = constraints.maxWidth >= 700 ? 2 : 1;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: cardWidth,
              child: _GameCartridge(
                key: const Key('sky-sprint-cartridge'),
                title: AppLocalizations.of(context).firstGameTitle,
                description:
                    AppLocalizations.of(context).skySprintGameDescription,
                icon: Icons.flight_rounded,
                accent: ArcadeColors.electricCyan,
                actionLabel: AppLocalizations.of(context).playSelectedGame,
                onPressed: onPlaySkySprint,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _GameCartridge(
                key: const Key('music-game-cartridge'),
                title: AppLocalizations.of(context).musicGameTitle,
                description: AppLocalizations.of(context).musicGameDescription,
                icon: Icons.music_note_rounded,
                accent: ArcadeColors.softPink,
                actionLabel: AppLocalizations.of(context).comingNext,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GameCartridge extends StatelessWidget {
  const _GameCartridge({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.actionLabel,
    this.onPressed,
    super.key,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: enabled,
      enabled: enabled,
      label: '$title. $description. $actionLabel',
      child: Opacity(
        opacity: enabled ? 1 : 0.72,
        child: Container(
          decoration: BoxDecoration(
            color: ArcadeColors.deepViolet,
            border: Border.all(color: accent, width: 3),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: ArcadeColors.royalPurple,
                offset: Offset(6, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 260),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        border: Border.all(color: accent, width: 3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: accent, size: 46),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(description),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: onPressed,
                    icon: Icon(
                      enabled
                          ? Icons.play_arrow_rounded
                          : Icons.construction_rounded,
                    ),
                    label: Text(actionLabel),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MotionStatusBanner extends StatelessWidget {
  const _MotionStatusBanner({required this.status});

  final ValueListenable<ArcadeMotionInputStatus> status;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ArcadeMotionInputStatus>(
      valueListenable: status,
      builder: (context, value, _) {
        final localizations = AppLocalizations.of(context);
        final (title, instruction, accent) = switch (value) {
          ArcadeMotionInputStatus.ready => (
              localizations.gameMotionControlReady,
              localizations.gameSelectionMotionReadyInstruction,
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
      },
    );
  }
}
