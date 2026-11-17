// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Adaptive Motion Arcade';

  @override
  String get languageSelectionLabel => 'App language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get homeTitleLineOne => 'ADAPTIVE MOTION';

  @override
  String get homeTitleLineTwo => 'ARCADE';

  @override
  String get homeCompactWelcome => 'Ready to play your way?';

  @override
  String get homeWelcome => 'Welcome! Choose how you want to play today.';

  @override
  String get homeQuickPlay => 'Quick Play';

  @override
  String get homeQuickPlayDescription => 'Play without a profile';

  @override
  String get homeSchool => 'School';

  @override
  String get homeSchoolDescription => 'Planned after teacher feedback';

  @override
  String optionSemantics(String label, String description) {
    return '$label. $description.';
  }

  @override
  String get arcadeLobbyTooltip => 'Arcade lobby';

  @override
  String get quickPlayTitle => 'Quick Play';

  @override
  String get quickPlayChooseMovementStep => 'STEP 1 • CHOOSE MOVEMENT';

  @override
  String get quickPlayComfortQuestion => 'What feels comfortable today?';

  @override
  String get quickPlayCompanionPrompt =>
      'Pick one movement. We will measure what feels good today.';

  @override
  String get movementHeadLabel => 'Head';

  @override
  String get movementHeadDescription => 'Tilt left or right';

  @override
  String get movementWristLabel => 'Hand / Wrist';

  @override
  String get movementWristDescription => 'Bend your wrist';

  @override
  String get movementFingerLabel => 'Finger';

  @override
  String get movementFingerDescription => 'Bend your index finger';

  @override
  String get movementLegLabel => 'Leg';

  @override
  String get movementLegDescription => 'Planned for a later version';

  @override
  String movementTileSemantics(String label, String description) {
    return '$label. $description.';
  }

  @override
  String get comingLater => 'COMING LATER';

  @override
  String get quickPlayComfortNote =>
      'Choose what is comfortable now. The next step measures your movement—it never asks you to stretch farther.';

  @override
  String movementShortLabel(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'finger': 'Finger',
      'wrist': 'Wrist',
      'head': 'Head',
      'other': 'Movement',
    });
    return '$_temp0';
  }

  @override
  String movementSelectionDescription(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'finger': 'Bend and straighten the index finger comfortably.',
      'wrist': 'Bend the wrist comfortably in either direction.',
      'head': 'Tilt the head comfortably left or right.',
      'other': 'Move comfortably.',
    });
    return '$_temp0';
  }

  @override
  String movementPositioningHint(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'finger': 'Show one hand clearly, including the full index finger.',
      'wrist': 'Show one hand, the wrist, and the forearm up to the elbow.',
      'head': 'Center the face and keep both eyes visible.',
      'other': 'Move fully into view.',
    });
    return '$_temp0';
  }

  @override
  String movementRestPrompt(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'finger':
          'Keep the hand comfortably at rest while the baseline is measured.',
      'wrist':
          'Keep the wrist comfortably at rest while the baseline is measured.',
      'head':
          'Keep the head comfortably at rest while the baseline is measured.',
      'other': 'Rest comfortably while the baseline is measured.',
    });
    return '$_temp0';
  }

  @override
  String movementPrompt(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'finger': 'Make one comfortable finger bend or straighten movement.',
      'wrist': 'Make one comfortable wrist bend in either direction.',
      'head': 'Make one comfortable head tilt to the left or right.',
      'other': 'Make one comfortable movement.',
    });
    return '$_temp0';
  }

  @override
  String movementIncreasingDirection(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'finger': 'More bend',
      'wrist': 'More wrist bend',
      'head': 'Tilt left',
      'other': 'First direction',
    });
    return '$_temp0';
  }

  @override
  String movementDecreasingDirection(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'finger': 'More straight',
      'wrist': 'More straight',
      'head': 'Tilt right',
      'other': 'Other direction',
    });
    return '$_temp0';
  }

  @override
  String movementTrackingSubject(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'finger': 'hand',
      'wrist': 'hand',
      'head': 'face',
      'other': 'tracked area',
    });
    return '$_temp0';
  }

  @override
  String movementReadyInstruction(String movement) {
    String _temp0 = intl.Intl.selectLogic(movement, {
      'finger': 'Make one comfortable finger movement.',
      'wrist': 'Make one comfortable wrist movement.',
      'head': 'Make one comfortable head movement.',
      'other': 'Make one comfortable movement.',
    });
    return '$_temp0';
  }

  @override
  String calibrationScreenTitle(String movement) {
    return '$movement calibration';
  }

  @override
  String controlTestScreenTitle(String movement) {
    return '$movement control test';
  }

  @override
  String get changeMovement => 'Change';

  @override
  String get livePreviewPrivacy =>
      'Live preview only. Nothing is recorded or saved.';

  @override
  String get chooseMovementTitle => 'Choose a movement';

  @override
  String get chooseMovementQuestion =>
      'What comfortable movement will control the game?';

  @override
  String get chooseMovementHelp =>
      'A caregiver can choose the clearest option. Calibration measures the player’s current comfortable movement and never asks for a maximum range. Head control uses left/right tilt only; it does not use blinking or facial expressions.';

  @override
  String get preparingMovementTracking => 'Preparing movement tracking';

  @override
  String get trackingPaused => 'Tracking paused';

  @override
  String get startingTracking => 'Starting tracking…';

  @override
  String get trackingUnavailable => 'Tracking unavailable';

  @override
  String get movementTrackingPausedSemantics => 'Movement tracking paused.';

  @override
  String get movementTrackingStartingSemantics => 'Starting movement tracking.';

  @override
  String movementTrackingActiveSemantics(String movement) {
    return '$movement movement is being tracked.';
  }

  @override
  String get movementTrackingUnavailableSemantics =>
      'Movement tracking is unavailable.';

  @override
  String trackingDetected(String movement, int fps) {
    return '$movement detected • $fps FPS';
  }

  @override
  String trackingDetectedWithLatency(String movement, int fps, int latency) {
    return '$movement detected • $fps FPS • $latency ms';
  }

  @override
  String get cameraPreviewLoading => 'Camera preview loading';

  @override
  String get cameraPreviewUnavailable => 'Camera preview unavailable';

  @override
  String get cameraTitleStarting => 'Starting camera';

  @override
  String get cameraTitleReady => 'Camera ready';

  @override
  String get cameraTitleNoFrontCamera => 'Front camera unavailable';

  @override
  String get cameraTitlePermissionNeeded => 'Camera permission needed';

  @override
  String get cameraTitleAccessRestricted => 'Camera access restricted';

  @override
  String get cameraTitlePaused => 'Camera paused';

  @override
  String get cameraTitleUnavailable => 'Camera unavailable';

  @override
  String get cameraMessageStarting => 'Starting the front camera…';

  @override
  String get cameraMessageAdjustingOrientation =>
      'Adjusting camera orientation…';

  @override
  String get cameraMessageReady => 'The front camera preview is ready.';

  @override
  String get cameraMessageNoFrontCamera =>
      'No front-facing camera was found on this device.';

  @override
  String get cameraMessagePermissionDenied =>
      'Camera access was denied. Allow camera access in device settings, then try again.';

  @override
  String get cameraMessagePermissionRestricted =>
      'Camera access is restricted on this device.';

  @override
  String get cameraMessagePaused =>
      'Camera paused while the app is not active.';

  @override
  String get cameraMessageFailure =>
      'The camera could not start. Please try again.';

  @override
  String cameraStatusSemantics(String title, String message) {
    return 'Camera status. $title. $message';
  }

  @override
  String get tryAgain => 'Try again';

  @override
  String get calibrationTitle => 'Comfortable movement calibration';

  @override
  String get calibrationIntroduction =>
      'A caregiver can guide two short steps. Keep every movement comfortable—never push for a maximum range.';

  @override
  String selectedMovement(String movement) {
    return 'Selected movement: $movement.';
  }

  @override
  String get startRestMeasurement => 'Start rest measurement';

  @override
  String get calibrationStepOne => 'Step 1 of 2 • Rest comfortably';

  @override
  String stableSamples(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Stable samples: $count',
      one: 'Stable sample: 1',
      zero: 'Stable samples: 0',
    );
    return '$_temp0';
  }

  @override
  String get retryRestMeasurement => 'Retry rest measurement';

  @override
  String get restMeasurementComplete => 'Rest measurement complete';

  @override
  String restEstimateNext(String value, String prompt) {
    return 'Rest estimate: ~$value°. Next, $prompt';
  }

  @override
  String get measureComfortableMovement => 'Measure comfortable movement';

  @override
  String get calibrationStepTwo => 'Step 2 of 2 • Move comfortably';

  @override
  String movementPromptSafety(String prompt) {
    return '$prompt Do not push farther.';
  }

  @override
  String get retryMovement => 'Retry movement';

  @override
  String get reviewManualSetting => 'Review manual setting';

  @override
  String get manualThresholdUnavailable =>
      'A reliable manual threshold is not available because the movement overlaps the measured noise. Retrying is safest.';

  @override
  String get caregiverReview => 'Caregiver review';

  @override
  String get caregiverReviewInstructions =>
      'Choose the direction and sensitivity. The threshold cannot go below measured noise or beyond the observed comfortable movement.';

  @override
  String get movementDirection => 'Movement direction';

  @override
  String sensitivityFromRest(String value) {
    return 'Sensitivity: ~$value° from rest';
  }

  @override
  String measuredNoiseAndMovement(String noise, String movement) {
    return 'Measured noise floor: ~$noise°. Observed comfortable movement: ~$movement°.';
  }

  @override
  String get useThisSetting => 'Use this setting';

  @override
  String get calibrationReady => 'Calibration ready';

  @override
  String calibrationDirectionThreshold(String direction, String value) {
    return 'Direction: $direction. Threshold: ~$value° from rest.';
  }

  @override
  String get calibrationNotSaved =>
      'This calibration is not saved and clears when you leave this screen.';

  @override
  String get calibrationSuccessCompanion =>
      'Nice job! This setting stays within the movement measured today.';

  @override
  String get testThisControl => 'Test this control';

  @override
  String get calibrateAgain => 'Calibrate again';

  @override
  String get calibrationSemanticReady => 'Calibration ready to begin.';

  @override
  String get calibrationSemanticMeasuringRest =>
      'Measuring comfortable rest position.';

  @override
  String get calibrationSemanticRestComplete =>
      'Rest measurement complete. Comfortable movement is next.';

  @override
  String get calibrationSemanticMeasuringMovement =>
      'Measuring one comfortable movement.';

  @override
  String get calibrationSemanticReview =>
      'Calibration is ready for caregiver review.';

  @override
  String get calibrationSemanticComplete =>
      'Calibration complete. It is not saved.';

  @override
  String currentAngleSemantics(String movement, String value) {
    return 'Current estimated $movement angle $value';
  }

  @override
  String currentAngleUnavailableSemantics(String movement) {
    return 'Current $movement angle unavailable';
  }

  @override
  String baselineTrackingPaused(String hint) {
    return 'Tracking paused. $hint';
  }

  @override
  String get delayedTrackingSample => 'A delayed tracking sample was ignored.';

  @override
  String get restSignalTooVariable =>
      'The resting signal is too variable for an automatic setting. Try again or use a caregiver-adjusted setting.';

  @override
  String get restSignalStable =>
      'The resting signal is stable enough to continue.';

  @override
  String get movementNotSeparated =>
      'This comfortable movement was not clearly separated from normal signal variation. Retry or use a caregiver-adjusted setting.';

  @override
  String get movementRecommendationReady =>
      'A starting threshold is available for caregiver review. It does not require a larger movement.';

  @override
  String get validationChooseSensitivity =>
      'Choose a valid sensitivity setting.';

  @override
  String validationBelowNoise(String value) {
    return 'This setting is below the measured noise floor of $value°. Increase the threshold or retry calibration.';
  }

  @override
  String get validationBeyondComfort =>
      'This setting is beyond the comfortable movement that was observed. Lower the threshold or retry calibration.';

  @override
  String get validationOutsideRange =>
      'This direction and sensitivity are outside the measured signal range. Change the setting or retry calibration.';

  @override
  String get validationReliable =>
      'This setting is above noise and within observed comfort.';

  @override
  String get controlStatusTrackingPaused => 'TRACKING PAUSED';

  @override
  String get controlStatusActionPressed => 'ACTION PRESSED';

  @override
  String get controlStatusReturnToRest => 'RETURN TO REST';

  @override
  String get controlStatusReady => 'READY';

  @override
  String controlInstructionReposition(String subject) {
    return 'Reposition the $subject to continue.';
  }

  @override
  String get controlInstructionReturnComfortably =>
      'Return comfortably to rest before moving again.';

  @override
  String get controlInstructionWillArm =>
      'The control will arm after the movement returns to rest.';

  @override
  String controlTestSemantics(String status, int count, String instruction) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actions detected',
      one: 'One action detected',
      zero: 'No actions detected',
    );
    return 'Control test. $status. $_temp0. $instruction';
  }

  @override
  String get controlTestTitle => 'Control Test';

  @override
  String get controlTestDescription =>
      'One comfortable movement should create one action.';

  @override
  String get developerTestInput => 'Developer test input';

  @override
  String get testPress => 'Test press';

  @override
  String get testRelease => 'Test release';

  @override
  String get validationDetails => 'Validation details';

  @override
  String get caregiverEngineeringChecks => 'Caregiver engineering checks';

  @override
  String get recalibrate => 'Recalibrate';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get notAvailable => 'Not available';

  @override
  String movementTowardAction(String value) {
    return '$value° toward action';
  }

  @override
  String get trackingLabel => 'Tracking';

  @override
  String get movementLabel => 'Movement';

  @override
  String get pressThreshold => 'Press threshold';

  @override
  String get releaseThreshold => 'Release threshold';

  @override
  String get actionsLabel => 'Actions';

  @override
  String get lastEvent => 'Last event';

  @override
  String get trackingLost => 'Lost';

  @override
  String get trackingReady => 'Ready';

  @override
  String motionEventLabel(String event) {
    String _temp0 = intl.Intl.selectLogic(event, {
      'primaryAction': 'Primary action',
      'actionDown': 'Action pressed',
      'actionUp': 'Action released',
      'trackingLost': 'Tracking lost',
      'trackingRecovered': 'Tracking recovered',
      'other': 'Unknown event',
    });
    return '$_temp0';
  }

  @override
  String get caregiverValidationSemantics => 'Caregiver validation details.';

  @override
  String get validTrackingSamples => 'Valid tracking samples';

  @override
  String validTrackingSamplesValue(int valid, int total, int percent) {
    return '$valid/$total ($percent%)';
  }

  @override
  String get detectionRate => 'Detection rate';

  @override
  String framesPerSecondValue(String value) {
    return '$value FPS';
  }

  @override
  String get processingDelayMedian => 'Processing delay median';

  @override
  String millisecondsValue(int value) {
    return '$value ms';
  }

  @override
  String get droppedFrames => 'Dropped frames';

  @override
  String get observedSignalNoise => 'Observed signal/noise';

  @override
  String ratioValue(String value) {
    return '$value×';
  }

  @override
  String get signalRiseToAction => 'Signal rise to action';

  @override
  String get completeAnAction => 'Complete an action';

  @override
  String millisecondsMedianValue(int value) {
    return '$value ms median';
  }

  @override
  String get engineeringDiagnosticsNote =>
      'These are engineering diagnostics, not clinical measurements. Signal timing starts when the camera estimate rises above the measured noise floor; it is not a measurement of physical reaction time.';

  @override
  String fingerDiagnosticSemantics(String value, String state, String detail) {
    return 'Index finger flexion diagnostic. $value. $state. $detail';
  }

  @override
  String get fingerFlexionTitle => 'Index finger flexion';

  @override
  String get fingerAngleExplanation =>
      '0° is straight; a larger angle means more bend.';

  @override
  String get fingerStateSteady => 'Steady';

  @override
  String get fingerStateBending => 'Bending';

  @override
  String get fingerStateStraightening => 'Straightening';

  @override
  String get fingerWaitingTracking =>
      'Waiting for hand tracking to become available.';

  @override
  String get fingerShowHand => 'Show one hand to measure the index finger.';

  @override
  String get fingerWaitingCurrentFrame =>
      'Waiting for a current tracking frame.';

  @override
  String get fingerMoveFullyIntoView =>
      'Move the hand fully into view for a stable measurement.';

  @override
  String get fingerWaitingMeasurement => 'Waiting for a measurement.';

  @override
  String get signalGeometryUsable => 'Signal geometry: usable';

  @override
  String get signalGeometrySettling => 'Signal geometry: settling';

  @override
  String get signalGeometryUnavailable => 'Signal geometry: unavailable';

  @override
  String get firstGameSectionLabel => 'GAMES';

  @override
  String get firstGameTitle => 'Sky Sprint';

  @override
  String get firstGameDescription =>
      'Help Joybit fly safely through the gates.';

  @override
  String get openGamePreview => 'Choose a game';

  @override
  String get gameSelectionTitle => 'Choose a game';

  @override
  String get gameSelectionHeading => 'Pick your next game';

  @override
  String get gameSelectionCardDescription =>
      'Open the game cabinet. Sky Sprint is ready, and a new music game is coming next.';

  @override
  String get gameSelectionKeyboardDescription =>
      'Try a game with the large button. On a computer, Space or Enter also works.';

  @override
  String get gameSelectionMotionDescription =>
      'Your calibrated movement works with every available game.';

  @override
  String get gameSelectionMotionReadyInstruction =>
      'Your calibrated movement is ready for the selected game.';

  @override
  String get skySprintGameDescription =>
      'Help Joybit fly through the gates in this first arcade challenge.';

  @override
  String get playSelectedGame => 'PLAY';

  @override
  String get musicGameTitle => 'Music Maker';

  @override
  String get musicGameDescription =>
      'Use one comfortable movement to play an instrument. We will choose and build the instrument in the next stage.';

  @override
  String get comingNext => 'COMING NEXT';

  @override
  String get donePlaying => 'Done playing';

  @override
  String get gameTitle => 'Sky Sprint';

  @override
  String get gamePrimaryAction => 'FLY';

  @override
  String get gamePrimaryActionSemantics => 'Make Joybit fly';

  @override
  String gameScore(int score) {
    return 'Score: $score';
  }

  @override
  String gameStatusSemantics(String status, int score, String instruction) {
    return 'Sky Sprint. $status. Score: $score. $instruction';
  }

  @override
  String get gameReady => 'Ready';

  @override
  String get gameFlying => 'Flying';

  @override
  String get gameOver => 'Game over';

  @override
  String get gameReadyInstruction =>
      'Press FLY to start. On a computer, Space or Enter also works.';

  @override
  String get gameFlyingInstruction => 'Keep Joybit between the gates.';

  @override
  String get gameOverInstruction =>
      'Restart to try the same obstacle course again.';

  @override
  String get gameRestartAction => 'PLAY AGAIN';

  @override
  String gameOverSemantics(int score) {
    return 'Game over. Score: $score. Play again to restart the same obstacle course.';
  }

  @override
  String get gamePaused => 'Paused';

  @override
  String get gameMotionControlReady => 'Motion control ready';

  @override
  String get gameMotionReadyInstruction =>
      'Use your calibrated movement to make Joybit fly.';

  @override
  String get gameMotionReturnToRest => 'Return comfortably to rest';

  @override
  String get gameMotionReturnToRestInstruction =>
      'The game will resume when the movement control is ready.';

  @override
  String get gameMotionTrackingPaused => 'Tracking paused';

  @override
  String get gameMotionTrackingPausedInstruction =>
      'Reposition the tracked body area. The game will wait safely.';

  @override
  String get chooseGamesWithControl => 'Choose a game with this control';

  @override
  String get gamePauseTooltip => 'Pause game';

  @override
  String get gameResumeTooltip => 'Resume game';

  @override
  String get gameRestartTooltip => 'Restart game';

  @override
  String get gameExitTooltip => 'Return to game selection';

  @override
  String get joybitDescription =>
      'Joybit, a friendly lavender hedgehog wearing arcade headphones.';
}
