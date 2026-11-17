import 'package:material_ui/material_ui.dart';

import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'theme/arcade_theme.dart';

void main() {
  runApp(const AdaptiveMotionArcadeApp());
}

class AdaptiveMotionArcadeApp extends StatelessWidget {
  const AdaptiveMotionArcadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      theme: buildArcadeTheme(),
      home: const HomeScreen(),
    );
  }
}
