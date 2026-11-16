import 'package:material_ui/material_ui.dart';

import '../movement/movement_measurement.dart';
import '../theme/arcade_theme.dart';
import '../widgets/joybit_companion.dart';
import 'camera_screen.dart';

class QuickPlayScreen extends StatelessWidget {
  const QuickPlayScreen({super.key, this.cameraScreenBuilder});

  final WidgetBuilder? cameraScreenBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Arcade lobby',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.home_rounded),
        ),
        title: const Text('Quick Play'),
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
}

class _QuickPlayIntroduction extends StatelessWidget {
  const _QuickPlayIntroduction();

  @override
  Widget build(BuildContext context) {
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
            child: const Text(
              'STEP 1 • CHOOSE MOVEMENT',
              style: TextStyle(
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
            'What feels comfortable today?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        const SizedBox(height: 12),
        const JoybitCompanion(
          compact: true,
          message: 'Pick one movement. We will measure what feels good today.',
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
                label: 'Head',
                description: 'Tilt left or right',
                icon: Icons.face_rounded,
                accent: ArcadeColors.arcadeYellow,
                onTap: () => onSelected(CalibrationMovementType.headTilt),
              ),
            ),
            SizedBox(
              width: width,
              child: _MovementTile(
                key: const Key('movement-wrist'),
                label: 'Hand / Wrist',
                description: 'Bend your wrist',
                icon: Icons.pan_tool_alt_rounded,
                accent: ArcadeColors.softPink,
                onTap: () => onSelected(CalibrationMovementType.wristBend),
              ),
            ),
            SizedBox(
              width: width,
              child: _MovementTile(
                key: const Key('movement-finger'),
                label: 'Finger',
                description: 'Bend your index finger',
                icon: Icons.touch_app_rounded,
                accent: ArcadeColors.electricCyan,
                onTap: () =>
                    onSelected(CalibrationMovementType.indexFingerBend),
              ),
            ),
            SizedBox(
              width: width,
              child: const _MovementTile(
                key: Key('movement-leg'),
                label: 'Leg',
                description: 'Planned for a later version',
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
    return Semantics(
      button: true,
      enabled: enabled,
      label: '$label. $description.',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ArcadeColors.background,
        border: Border.all(color: ArcadeColors.warmCream),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'COMING LATER',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ComfortNote extends StatelessWidget {
  const _ComfortNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ArcadeColors.deepViolet,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArcadeColors.royalPurple, width: 2),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.favorite_rounded, color: ArcadeColors.softPink),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Choose what is comfortable now. The next step measures your '
              'movement—it never asks you to stretch farther.',
            ),
          ),
        ],
      ),
    );
  }
}
