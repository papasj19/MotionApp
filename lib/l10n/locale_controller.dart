import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract interface class LanguagePreferenceStore {
  Future<String?> readLanguageCode();

  Future<void> writeLanguageCode(String languageCode);
}

class SharedPreferencesLanguagePreferenceStore
    implements LanguagePreferenceStore {
  SharedPreferencesLanguagePreferenceStore(
      {SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _languageCodeKey = 'preferred_language_code';

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> readLanguageCode() {
    return _preferences.getString(_languageCodeKey);
  }

  @override
  Future<void> writeLanguageCode(String languageCode) {
    return _preferences.setString(_languageCodeKey, languageCode);
  }
}

class LocaleController extends ChangeNotifier {
  LocaleController({required this.preferenceStore});

  static const supportedLanguageCodes = <String>{'en', 'es'};

  final LanguagePreferenceStore preferenceStore;
  Locale? _locale;

  /// A null locale means the app follows the supported device language.
  Locale? get locale => _locale;

  Future<void> load() async {
    final languageCode = await preferenceStore.readLanguageCode();
    if (languageCode != null &&
        supportedLanguageCodes.contains(languageCode) &&
        _locale?.languageCode != languageCode) {
      _locale = Locale(languageCode);
      notifyListeners();
    }
  }

  Future<void> selectLocale(Locale locale) async {
    final languageCode = locale.languageCode;
    if (!supportedLanguageCodes.contains(languageCode)) {
      throw ArgumentError.value(
        languageCode,
        'locale',
        'Only English and Spanish are supported.',
      );
    }
    if (_locale?.languageCode == languageCode) {
      return;
    }
    _locale = Locale(languageCode);
    notifyListeners();
    await preferenceStore.writeLanguageCode(languageCode);
  }
}

class LocaleControllerScope extends InheritedNotifier<LocaleController> {
  const LocaleControllerScope({
    required LocaleController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<LocaleControllerScope>();
    assert(scope != null, 'No LocaleControllerScope found in this context.');
    return scope!.notifier!;
  }
}
