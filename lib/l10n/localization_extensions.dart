import 'package:intl/intl.dart' as intl;

import '../calibration/baseline_calibration.dart';
import '../calibration/calibration_profile.dart';
import '../calibration/comfortable_movement_calibration.dart';
import '../input_controller/motion_input_controller.dart';
import 'app_localizations.dart';

extension AdaptiveMotionLocalizations on AppLocalizations {
  String formatNumber(double value, {int decimalDigits = 1}) {
    final formatter = intl.NumberFormat.decimalPattern(localeName)
      ..minimumFractionDigits = decimalDigits
      ..maximumFractionDigits = decimalDigits;
    return formatter.format(value);
  }

  String movementLabelFor(CalibrationMovementType movementType) {
    return movementShortLabel(_movementToken(movementType));
  }

  String movementSelectionDescriptionFor(
    CalibrationMovementType movementType,
  ) {
    return movementSelectionDescription(_movementToken(movementType));
  }

  String movementPositioningHintFor(CalibrationMovementType movementType) {
    return movementPositioningHint(_movementToken(movementType));
  }

  String movementRestPromptFor(CalibrationMovementType movementType) {
    return movementRestPrompt(_movementToken(movementType));
  }

  String movementPromptFor(CalibrationMovementType movementType) {
    return movementPrompt(_movementToken(movementType));
  }

  String movementIncreasingDirectionFor(
    CalibrationMovementType movementType,
  ) {
    return movementIncreasingDirection(_movementToken(movementType));
  }

  String movementDecreasingDirectionFor(
    CalibrationMovementType movementType,
  ) {
    return movementDecreasingDirection(_movementToken(movementType));
  }

  String movementTrackingSubjectFor(CalibrationMovementType movementType) {
    return movementTrackingSubject(_movementToken(movementType));
  }

  String movementReadyInstructionFor(CalibrationMovementType movementType) {
    return movementReadyInstruction(_movementToken(movementType));
  }

  String baselineAssessmentMessage(
    CalibrationMovementType movementType,
    BaselineCalibrationAssessment? assessment,
  ) {
    if (assessment == null) {
      return movementRestPromptFor(movementType);
    }
    return switch (assessment.status) {
      BaselineCalibrationStatus.collecting =>
        movementRestPromptFor(movementType),
      BaselineCalibrationStatus.ready => restSignalStable,
      BaselineCalibrationStatus.trackingUnavailable => baselineTrackingPaused(
          movementPositioningHintFor(movementType),
        ),
      BaselineCalibrationStatus.signalTooVariable => restSignalTooVariable,
      BaselineCalibrationStatus.outOfOrderSample => delayedTrackingSample,
    };
  }

  String comfortableMovementAssessmentMessage(
    CalibrationMovementType movementType,
    ComfortableMovementAssessment? assessment,
  ) {
    if (assessment == null) {
      return movementPromptSafety(movementPromptFor(movementType));
    }
    return switch (assessment.status) {
      ComfortableMovementStatus.collecting =>
        movementPromptSafety(movementPromptFor(movementType)),
      ComfortableMovementStatus.recommendationReady =>
        movementRecommendationReady,
      ComfortableMovementStatus.movementNotSeparatedFromNoise =>
        movementNotSeparated,
      ComfortableMovementStatus.trackingUnavailable => baselineTrackingPaused(
          movementPositioningHintFor(movementType),
        ),
      ComfortableMovementStatus.outOfOrderSample => delayedTrackingSample,
    };
  }

  String calibrationValidationMessage(
    CalibrationValidationStatus status, {
    required double noiseFloorDegrees,
  }) {
    return switch (status) {
      CalibrationValidationStatus.valid => validationReliable,
      CalibrationValidationStatus.invalidNumber => validationChooseSensitivity,
      CalibrationValidationStatus.belowNoiseFloor => validationBelowNoise(
          formatNumber(noiseFloorDegrees),
        ),
      CalibrationValidationStatus.beyondObservedComfort =>
        validationBeyondComfort,
      CalibrationValidationStatus.outsideSignalRange => validationOutsideRange,
    };
  }

  String motionEventLabelFor(MotionInputEventType eventType) {
    return motionEventLabel(eventType.name);
  }
}

String _movementToken(CalibrationMovementType movementType) {
  return switch (movementType) {
    CalibrationMovementType.indexFingerBend => 'finger',
    CalibrationMovementType.wristBend => 'wrist',
    CalibrationMovementType.headTilt => 'head',
  };
}
