// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Adaptive Motion Arcade';

  @override
  String get arcadeLobbyTooltip => 'Arcade lobby';

  @override
  String get quickPlayTitle => 'Quick Play';

  @override
  String get quickPlayChooseMovementStep => 'STEP 1 • CHOOSE MOVEMENT';

  @override
  String get quickPlayComfortQuestion => 'What feels comfortable today?';

  @override
  String get quickPlayCompanionPrompt =>
      'Pick one movement. We will measure what feels good today.';

  @override
  String get movementHeadLabel => 'Head';

  @override
  String get movementHeadDescription => 'Tilt left or right';

  @override
  String get movementWristLabel => 'Hand / Wrist';

  @override
  String get movementWristDescription => 'Bend your wrist';

  @override
  String get movementFingerLabel => 'Finger';

  @override
  String get movementFingerDescription => 'Bend your index finger';

  @override
  String get movementLegLabel => 'Leg';

  @override
  String get movementLegDescription => 'Planned for a later version';

  @override
  String movementTileSemantics(String label, String description) {
    return '$label. $description.';
  }

  @override
  String get comingLater => 'COMING LATER';

  @override
  String get quickPlayComfortNote =>
      'Choose what is comfortable now. The next step measures your movement—it never asks you to stretch farther.';
}
