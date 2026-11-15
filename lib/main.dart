import 'package:material_ui/material_ui.dart';

import 'screens/home_screen.dart';
import 'theme/arcade_theme.dart';

void main() {
  runApp(const AdaptiveMotionArcadeApp());
}

class AdaptiveMotionArcadeApp extends StatelessWidget {
  const AdaptiveMotionArcadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adaptive Motion Arcade',
      debugShowCheckedModeBanner: false,
      theme: buildArcadeTheme(),
      home: const HomeScreen(),
    );
  }
}
