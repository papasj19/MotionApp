import 'package:material_ui/material_ui.dart';

import '../theme/arcade_theme.dart';

class JoybitCompanion extends StatelessWidget {
  const JoybitCompanion({
    required this.message,
    this.compact = false,
    super.key,
  });

  static const assetPath = 'assets/arcade/joybit_welcome.png';

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final portrait = _JoybitPortrait(size: compact ? 92 : 210);
    final messageBubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ArcadeColors.deepViolet,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ArcadeColors.lavender, width: 2),
      ),
      child: Text(
        message,
        textAlign: compact ? TextAlign.left : TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    );

    if (compact) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          portrait,
          const SizedBox(width: 12),
          Expanded(child: messageBubble),
        ],
      );
    }

    return Column(
      children: [portrait, const SizedBox(height: 12), messageBubble],
    );
  }
}

class _JoybitPortrait extends StatelessWidget {
  const _JoybitPortrait({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Joybit, a friendly lavender hedgehog wearing arcade headphones.',
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: ArcadeColors.electricCyan, width: 3),
            boxShadow: const [
              BoxShadow(
                color: ArcadeColors.royalPurple,
                blurRadius: 0,
                spreadRadius: 4,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            JoybitCompanion.assetPath,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: ArcadeColors.deepViolet,
              child: Icon(
                Icons.star,
                color: ArcadeColors.arcadeYellow,
                size: 52,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
