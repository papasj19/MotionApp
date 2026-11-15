import 'package:material_ui/material_ui.dart';

import '../theme/arcade_theme.dart';
import '../widgets/joybit_companion.dart';
import 'camera_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.cameraScreenBuilder});

  final WidgetBuilder? cameraScreenBuilder;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Adaptive Motion Arcade'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const JoybitCompanion(
                    message:
                        'Hi, I’m Joybit. Let’s find a movement that feels good today.',
                  ),
                  const SizedBox(height: 28),
                  Semantics(
                    header: true,
                    child: Text(
                      'Move in your way. Play in your way.',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Adaptive Motion Arcade will turn comfortable finger, '
                    'wrist, or head movements into accessible game controls.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: ArcadeColors.arcadeYellow,
                            size: 30,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Comfortable calibration ready',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Measure a comfortable rest position and one '
                                  'comfortable finger, wrist, or head movement '
                                  'with caregiver guidance.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder:
                              cameraScreenBuilder ??
                              (_) => const CameraScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Start comfortable calibration'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Camera video stays in the live preview and is not saved.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
