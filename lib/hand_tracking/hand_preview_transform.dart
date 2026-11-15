import 'package:flutter/painting.dart';

import 'hand_observation.dart';

class HandPreviewTransform {
  const HandPreviewTransform._();

  static Offset rotateNormalized(Offset point, int rotationDegrees) {
    return switch (rotationDegrees) {
      0 => point,
      90 => Offset(1 - point.dy, point.dx),
      180 => Offset(1 - point.dx, 1 - point.dy),
      270 => Offset(point.dy, 1 - point.dx),
      _ => throw ArgumentError.value(
        rotationDegrees,
        'rotationDegrees',
        'Rotation must be 0, 90, 180, or 270.',
      ),
    };
  }

  static Size orientedImageSize(HandObservation observation) {
    if (observation.rotationDegrees == 90 ||
        observation.rotationDegrees == 270) {
      return Size(
        observation.imageHeight.toDouble(),
        observation.imageWidth.toDouble(),
      );
    }
    return Size(
      observation.imageWidth.toDouble(),
      observation.imageHeight.toDouble(),
    );
  }

  static Offset mapLandmark({
    required HandLandmark landmark,
    required HandObservation observation,
    required Size viewportSize,
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.center,
  }) {
    var point = rotateNormalized(
      Offset(landmark.x, landmark.y),
      observation.rotationDegrees,
    );
    if (observation.isMirrored) {
      point = Offset(1 - point.dx, point.dy);
    }

    final imageSize = orientedImageSize(observation);
    final fitted = applyBoxFit(fit, imageSize, viewportSize);
    final sourceRect = alignment.inscribe(
      fitted.source,
      Offset.zero & imageSize,
    );
    final destinationRect = alignment.inscribe(
      fitted.destination,
      Offset.zero & viewportSize,
    );
    final imagePoint = Offset(
      point.dx * imageSize.width,
      point.dy * imageSize.height,
    );

    return Offset(
      destinationRect.left +
          (imagePoint.dx - sourceRect.left) *
              destinationRect.width /
              sourceRect.width,
      destinationRect.top +
          (imagePoint.dy - sourceRect.top) *
              destinationRect.height /
              sourceRect.height,
    );
  }
}
