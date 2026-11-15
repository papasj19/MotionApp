import 'package:material_ui/material_ui.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const AdaptiveMotionArcadeApp());
}

class AdaptiveMotionArcadeApp extends StatelessWidget {
  const AdaptiveMotionArcadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF176B68);

    return MaterialApp(
      title: 'Adaptive Motion Arcade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
