import 'package:material_ui/material_ui.dart';

import 'l10n/app_localizations.dart';
import 'l10n/locale_controller.dart';
import 'screens/home_screen.dart';
import 'theme/arcade_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final localeController = LocaleController(
    preferenceStore: SharedPreferencesLanguagePreferenceStore(),
  );
  await localeController.load();
  runApp(AdaptiveMotionArcadeApp(localeController: localeController));
}

class AdaptiveMotionArcadeApp extends StatelessWidget {
  const AdaptiveMotionArcadeApp({required this.localeController, super.key});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return LocaleControllerScope(
      controller: localeController,
      child: AnimatedBuilder(
        animation: localeController,
        builder: (context, _) => MaterialApp(
          locale: localeController.locale,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          localizationsDelegates: [
            AppLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          theme: buildArcadeTheme(),
          home: const HomeScreen(),
        ),
      ),
    );
  }
}
