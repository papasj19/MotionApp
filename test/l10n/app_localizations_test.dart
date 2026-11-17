import 'package:adaptive_motion_arcade/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('English and Spanish catalogs expose the same core interface', () async {
    expect(
      AppLocalizations.supportedLocales,
      const <Locale>[Locale('en'), Locale('es')],
    );

    final english = await AppLocalizations.delegate.load(
      const Locale('en'),
    );
    final spanish = await AppLocalizations.delegate.load(
      const Locale('es'),
    );

    expect(english.appTitle, 'Adaptive Motion Arcade');
    expect(english.quickPlayTitle, 'Quick Play');
    expect(spanish.appTitle, 'Adaptive Motion Arcade');
    expect(spanish.quickPlayTitle, 'Juego rápido');
    expect(
      english.movementTileSemantics(
        english.movementHeadLabel,
        english.movementHeadDescription,
      ),
      'Head. Tilt left or right.',
    );
    expect(
      spanish.movementTileSemantics(
        spanish.movementHeadLabel,
        spanish.movementHeadDescription,
      ),
      'Cabeza. Inclínala a la izquierda o a la derecha.',
    );
  });
}
