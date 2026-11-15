enum Handedness { left, right, unknown }

class HandLandmark {
  const HandLandmark({
    required this.x,
    required this.y,
    required this.z,
    this.visibility,
    this.presence,
  });

  final double x;
  final double y;
  final double z;
  final double? visibility;
  final double? presence;
}

class HandObservation {
  HandObservation({
    required this.timestamp,
    required List<HandLandmark> landmarks,
    required this.imageWidth,
    required this.imageHeight,
    required this.rotationDegrees,
    required this.isMirrored,
    required this.handedness,
    this.handednessConfidence,
  }) : landmarks = List.unmodifiable(landmarks) {
    if (landmarks.length != 21) {
      throw ArgumentError.value(
        landmarks.length,
        'landmarks',
        'A hand observation must contain exactly 21 landmarks.',
      );
    }
    if (imageWidth <= 0 || imageHeight <= 0) {
      throw ArgumentError('Image dimensions must be positive.');
    }
    if (rotationDegrees != 0 &&
        rotationDegrees != 90 &&
        rotationDegrees != 180 &&
        rotationDegrees != 270) {
      throw ArgumentError.value(
        rotationDegrees,
        'rotationDegrees',
        'Rotation must be 0, 90, 180, or 270.',
      );
    }
  }

  final Duration timestamp;
  final List<HandLandmark> landmarks;
  final int imageWidth;
  final int imageHeight;
  final int rotationDegrees;
  final bool isMirrored;
  final Handedness handedness;
  final double? handednessConfidence;
}
