import 'package:adaptive_motion_arcade/hand_tracking/hand_observation.dart';
import 'package:adaptive_motion_arcade/hand_tracking/hand_preview_transform.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('front camera mirrors the horizontal overlay coordinate', () {
    final rear = _observation(width: 100, height: 100, mirrored: false);
    final front = _observation(width: 100, height: 100, mirrored: true);
    const landmark = HandLandmark(x: 0.2, y: 0.3, z: 0);

    final rearPoint = HandPreviewTransform.mapLandmark(
      landmark: landmark,
      observation: rear,
      viewportSize: const Size(100, 100),
    );
    final frontPoint = HandPreviewTransform.mapLandmark(
      landmark: landmark,
      observation: front,
      viewportSize: const Size(100, 100),
    );

    expect(rearPoint, const Offset(20, 30));
    expect(frontPoint, const Offset(80, 30));
  });

  test('clockwise rotation maps landmarks and swaps image dimensions', () {
    final observation = _observation(
      width: 200,
      height: 100,
      rotationDegrees: 90,
    );

    expect(
      HandPreviewTransform.orientedImageSize(observation),
      const Size(100, 200),
    );
    expect(
      HandPreviewTransform.mapLandmark(
        landmark: const HandLandmark(x: 0.2, y: 0.3, z: 0),
        observation: observation,
        viewportSize: const Size(100, 200),
      ),
      const Offset(70, 40),
    );
  });

  test('contain fit centers a wide image without stretching it', () {
    final observation = _observation(width: 400, height: 200);

    final topLeft = HandPreviewTransform.mapLandmark(
      landmark: const HandLandmark(x: 0, y: 0, z: 0),
      observation: observation,
      viewportSize: const Size(200, 200),
    );
    final center = HandPreviewTransform.mapLandmark(
      landmark: const HandLandmark(x: 0.5, y: 0.5, z: 0),
      observation: observation,
      viewportSize: const Size(200, 200),
    );

    expect(topLeft, const Offset(0, 50));
    expect(center, const Offset(100, 100));
  });

  test('cover fit maps through centered crop', () {
    final observation = _observation(width: 400, height: 200);

    final leftEdge = HandPreviewTransform.mapLandmark(
      landmark: const HandLandmark(x: 0, y: 0.5, z: 0),
      observation: observation,
      viewportSize: const Size(200, 200),
      fit: BoxFit.cover,
    );
    final center = HandPreviewTransform.mapLandmark(
      landmark: const HandLandmark(x: 0.5, y: 0.5, z: 0),
      observation: observation,
      viewportSize: const Size(200, 200),
      fit: BoxFit.cover,
    );

    expect(leftEdge, const Offset(-100, 100));
    expect(center, const Offset(100, 100));
  });
}

HandObservation _observation({
  required int width,
  required int height,
  int rotationDegrees = 0,
  bool mirrored = false,
}) {
  return HandObservation(
    timestamp: Duration.zero,
    landmarks: List.generate(
      21,
      (_) => const HandLandmark(x: 0.5, y: 0.5, z: 0),
    ),
    imageWidth: width,
    imageHeight: height,
    rotationDegrees: rotationDegrees,
    isMirrored: mirrored,
    handedness: Handedness.unknown,
  );
}
