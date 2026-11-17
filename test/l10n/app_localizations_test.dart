import 'package:adaptive_motion_arcade/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English is the source locale for the localization foundation',
      () async {
    expect(AppLocalizations.supportedLocales, const <Locale>[Locale('en')]);

    final localizations = await AppLocalizations.delegate.load(
      const Locale('en'),
    );

    expect(localizations.appTitle, 'Adaptive Motion Arcade');
    expect(localizations.quickPlayTitle, 'Quick Play');
    expect(
      localizations.movementTileSemantics(
        localizations.movementHeadLabel,
        localizations.movementHeadDescription,
      ),
      'Head. Tilt left or right.',
    );
  });
}
