import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../movement/movement_measurement.dart';
import '../theme/arcade_theme.dart';
import '../widgets/joybit_companion.dart';
import 'camera_screen.dart';
import 'flap_to_fly_screen.dart';

class QuickPlayScreen extends StatelessWidget {
  const QuickPlayScreen({
    super.key,
    this.cameraScreenBuilder,
    this.gamePreviewScreenBuilder,
  });

  final WidgetBuilder? cameraScreenBuilder;
  final WidgetBuilder? gamePreviewScreenBuilder;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: localizations.arcadeLobbyTooltip,
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.home_rounded),
        ),
        title: Text(localizations.quickPlayTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _QuickPlayIntroduction(),
                  const SizedBox(height: 20),
                  _MovementTileGrid(
                    onSelected: (movementType) =>
                        _openCalibration(context, movementType),
                  ),
                  const SizedBox(height: 18),
                  const _ComfortNote(),
                  const SizedBox(height: 18),
                  _GamePreviewCard(
                    onOpen: () => _openGamePreview(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openCalibration(
    BuildContext context,
    CalibrationMovementType movementType,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) {
          final injectedBuilder = cameraScreenBuilder;
          if (injectedBuilder != null) {
            return injectedBuilder(routeContext);
          }
          return CameraScreen(
            initialMovementType: movementType,
            onChangeMovement: () => Navigator.of(routeContext).pop(),
          );
        },
      ),
    );
  }

  void _openGamePreview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) =>
            gamePreviewScreenBuilder?.call(routeContext) ??
            const FlapToFlyScreen(),
      ),
    );
  }
}

class _QuickPlayIntroduction extends StatelessWidget {
  const _QuickPlayIntroduction();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ArcadeColors.deepViolet,
              border: Border.all(color: ArcadeColors.electricCyan, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              localizations.quickPlayChooseMovementStep,
              style: const TextStyle(
                color: ArcadeColors.electricCyan,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Semantics(
          header: true,
          child: Text(
            localizations.quickPlayComfortQuestion,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 12),
        JoybitCompanion(
          compact: true,
          message: localizations.quickPlayCompanionPrompt,
        ),
      ],
    );
  }
}

class _MovementTileGrid extends StatelessWidget {
  const _MovementTileGrid({required this.onSelected});

  final ValueChanged<CalibrationMovementType> onSelected;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnCount = constraints.maxWidth >= 820
            ? 4
            : constraints.maxWidth >= 360
                ? 2
                : 1;
        const spacing = 14.0;
        final width =
            (constraints.maxWidth - spacing * (columnCount - 1)) / columnCount;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: width,
              child: _MovementTile(
                key: const Key('movement-head'),
                label: localizations.movementHeadLabel,
                description: localizations.movementHeadDescription,
                icon: Icons.face_rounded,
                accent: ArcadeColors.arcadeYellow,
                onTap: () => onSelected(CalibrationMovementType.headTilt),
              ),
            ),
            SizedBox(
              width: width,
              child: _MovementTile(
                key: const Key('movement-wrist'),
                label: localizations.movementWristLabel,
                description: localizations.movementWristDescription,
                icon: Icons.pan_tool_alt_rounded,
                accent: ArcadeColors.softPink,
                onTap: () => onSelected(CalibrationMovementType.wristBend),
              ),
            ),
            SizedBox(
              width: width,
              child: _MovementTile(
                key: const Key('movement-finger'),
                label: localizations.movementFingerLabel,
                description: localizations.movementFingerDescription,
                icon: Icons.touch_app_rounded,
                accent: ArcadeColors.electricCyan,
                onTap: () =>
                    onSelected(CalibrationMovementType.indexFingerBend),
              ),
            ),
            SizedBox(
              width: width,
              child: _MovementTile(
                key: const Key('movement-leg'),
                label: localizations.movementLegLabel,
                description: localizations.movementLegDescription,
                icon: Icons.accessibility_new_rounded,
                accent: ArcadeColors.lavender,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.accent,
    this.onTap,
    super.key,
  });

  final String label;
  final String description;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final localizations = AppLocalizations.of(context);
    return Semantics(
      button: true,
      enabled: enabled,
      label: localizations.movementTileSemantics(label, description),
      child: Opacity(
        opacity: enabled ? 1 : 0.62,
        child: Container(
          decoration: BoxDecoration(
            color: ArcadeColors.royalPurple,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: enabled ? accent : ArcadeColors.deepViolet,
                offset: const Offset(5, 5),
              ),
            ],
          ),
          child: Material(
            color: ArcadeColors.deepViolet,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: accent, width: 3),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 180),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.15),
                          border: Border.all(color: accent, width: 3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: accent, size: 42),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(description, textAlign: TextAlign.center),
                      if (!enabled) ...[
                        const SizedBox(height: 8),
                        const _LaterBadge(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LaterBadge extends StatelessWidget {
  const _LaterBadge();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ArcadeColors.background,
        border: Border.all(color: ArcadeColors.warmCream),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        localizations.comingLater,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ComfortNote extends StatelessWidget {
  const _ComfortNote();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ArcadeColors.deepViolet,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArcadeColors.royalPurple, width: 2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite_rounded, color: ArcadeColors.softPink),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              localizations.quickPlayComfortNote,
            ),
          ),
        ],
      ),
    );
  }
}

class _GamePreviewCard extends StatelessWidget {
  const _GamePreviewCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          localizations.firstGameSectionLabel,
          style: const TextStyle(
            color: ArcadeColors.arcadeYellow,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          localizations.firstGameTitle,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        Text(localizations.firstGameDescription),
      ],
    );
    final button = FilledButton.icon(
      key: const Key('open-game-preview'),
      onPressed: onOpen,
      icon: const Icon(Icons.rocket_launch_rounded),
      label: Text(localizations.openGamePreview),
    );

    return Semantics(
      key: const Key('first-game-preview-card'),
      container: true,
      label: localizations.optionSemantics(
        localizations.firstGameTitle,
        localizations.firstGameDescription,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 660) {
                return Row(
                  children: [
                    const Icon(
                      Icons.flight_rounded,
                      color: ArcadeColors.electricCyan,
                      size: 56,
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: copy),
                    const SizedBox(width: 18),
                    button,
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  copy,
                  const SizedBox(height: 14),
                  button,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
