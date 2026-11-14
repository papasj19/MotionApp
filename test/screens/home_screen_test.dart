import 'package:adaptive_motion_arcade/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the Stage 1 home screen', (tester) async {
    await tester.pumpWidget(const AdaptiveMotionArcadeApp());

    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.text('Adaptive Motion Arcade'), findsOneWidget);
    expect(find.text('Move in your way. Play in your way.'), findsOneWidget);
    expect(find.text('Project setup complete'), findsOneWidget);
    expect(
      find.text('No camera data is being captured or stored.'),
      findsOneWidget,
    );
  });
}
