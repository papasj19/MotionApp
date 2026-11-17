import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_controller.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final controller = LocaleControllerScope.of(context);
    final activeLanguageCode = Localizations.localeOf(context).languageCode;
    final selectedCode = activeLanguageCode == 'es' ? 'es' : 'en';

    return Semantics(
      container: true,
      label: localizations.languageSelectionLabel,
      child: SegmentedButton<String>(
        key: const Key('language-switcher'),
        showSelectedIcon: false,
        segments: [
          ButtonSegment<String>(
            value: 'en',
            label: Text(localizations.languageEnglish),
          ),
          ButtonSegment<String>(
            value: 'es',
            label: Text(localizations.languageSpanish),
          ),
        ],
        selected: {selectedCode},
        onSelectionChanged: (selection) {
          unawaited(controller.selectLocale(Locale(selection.single)));
        },
      ),
    );
  }
}
