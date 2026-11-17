import 'package:adaptive_motion_arcade/l10n/locale_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_support/localized_test_app.dart';

void main() {
  test('uses the device language until a preference is selected', () async {
    final store = MemoryLanguagePreferenceStore();
    final controller = LocaleController(preferenceStore: store);

    await controller.load();

    expect(controller.locale, isNull);
  });

  test('loads and persists a supported language selection', () async {
    final store = MemoryLanguagePreferenceStore(languageCode: 'es');
    final controller = LocaleController(preferenceStore: store);

    await controller.load();
    expect(controller.locale, const Locale('es'));

    await controller.selectLocale(const Locale('en'));
    expect(controller.locale, const Locale('en'));
    expect(store.languageCode, 'en');
  });

  test('ignores an unsupported saved language and rejects selection', () async {
    final store = MemoryLanguagePreferenceStore(languageCode: 'fr');
    final controller = LocaleController(preferenceStore: store);

    await controller.load();
    expect(controller.locale, isNull);

    await expectLater(
      controller.selectLocale(const Locale('fr')),
      throwsArgumentError,
    );
  });
}
