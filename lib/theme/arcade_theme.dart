import 'package:material_ui/material_ui.dart';

abstract final class ArcadeColors {
  static const background = Color(0xFF17102F);
  static const deepViolet = Color(0xFF24134F);
  static const royalPurple = Color(0xFF6E2CC8);
  static const lavender = Color(0xFFB05AE8);
  static const softPink = Color(0xFFF486B9);
  static const electricCyan = Color(0xFF43DCEB);
  static const warmCream = Color(0xFFFFE8CB);
  static const arcadeYellow = Color(0xFFFFD15A);
}

ThemeData buildArcadeTheme() {
  const colorScheme = ColorScheme.dark(
    primary: ArcadeColors.electricCyan,
    onPrimary: ArcadeColors.background,
    secondary: ArcadeColors.softPink,
    onSecondary: ArcadeColors.background,
    tertiary: ArcadeColors.arcadeYellow,
    onTertiary: ArcadeColors.background,
    surface: ArcadeColors.deepViolet,
    onSurface: ArcadeColors.warmCream,
    error: Color(0xFFFF8A8A),
    onError: ArcadeColors.background,
  );

  final base = ThemeData(colorScheme: colorScheme, useMaterial3: true);
  final textTheme = base.textTheme.apply(
    bodyColor: ArcadeColors.warmCream,
    displayColor: ArcadeColors.warmCream,
  );

  return base.copyWith(
    scaffoldBackgroundColor: ArcadeColors.background,
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: ArcadeColors.background,
      foregroundColor: ArcadeColors.warmCream,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: ArcadeColors.warmCream,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: ArcadeColors.deepViolet,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: ArcadeColors.royalPurple, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ArcadeColors.electricCyan,
        foregroundColor: ArcadeColors.background,
        disabledBackgroundColor: ArcadeColors.royalPurple.withValues(
          alpha: 0.45,
        ),
        disabledForegroundColor: ArcadeColors.warmCream.withValues(alpha: 0.6),
        minimumSize: const Size(64, 56),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ArcadeColors.electricCyan,
        minimumSize: const Size(64, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        side: const BorderSide(color: ArcadeColors.electricCyan, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ArcadeColors.electricCyan,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: ArcadeColors.electricCyan,
      inactiveTrackColor: ArcadeColors.royalPurple,
      thumbColor: ArcadeColors.arcadeYellow,
      overlayColor: ArcadeColors.electricCyan.withValues(alpha: 0.18),
    ),
    iconTheme: const IconThemeData(color: ArcadeColors.electricCyan),
    dividerColor: ArcadeColors.royalPurple,
    focusColor: ArcadeColors.arcadeYellow.withValues(alpha: 0.32),
  );
}
