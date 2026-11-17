// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// The application name shown by Flutter.
  ///
  /// In en, this message translates to:
  /// **'Adaptive Motion Arcade'**
  String get appTitle;

  /// Tooltip for returning to the main arcade lobby.
  ///
  /// In en, this message translates to:
  /// **'Arcade lobby'**
  String get arcadeLobbyTooltip;

  /// Title of the quick-play setup screen.
  ///
  /// In en, this message translates to:
  /// **'Quick Play'**
  String get quickPlayTitle;

  /// First quick-play setup step. Preserve the meaning rather than the capitalization when translating.
  ///
  /// In en, this message translates to:
  /// **'STEP 1 • CHOOSE MOVEMENT'**
  String get quickPlayChooseMovementStep;

  /// Heading inviting the player to choose a comfortable movement.
  ///
  /// In en, this message translates to:
  /// **'What feels comfortable today?'**
  String get quickPlayComfortQuestion;

  /// Child-friendly companion guidance on the quick-play screen.
  ///
  /// In en, this message translates to:
  /// **'Pick one movement. We will measure what feels good today.'**
  String get quickPlayCompanionPrompt;

  /// Label for head movement control.
  ///
  /// In en, this message translates to:
  /// **'Head'**
  String get movementHeadLabel;

  /// Short description of the supported head movement.
  ///
  /// In en, this message translates to:
  /// **'Tilt left or right'**
  String get movementHeadDescription;

  /// Label for wrist movement control.
  ///
  /// In en, this message translates to:
  /// **'Hand / Wrist'**
  String get movementWristLabel;

  /// Short description of the supported wrist movement.
  ///
  /// In en, this message translates to:
  /// **'Bend your wrist'**
  String get movementWristDescription;

  /// Label for index-finger movement control.
  ///
  /// In en, this message translates to:
  /// **'Finger'**
  String get movementFingerLabel;

  /// Short description of the supported finger movement.
  ///
  /// In en, this message translates to:
  /// **'Bend your index finger'**
  String get movementFingerDescription;

  /// Label for a future leg movement control.
  ///
  /// In en, this message translates to:
  /// **'Leg'**
  String get movementLegLabel;

  /// Explanation that leg movement is not available yet.
  ///
  /// In en, this message translates to:
  /// **'Planned for a later version'**
  String get movementLegDescription;

  /// Screen-reader description for a movement choice.
  ///
  /// In en, this message translates to:
  /// **'{label}. {description}.'**
  String movementTileSemantics(String label, String description);

  /// Badge for a feature that is not available yet. Preserve the meaning rather than the capitalization when translating.
  ///
  /// In en, this message translates to:
  /// **'COMING LATER'**
  String get comingLater;

  /// Safety guidance that calibration uses comfortable movement rather than maximum range.
  ///
  /// In en, this message translates to:
  /// **'Choose what is comfortable now. The next step measures your movement—it never asks you to stretch farther.'**
  String get quickPlayComfortNote;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
