import 'package:adaptive_motion_arcade/screens/home_screen.dart';
import 'package:adaptive_motion_arcade/screens/quick_play_screen.dart';
import 'package:adaptive_motion_arcade/l10n/locale_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../test_support/localized_test_app.dart';

void main() {
  testWidgets('shows the responsive arcade lobby', (tester) async {
    await tester.pumpWidget(
      localizedTestApp(home: const HomeScreen()),
    );

    expect(find.text('ADAPTIVE MOTION'), findsOneWidget);
    expect(find.text('ARCADE'), findsOneWidget);
    expect(find.text('Quick Play'), findsOneWidget);
    expect(find.text('Play without a profile'), findsOneWidget);
    expect(find.text('School'), findsOneWidget);
    expect(find.text('Planned after teacher feedback'), findsOneWidget);
    expect(find.text('Start comfortable calibration'), findsNothing);
  });

  testWidgets('opens Quick Play and then the selected camera route', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(
        home: HomeScreen(
          cameraScreenBuilder: (_) =>
              const Scaffold(body: Text('Injected camera screen')),
        ),
      ),
    );

    await tester.tap(find.text('Quick Play'));
    await tester.pumpAndSettle();

    expect(find.byType(QuickPlayScreen), findsOneWidget);
    expect(find.text('What feels comfortable today?'), findsOneWidget);

    await tester.ensureVisible(find.text('Finger'));
    await tester.tap(find.text('Finger'));
    await tester.pumpAndSettle();

    expect(find.text('Injected camera screen'), findsOneWidget);
  });

  testWidgets('keeps School unavailable until teacher interviews', (
    tester,
  ) async {
    await tester.pumpWidget(
      localizedTestApp(home: const HomeScreen()),
    );

    await tester.tap(find.byKey(const Key('school-button')));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Planned after teacher feedback'), findsOneWidget);
  });

  testWidgets('switches between English and Spanish and remembers the choice', (
    tester,
  ) async {
    final store = MemoryLanguagePreferenceStore();
    final controller = LocaleController(preferenceStore: store);
    await tester.pumpWidget(
      localizedTestApp(
        home: const HomeScreen(),
        localeController: controller,
      ),
    );

    expect(find.text('Quick Play'), findsOneWidget);
    await tester.tap(find.text('Español'));
    await tester.pumpAndSettle();

    expect(find.text('Juego rápido'), findsOneWidget);
    expect(find.text('Escuela'), findsOneWidget);
    expect(store.languageCode, 'es');

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Quick Play'), findsOneWidget);
    expect(store.languageCode, 'en');
  });

  testWidgets('lobby fits a compact landscape phone', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(640, 360);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      localizedTestApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.8)),
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Quick Play'), findsOneWidget);
    expect(find.text('School'), findsOneWidget);
  });
}
