import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../theme/arcade_theme.dart';
import '../widgets/joybit_companion.dart';
import '../widgets/language_switcher.dart';
import 'quick_play_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.cameraScreenBuilder,
    this.quickPlayScreenBuilder,
  });

  final WidgetBuilder? cameraScreenBuilder;
  final WidgetBuilder? quickPlayScreenBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxHeight < 650 || constraints.maxWidth < 430;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? 16 : 24,
                      compact ? 12 : 20,
                      compact ? 16 : 24,
                      compact ? 12 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: LanguageSwitcher(),
                        ),
                        SizedBox(height: compact ? 8 : 12),
                        const _LobbyHeading(),
                        SizedBox(height: compact ? 8 : 16),
                        Expanded(child: _ArcadeScene(compact: compact)),
                        SizedBox(height: compact ? 10 : 18),
                        _LobbyActions(
                          compact: compact,
                          onQuickPlay: () => _openQuickPlay(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openQuickPlay(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: quickPlayScreenBuilder ??
            (_) => QuickPlayScreen(cameraScreenBuilder: cameraScreenBuilder),
      ),
    );
  }
}

class _LobbyHeading extends StatelessWidget {
  const _LobbyHeading();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Semantics(
      header: true,
      child: Column(
        children: [
          Text(
            localizations.homeTitleLineOne,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: ArcadeColors.electricCyan,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            localizations.homeTitleLineTwo,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: ArcadeColors.arcadeYellow,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
          ),
        ],
      ),
    );
  }
}

class _ArcadeScene extends StatelessWidget {
  const _ArcadeScene({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: ExcludeSemantics(
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _CabinetColumn(compact: compact, mirror: false),
                    _CabinetColumn(compact: compact, mirror: true),
                  ],
                ),
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compact ? 360 : 430),
          child: JoybitCompanion(
            compact: compact,
            message: compact
                ? localizations.homeCompactWelcome
                : localizations.homeWelcome,
          ),
        ),
      ],
    );
  }
}

class _CabinetColumn extends StatelessWidget {
  const _CabinetColumn({required this.compact, required this.mirror});

  final bool compact;
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    final cabinets = compact ? 2 : 3;
    final colors = mirror
        ? const [
            ArcadeColors.softPink,
            ArcadeColors.electricCyan,
            ArcadeColors.arcadeYellow,
          ]
        : const [
            ArcadeColors.electricCyan,
            ArcadeColors.arcadeYellow,
            ArcadeColors.softPink,
          ];
    return SizedBox(
      width: compact ? 52 : 92,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cabinetHeight = compact ? 62.0 : 96.0;
          final visibleCabinets =
              (constraints.maxHeight ~/ cabinetHeight).clamp(0, cabinets);
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (var index = 0; index < visibleCabinets; index++)
                _ArcadeCabinet(
                  accent: colors[index],
                  compact: compact,
                  mirror: mirror,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ArcadeCabinet extends StatelessWidget {
  const _ArcadeCabinet({
    required this.accent,
    required this.compact,
    required this.mirror,
  });

  final Color accent;
  final bool compact;
  final bool mirror;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 42.0 : 70.0;
    final height = compact ? 62.0 : 96.0;
    return Transform.flip(
      flipX: mirror,
      child: Container(
        width: width,
        height: height,
        padding: EdgeInsets.all(compact ? 5 : 8),
        decoration: BoxDecoration(
          color: ArcadeColors.deepViolet,
          border: Border.all(color: accent, width: compact ? 2 : 3),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(3),
            bottomLeft: Radius.circular(3),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: ArcadeColors.background,
                  border: Border.all(color: accent),
                ),
                child: Center(
                  child: Icon(
                    Icons.star_rounded,
                    color: accent,
                    size: compact ? 14 : 22,
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 4 : 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: compact ? 5 : 8,
                  height: compact ? 5 : 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: compact ? 4 : 7),
                Container(
                  width: compact ? 10 : 17,
                  height: compact ? 3 : 5,
                  color: ArcadeColors.warmCream,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LobbyActions extends StatelessWidget {
  const _LobbyActions({required this.compact, required this.onQuickPlay});

  final bool compact;
  final VoidCallback onQuickPlay;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _LobbyModeButton(
                  key: const Key('quick-play-button'),
                  label: localizations.homeQuickPlay,
                  supportingText: localizations.homeQuickPlayDescription,
                  icon: Icons.home_rounded,
                  accent: ArcadeColors.electricCyan,
                  compact: compact,
                  onTap: onQuickPlay,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _LobbyModeButton(
                  key: const Key('school-button'),
                  label: localizations.homeSchool,
                  supportingText: localizations.homeSchoolDescription,
                  icon: Icons.school_rounded,
                  accent: ArcadeColors.softPink,
                  compact: compact,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LobbyModeButton extends StatelessWidget {
  const _LobbyModeButton({
    required this.label,
    required this.supportingText,
    required this.icon,
    required this.accent,
    required this.compact,
    this.onTap,
    super.key,
  });

  final String label;
  final String supportingText;
  final IconData icon;
  final Color accent;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final localizations = AppLocalizations.of(context);
    return Semantics(
      button: true,
      enabled: enabled,
      label: localizations.optionSemantics(label, supportingText),
      child: Opacity(
        opacity: enabled ? 1 : 0.72,
        child: Material(
          color: ArcadeColors.deepViolet,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: accent, width: 3),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 18,
                vertical: compact ? 10 : 16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: compact ? 28 : 36, color: accent),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    supportingText,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
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
