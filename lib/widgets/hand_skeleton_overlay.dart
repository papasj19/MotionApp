import 'package:material_ui/material_ui.dart';

import '../hand_tracking/hand_observation.dart';
import '../hand_tracking/hand_preview_transform.dart';

class HandSkeletonOverlay extends StatelessWidget {
  const HandSkeletonOverlay({required this.observation, super.key});

  final HandObservation observation;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: CustomPaint(
          painter: HandSkeletonPainter(observation),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class HandSkeletonPainter extends CustomPainter {
  HandSkeletonPainter(this.observation);

  static const connections = <(int, int)>[
    (0, 1),
    (1, 2),
    (2, 3),
    (3, 4),
    (0, 5),
    (5, 6),
    (6, 7),
    (7, 8),
    (5, 9),
    (9, 10),
    (10, 11),
    (11, 12),
    (9, 13),
    (13, 14),
    (14, 15),
    (15, 16),
    (13, 17),
    (17, 18),
    (18, 19),
    (19, 20),
    (0, 17),
  ];

  final HandObservation observation;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final points = observation.landmarks
        .map(
          (landmark) => HandPreviewTransform.mapLandmark(
            landmark: landmark,
            observation: observation,
            viewportSize: size,
          ),
        )
        .toList(growable: false);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.8)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    final linePaint = Paint()
      ..color = const Color(0xFF63FFF1)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    for (final (start, end) in connections) {
      canvas.drawLine(points[start], points[end], shadowPaint);
      canvas.drawLine(points[start], points[end], linePaint);
    }

    final pointOutlinePaint = Paint()..color = Colors.black;
    final pointPaint = Paint()..color = Colors.white;
    for (final point in points) {
      canvas.drawCircle(point, 6, pointOutlinePaint);
      canvas.drawCircle(point, 3.5, pointPaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HandSkeletonPainter oldDelegate) {
    return !identical(oldDelegate.observation, observation);
  }
}
