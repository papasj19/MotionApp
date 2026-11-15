enum CalibrationMovementType { indexFingerBend, wristBend, headTilt }

extension CalibrationMovementTypeDetails on CalibrationMovementType {
  String get shortLabel => switch (this) {
    CalibrationMovementType.indexFingerBend => 'Finger',
    CalibrationMovementType.wristBend => 'Wrist',
    CalibrationMovementType.headTilt => 'Head',
  };

  String get selectionDescription => switch (this) {
    CalibrationMovementType.indexFingerBend =>
      'Bend and straighten the index finger comfortably.',
    CalibrationMovementType.wristBend =>
      'Bend the wrist comfortably in either direction.',
    CalibrationMovementType.headTilt =>
      'Tilt the head comfortably left or right.',
  };

  String get positioningHint => switch (this) {
    CalibrationMovementType.indexFingerBend =>
      'Show one hand clearly, including the full index finger.',
    CalibrationMovementType.wristBend =>
      'Show one hand, the wrist, and the forearm up to the elbow.',
    CalibrationMovementType.headTilt =>
      'Center the face and keep both eyes visible.',
  };

  String get restPrompt => switch (this) {
    CalibrationMovementType.indexFingerBend =>
      'Keep the hand comfortably at rest while the baseline is measured.',
    CalibrationMovementType.wristBend =>
      'Keep the wrist comfortably at rest while the baseline is measured.',
    CalibrationMovementType.headTilt =>
      'Keep the head comfortably at rest while the baseline is measured.',
  };

  String get movementPrompt => switch (this) {
    CalibrationMovementType.indexFingerBend =>
      'Make one comfortable finger bend or straighten movement.',
    CalibrationMovementType.wristBend =>
      'Make one comfortable wrist bend in either direction.',
    CalibrationMovementType.headTilt =>
      'Make one comfortable head tilt to the left or right.',
  };

  String get increasingDirectionLabel => switch (this) {
    CalibrationMovementType.indexFingerBend => 'More bend',
    CalibrationMovementType.wristBend => 'More wrist bend',
    CalibrationMovementType.headTilt => 'Tilt left',
  };

  String get decreasingDirectionLabel => switch (this) {
    CalibrationMovementType.indexFingerBend => 'More straight',
    CalibrationMovementType.wristBend => 'More straight',
    CalibrationMovementType.headTilt => 'Tilt right',
  };

  double get minimumDegrees => switch (this) {
    CalibrationMovementType.indexFingerBend ||
    CalibrationMovementType.wristBend => 0,
    CalibrationMovementType.headTilt => -90,
  };

  double get maximumDegrees => switch (this) {
    CalibrationMovementType.indexFingerBend ||
    CalibrationMovementType.wristBend => 180,
    CalibrationMovementType.headTilt => 90,
  };

  String get trackingSubject => switch (this) {
    CalibrationMovementType.indexFingerBend ||
    CalibrationMovementType.wristBend => 'hand',
    CalibrationMovementType.headTilt => 'face',
  };
}

/// The calibration layer only needs a timestamped angle and whether it is
/// trustworthy enough to use. Camera- and MediaPipe-specific objects stay
/// behind this boundary.
abstract interface class MovementMeasurement {
  Duration get timestamp;

  bool get isValid;

  double? get valueDegrees;
}
