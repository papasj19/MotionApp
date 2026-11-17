import 'package:adaptive_motion_arcade/l10n/app_localizations.dart';
import 'package:adaptive_motion_arcade/l10n/locale_controller.dart';
import 'package:adaptive_motion_arcade/theme/arcade_theme.dart';
import 'package:material_ui/material_ui.dart';

class MemoryLanguagePreferenceStore implements LanguagePreferenceStore {
  MemoryLanguagePreferenceStore({this.languageCode});

  String? languageCode;

  @override
  Future<String?> readLanguageCode() async => languageCode;

  @override
  Future<void> writeLanguageCode(String languageCode) async {
    this.languageCode = languageCode;
  }
}

Widget localizedTestApp({
  required Widget home,
  Locale locale = const Locale('en'),
  LocaleController? localeController,
  TransitionBuilder? builder,
}) {
  final controller = localeController ??
      LocaleController(preferenceStore: MemoryLanguagePreferenceStore());
  return LocaleControllerScope(
    controller: controller,
    child: AnimatedBuilder(
      animation: controller,
      builder: (context, _) => MaterialApp(
        locale: controller.locale ?? locale,
        localizationsDelegates: [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: buildArcadeTheme(),
        builder: builder,
        home: home,
      ),
    ),
  );
}
