// ignore_for_file: deprecated_member_use
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Adaptive Motion Arcade'**
  String get appTitle;

  /// No description provided for @languageSelectionLabel.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get languageSelectionLabel;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @homeTitleLineOne.
  ///
  /// In en, this message translates to:
  /// **'ADAPTIVE MOTION'**
  String get homeTitleLineOne;

  /// No description provided for @homeTitleLineTwo.
  ///
  /// In en, this message translates to:
  /// **'ARCADE'**
  String get homeTitleLineTwo;

  /// No description provided for @homeCompactWelcome.
  ///
  /// In en, this message translates to:
  /// **'Ready to play your way?'**
  String get homeCompactWelcome;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome! Choose how you want to play today.'**
  String get homeWelcome;

  /// No description provided for @homeQuickPlay.
  ///
  /// In en, this message translates to:
  /// **'Quick Play'**
  String get homeQuickPlay;

  /// No description provided for @homeQuickPlayDescription.
  ///
  /// In en, this message translates to:
  /// **'Play without a profile'**
  String get homeQuickPlayDescription;

  /// No description provided for @homeSchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get homeSchool;

  /// No description provided for @homeSchoolDescription.
  ///
  /// In en, this message translates to:
  /// **'Planned after teacher feedback'**
  String get homeSchoolDescription;

  /// No description provided for @optionSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label}. {description}.'**
  String optionSemantics(String label, String description);

  /// No description provided for @arcadeLobbyTooltip.
  ///
  /// In en, this message translates to:
  /// **'Arcade lobby'**
  String get arcadeLobbyTooltip;

  /// No description provided for @quickPlayTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Play'**
  String get quickPlayTitle;

  /// No description provided for @quickPlayChooseMovementStep.
  ///
  /// In en, this message translates to:
  /// **'STEP 1 • CHOOSE MOVEMENT'**
  String get quickPlayChooseMovementStep;

  /// No description provided for @quickPlayComfortQuestion.
  ///
  /// In en, this message translates to:
  /// **'What feels comfortable today?'**
  String get quickPlayComfortQuestion;

  /// No description provided for @quickPlayCompanionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Pick one movement. We will measure what feels good today.'**
  String get quickPlayCompanionPrompt;

  /// No description provided for @movementHeadLabel.
  ///
  /// In en, this message translates to:
  /// **'Head'**
  String get movementHeadLabel;

  /// No description provided for @movementHeadDescription.
  ///
  /// In en, this message translates to:
  /// **'Tilt left or right'**
  String get movementHeadDescription;

  /// No description provided for @movementWristLabel.
  ///
  /// In en, this message translates to:
  /// **'Hand / Wrist'**
  String get movementWristLabel;

  /// No description provided for @movementWristDescription.
  ///
  /// In en, this message translates to:
  /// **'Bend your wrist'**
  String get movementWristDescription;

  /// No description provided for @movementFingerLabel.
  ///
  /// In en, this message translates to:
  /// **'Finger'**
  String get movementFingerLabel;

  /// No description provided for @movementFingerDescription.
  ///
  /// In en, this message translates to:
  /// **'Bend your index finger'**
  String get movementFingerDescription;

  /// No description provided for @movementLegLabel.
  ///
  /// In en, this message translates to:
  /// **'Leg'**
  String get movementLegLabel;

  /// No description provided for @movementLegDescription.
  ///
  /// In en, this message translates to:
  /// **'Planned for a later version'**
  String get movementLegDescription;

  /// No description provided for @movementTileSemantics.
  ///
  /// In en, this message translates to:
  /// **'{label}. {description}.'**
  String movementTileSemantics(String label, String description);

  /// No description provided for @comingLater.
  ///
  /// In en, this message translates to:
  /// **'COMING LATER'**
  String get comingLater;

  /// No description provided for @quickPlayComfortNote.
  ///
  /// In en, this message translates to:
  /// **'Choose what is comfortable now. The next step measures your movement—it never asks you to stretch farther.'**
  String get quickPlayComfortNote;

  /// No description provided for @movementShortLabel.
  ///
  /// In en, this message translates to:
  /// **'{movement, select, finger{Finger} wrist{Wrist} head{Head} other{Movement}}'**
  String movementShortLabel(String movement);

  /// No description provided for @movementSelectionDescription.
  ///
  /// In en, this message translates to:
  /// **'{movement, select, finger{Bend and straighten the index finger comfortably.} wrist{Bend the wrist comfortably in either direction.} head{Tilt the head comfortably left or right.} other{Move comfortably.}}'**
  String movementSelectionDescription(String movement);

  /// No description provided for @movementPositioningHint.
  ///
  /// In en, this message translates to:
  /// **'{movement, select, finger{Show one hand clearly, including the full index finger.} wrist{Show one hand, the wrist, and the forearm up to the elbow.} head{Center the face and keep both eyes visible.} other{Move fully into view.}}'**
  String movementPositioningHint(String movement);

  /// No description provided for @movementRestPrompt.
  ///
  /// In en, this message translates to:
  /// **'{movement, select, finger{Keep the hand comfortably at rest while the baseline is measured.} wrist{Keep the wrist comfortably at rest while the baseline is measured.} head{Keep the head comfortably at rest while the baseline is measured.} other{Rest comfortably while the baseline is measured.}}'**
  String movementRestPrompt(String movement);

  /// No description provided for @movementPrompt.
  ///
  /// In en, this message translates to:
  /// **'{movement, select, finger{Make one comfortable finger bend or straighten movement.} wrist{Make one comfortable wrist bend in either direction.} head{Make one comfortable head tilt to the left or right.} other{Make one comfortable movement.}}'**
  String movementPrompt(String movement);

  /// No description provided for @movementIncreasingDirection.
  ///
  /// In en, this message translates to:
  /// **'{movement, select, finger{More bend} wrist{More wrist bend} head{Tilt left} other{First direction}}'**
  String movementIncreasingDirection(String movement);

  /// No description provided for @movementDecreasingDirection.
  ///
  /// In en, this message translates to:
  /// **'{movement, select, finger{More straight} wrist{More straight} head{Tilt right} other{Other direction}}'**
  String movementDecreasingDirection(String movement);

  /// No description provided for @movementTrackingSubject.
  ///
  /// In en, this message translates to:
  /// **'{movement, select, finger{hand} wrist{hand} head{face} other{tracked area}}'**
  String movementTrackingSubject(String movement);

  /// No description provided for @movementReadyInstruction.
  ///
  /// In en, this message translates to:
  /// **'{movement, select, finger{Make one comfortable finger movement.} wrist{Make one comfortable wrist movement.} head{Make one comfortable head movement.} other{Make one comfortable movement.}}'**
  String movementReadyInstruction(String movement);

  /// No description provided for @calibrationScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'{movement} calibration'**
  String calibrationScreenTitle(String movement);

  /// No description provided for @controlTestScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'{movement} control test'**
  String controlTestScreenTitle(String movement);

  /// No description provided for @changeMovement.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeMovement;

  /// No description provided for @livePreviewPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Live preview only. Nothing is recorded or saved.'**
  String get livePreviewPrivacy;

  /// No description provided for @chooseMovementTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a movement'**
  String get chooseMovementTitle;

  /// No description provided for @chooseMovementQuestion.
  ///
  /// In en, this message translates to:
  /// **'What comfortable movement will control the game?'**
  String get chooseMovementQuestion;

  /// No description provided for @chooseMovementHelp.
  ///
  /// In en, this message translates to:
  /// **'A caregiver can choose the clearest option. Calibration measures the player’s current comfortable movement and never asks for a maximum range. Head control uses left/right tilt only; it does not use blinking or facial expressions.'**
  String get chooseMovementHelp;

  /// No description provided for @preparingMovementTracking.
  ///
  /// In en, this message translates to:
  /// **'Preparing movement tracking'**
  String get preparingMovementTracking;

  /// No description provided for @trackingPaused.
  ///
  /// In en, this message translates to:
  /// **'Tracking paused'**
  String get trackingPaused;

  /// No description provided for @startingTracking.
  ///
  /// In en, this message translates to:
  /// **'Starting tracking…'**
  String get startingTracking;

  /// No description provided for @trackingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Tracking unavailable'**
  String get trackingUnavailable;

  /// No description provided for @movementTrackingPausedSemantics.
  ///
  /// In en, this message translates to:
  /// **'Movement tracking paused.'**
  String get movementTrackingPausedSemantics;

  /// No description provided for @movementTrackingStartingSemantics.
  ///
  /// In en, this message translates to:
  /// **'Starting movement tracking.'**
  String get movementTrackingStartingSemantics;

  /// No description provided for @movementTrackingActiveSemantics.
  ///
  /// In en, this message translates to:
  /// **'{movement} movement is being tracked.'**
  String movementTrackingActiveSemantics(String movement);

  /// No description provided for @movementTrackingUnavailableSemantics.
  ///
  /// In en, this message translates to:
  /// **'Movement tracking is unavailable.'**
  String get movementTrackingUnavailableSemantics;

  /// No description provided for @trackingDetected.
  ///
  /// In en, this message translates to:
  /// **'{movement} detected • {fps} FPS'**
  String trackingDetected(String movement, int fps);

  /// No description provided for @trackingDetectedWithLatency.
  ///
  /// In en, this message translates to:
  /// **'{movement} detected • {fps} FPS • {latency} ms'**
  String trackingDetectedWithLatency(String movement, int fps, int latency);

  /// No description provided for @cameraPreviewLoading.
  ///
  /// In en, this message translates to:
  /// **'Camera preview loading'**
  String get cameraPreviewLoading;

  /// No description provided for @cameraPreviewUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera preview unavailable'**
  String get cameraPreviewUnavailable;

  /// No description provided for @cameraTitleStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting camera'**
  String get cameraTitleStarting;

  /// No description provided for @cameraTitleReady.
  ///
  /// In en, this message translates to:
  /// **'Camera ready'**
  String get cameraTitleReady;

  /// No description provided for @cameraTitleNoFrontCamera.
  ///
  /// In en, this message translates to:
  /// **'Front camera unavailable'**
  String get cameraTitleNoFrontCamera;

  /// No description provided for @cameraTitlePermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Camera permission needed'**
  String get cameraTitlePermissionNeeded;

  /// No description provided for @cameraTitleAccessRestricted.
  ///
  /// In en, this message translates to:
  /// **'Camera access restricted'**
  String get cameraTitleAccessRestricted;

  /// No description provided for @cameraTitlePaused.
  ///
  /// In en, this message translates to:
  /// **'Camera paused'**
  String get cameraTitlePaused;

  /// No description provided for @cameraTitleUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable'**
  String get cameraTitleUnavailable;

  /// No description provided for @cameraMessageStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting the front camera…'**
  String get cameraMessageStarting;

  /// No description provided for @cameraMessageAdjustingOrientation.
  ///
  /// In en, this message translates to:
  /// **'Adjusting camera orientation…'**
  String get cameraMessageAdjustingOrientation;

  /// No description provided for @cameraMessageReady.
  ///
  /// In en, this message translates to:
  /// **'The front camera preview is ready.'**
  String get cameraMessageReady;

  /// No description provided for @cameraMessageNoFrontCamera.
  ///
  /// In en, this message translates to:
  /// **'No front-facing camera was found on this device.'**
  String get cameraMessageNoFrontCamera;

  /// No description provided for @cameraMessagePermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera access was denied. Allow camera access in device settings, then try again.'**
  String get cameraMessagePermissionDenied;

  /// No description provided for @cameraMessagePermissionRestricted.
  ///
  /// In en, this message translates to:
  /// **'Camera access is restricted on this device.'**
  String get cameraMessagePermissionRestricted;

  /// No description provided for @cameraMessagePaused.
  ///
  /// In en, this message translates to:
  /// **'Camera paused while the app is not active.'**
  String get cameraMessagePaused;

  /// No description provided for @cameraMessageFailure.
  ///
  /// In en, this message translates to:
  /// **'The camera could not start. Please try again.'**
  String get cameraMessageFailure;

  /// No description provided for @cameraStatusSemantics.
  ///
  /// In en, this message translates to:
  /// **'Camera status. {title}. {message}'**
  String cameraStatusSemantics(String title, String message);

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @calibrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Comfortable movement calibration'**
  String get calibrationTitle;

  /// No description provided for @calibrationIntroduction.
  ///
  /// In en, this message translates to:
  /// **'A caregiver can guide two short steps. Keep every movement comfortable—never push for a maximum range.'**
  String get calibrationIntroduction;

  /// No description provided for @selectedMovement.
  ///
  /// In en, this message translates to:
  /// **'Selected movement: {movement}.'**
  String selectedMovement(String movement);

  /// No description provided for @startRestMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Start rest measurement'**
  String get startRestMeasurement;

  /// No description provided for @calibrationStepOne.
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2 • Rest comfortably'**
  String get calibrationStepOne;

  /// No description provided for @stableSamples.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Stable samples: 0} =1{Stable sample: 1} other{Stable samples: {count}}}'**
  String stableSamples(int count);

  /// No description provided for @retryRestMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Retry rest measurement'**
  String get retryRestMeasurement;

  /// No description provided for @restMeasurementComplete.
  ///
  /// In en, this message translates to:
  /// **'Rest measurement complete'**
  String get restMeasurementComplete;

  /// No description provided for @restEstimateNext.
  ///
  /// In en, this message translates to:
  /// **'Rest estimate: ~{value}°. Next, {prompt}'**
  String restEstimateNext(String value, String prompt);

  /// No description provided for @measureComfortableMovement.
  ///
  /// In en, this message translates to:
  /// **'Measure comfortable movement'**
  String get measureComfortableMovement;

  /// No description provided for @calibrationStepTwo.
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 2 • Move comfortably'**
  String get calibrationStepTwo;

  /// No description provided for @movementPromptSafety.
  ///
  /// In en, this message translates to:
  /// **'{prompt} Do not push farther.'**
  String movementPromptSafety(String prompt);

  /// No description provided for @retryMovement.
  ///
  /// In en, this message translates to:
  /// **'Retry movement'**
  String get retryMovement;

  /// No description provided for @reviewManualSetting.
  ///
  /// In en, this message translates to:
  /// **'Review manual setting'**
  String get reviewManualSetting;

  /// No description provided for @manualThresholdUnavailable.
  ///
  /// In en, this message translates to:
  /// **'A reliable manual threshold is not available because the movement overlaps the measured noise. Retrying is safest.'**
  String get manualThresholdUnavailable;

  /// No description provided for @caregiverReview.
  ///
  /// In en, this message translates to:
  /// **'Caregiver review'**
  String get caregiverReview;

  /// No description provided for @caregiverReviewInstructions.
  ///
  /// In en, this message translates to:
  /// **'Choose the direction and sensitivity. The threshold cannot go below measured noise or beyond the observed comfortable movement.'**
  String get caregiverReviewInstructions;

  /// No description provided for @movementDirection.
  ///
  /// In en, this message translates to:
  /// **'Movement direction'**
  String get movementDirection;

  /// No description provided for @sensitivityFromRest.
  ///
  /// In en, this message translates to:
  /// **'Sensitivity: ~{value}° from rest'**
  String sensitivityFromRest(String value);

  /// No description provided for @measuredNoiseAndMovement.
  ///
  /// In en, this message translates to:
  /// **'Measured noise floor: ~{noise}°. Observed comfortable movement: ~{movement}°.'**
  String measuredNoiseAndMovement(String noise, String movement);

  /// No description provided for @useThisSetting.
  ///
  /// In en, this message translates to:
  /// **'Use this setting'**
  String get useThisSetting;

  /// No description provided for @calibrationReady.
  ///
  /// In en, this message translates to:
  /// **'Calibration ready'**
  String get calibrationReady;

  /// No description provided for @calibrationDirectionThreshold.
  ///
  /// In en, this message translates to:
  /// **'Direction: {direction}. Threshold: ~{value}° from rest.'**
  String calibrationDirectionThreshold(String direction, String value);

  /// No description provided for @calibrationNotSaved.
  ///
  /// In en, this message translates to:
  /// **'This calibration is not saved and clears when you leave this screen.'**
  String get calibrationNotSaved;

  /// No description provided for @calibrationSuccessCompanion.
  ///
  /// In en, this message translates to:
  /// **'Nice job! This setting stays within the movement measured today.'**
  String get calibrationSuccessCompanion;

  /// No description provided for @testThisControl.
  ///
  /// In en, this message translates to:
  /// **'Test this control'**
  String get testThisControl;

  /// No description provided for @calibrateAgain.
  ///
  /// In en, this message translates to:
  /// **'Calibrate again'**
  String get calibrateAgain;

  /// No description provided for @calibrationSemanticReady.
  ///
  /// In en, this message translates to:
  /// **'Calibration ready to begin.'**
  String get calibrationSemanticReady;

  /// No description provided for @calibrationSemanticMeasuringRest.
  ///
  /// In en, this message translates to:
  /// **'Measuring comfortable rest position.'**
  String get calibrationSemanticMeasuringRest;

  /// No description provided for @calibrationSemanticRestComplete.
  ///
  /// In en, this message translates to:
  /// **'Rest measurement complete. Comfortable movement is next.'**
  String get calibrationSemanticRestComplete;

  /// No description provided for @calibrationSemanticMeasuringMovement.
  ///
  /// In en, this message translates to:
  /// **'Measuring one comfortable movement.'**
  String get calibrationSemanticMeasuringMovement;

  /// No description provided for @calibrationSemanticReview.
  ///
  /// In en, this message translates to:
  /// **'Calibration is ready for caregiver review.'**
  String get calibrationSemanticReview;

  /// No description provided for @calibrationSemanticComplete.
  ///
  /// In en, this message translates to:
  /// **'Calibration complete. It is not saved.'**
  String get calibrationSemanticComplete;

  /// No description provided for @currentAngleSemantics.
  ///
  /// In en, this message translates to:
  /// **'Current estimated {movement} angle {value}'**
  String currentAngleSemantics(String movement, String value);

  /// No description provided for @currentAngleUnavailableSemantics.
  ///
  /// In en, this message translates to:
  /// **'Current {movement} angle unavailable'**
  String currentAngleUnavailableSemantics(String movement);

  /// No description provided for @baselineTrackingPaused.
  ///
  /// In en, this message translates to:
  /// **'Tracking paused. {hint}'**
  String baselineTrackingPaused(String hint);

  /// No description provided for @delayedTrackingSample.
  ///
  /// In en, this message translates to:
  /// **'A delayed tracking sample was ignored.'**
  String get delayedTrackingSample;

  /// No description provided for @restSignalTooVariable.
  ///
  /// In en, this message translates to:
  /// **'The resting signal is too variable for an automatic setting. Try again or use a caregiver-adjusted setting.'**
  String get restSignalTooVariable;

  /// No description provided for @restSignalStable.
  ///
  /// In en, this message translates to:
  /// **'The resting signal is stable enough to continue.'**
  String get restSignalStable;

  /// No description provided for @movementNotSeparated.
  ///
  /// In en, this message translates to:
  /// **'This comfortable movement was not clearly separated from normal signal variation. Retry or use a caregiver-adjusted setting.'**
  String get movementNotSeparated;

  /// No description provided for @movementRecommendationReady.
  ///
  /// In en, this message translates to:
  /// **'A starting threshold is available for caregiver review. It does not require a larger movement.'**
  String get movementRecommendationReady;

  /// No description provided for @validationChooseSensitivity.
  ///
  /// In en, this message translates to:
  /// **'Choose a valid sensitivity setting.'**
  String get validationChooseSensitivity;

  /// No description provided for @validationBelowNoise.
  ///
  /// In en, this message translates to:
  /// **'This setting is below the measured noise floor of {value}°. Increase the threshold or retry calibration.'**
  String validationBelowNoise(String value);

  /// No description provided for @validationBeyondComfort.
  ///
  /// In en, this message translates to:
  /// **'This setting is beyond the comfortable movement that was observed. Lower the threshold or retry calibration.'**
  String get validationBeyondComfort;

  /// No description provided for @validationOutsideRange.
  ///
  /// In en, this message translates to:
  /// **'This direction and sensitivity are outside the measured signal range. Change the setting or retry calibration.'**
  String get validationOutsideRange;

  /// No description provided for @validationReliable.
  ///
  /// In en, this message translates to:
  /// **'This setting is above noise and within observed comfort.'**
  String get validationReliable;

  /// No description provided for @controlStatusTrackingPaused.
  ///
  /// In en, this message translates to:
  /// **'TRACKING PAUSED'**
  String get controlStatusTrackingPaused;

  /// No description provided for @controlStatusActionPressed.
  ///
  /// In en, this message translates to:
  /// **'ACTION PRESSED'**
  String get controlStatusActionPressed;

  /// No description provided for @controlStatusReturnToRest.
  ///
  /// In en, this message translates to:
  /// **'RETURN TO REST'**
  String get controlStatusReturnToRest;

  /// No description provided for @controlStatusReady.
  ///
  /// In en, this message translates to:
  /// **'READY'**
  String get controlStatusReady;

  /// No description provided for @controlInstructionReposition.
  ///
  /// In en, this message translates to:
  /// **'Reposition the {subject} to continue.'**
  String controlInstructionReposition(String subject);

  /// No description provided for @controlInstructionReturnComfortably.
  ///
  /// In en, this message translates to:
  /// **'Return comfortably to rest before moving again.'**
  String get controlInstructionReturnComfortably;

  /// No description provided for @controlInstructionWillArm.
  ///
  /// In en, this message translates to:
  /// **'The control will arm after the movement returns to rest.'**
  String get controlInstructionWillArm;

  /// No description provided for @controlTestSemantics.
  ///
  /// In en, this message translates to:
  /// **'Control test. {status}. {count, plural, =0{No actions detected} =1{One action detected} other{{count} actions detected}}. {instruction}'**
  String controlTestSemantics(String status, int count, String instruction);

  /// No description provided for @controlTestTitle.
  ///
  /// In en, this message translates to:
  /// **'Control Test'**
  String get controlTestTitle;

  /// No description provided for @controlTestDescription.
  ///
  /// In en, this message translates to:
  /// **'One comfortable movement should create one action.'**
  String get controlTestDescription;

  /// No description provided for @developerTestInput.
  ///
  /// In en, this message translates to:
  /// **'Developer test input'**
  String get developerTestInput;

  /// No description provided for @testPress.
  ///
  /// In en, this message translates to:
  /// **'Test press'**
  String get testPress;

  /// No description provided for @testRelease.
  ///
  /// In en, this message translates to:
  /// **'Test release'**
  String get testRelease;

  /// No description provided for @validationDetails.
  ///
  /// In en, this message translates to:
  /// **'Validation details'**
  String get validationDetails;

  /// No description provided for @caregiverEngineeringChecks.
  ///
  /// In en, this message translates to:
  /// **'Caregiver engineering checks'**
  String get caregiverEngineeringChecks;

  /// No description provided for @recalibrate.
  ///
  /// In en, this message translates to:
  /// **'Recalibrate'**
  String get recalibrate;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @movementTowardAction.
  ///
  /// In en, this message translates to:
  /// **'{value}° toward action'**
  String movementTowardAction(String value);

  /// No description provided for @trackingLabel.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get trackingLabel;

  /// No description provided for @movementLabel.
  ///
  /// In en, this message translates to:
  /// **'Movement'**
  String get movementLabel;

  /// No description provided for @pressThreshold.
  ///
  /// In en, this message translates to:
  /// **'Press threshold'**
  String get pressThreshold;

  /// No description provided for @releaseThreshold.
  ///
  /// In en, this message translates to:
  /// **'Release threshold'**
  String get releaseThreshold;

  /// No description provided for @actionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actionsLabel;

  /// No description provided for @lastEvent.
  ///
  /// In en, this message translates to:
  /// **'Last event'**
  String get lastEvent;

  /// No description provided for @trackingLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get trackingLost;

  /// No description provided for @trackingReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get trackingReady;

  /// No description provided for @motionEventLabel.
  ///
  /// In en, this message translates to:
  /// **'{event, select, primaryAction{Primary action} actionDown{Action pressed} actionUp{Action released} trackingLost{Tracking lost} trackingRecovered{Tracking recovered} other{Unknown event}}'**
  String motionEventLabel(String event);

  /// No description provided for @caregiverValidationSemantics.
  ///
  /// In en, this message translates to:
  /// **'Caregiver validation details.'**
  String get caregiverValidationSemantics;

  /// No description provided for @validTrackingSamples.
  ///
  /// In en, this message translates to:
  /// **'Valid tracking samples'**
  String get validTrackingSamples;

  /// No description provided for @validTrackingSamplesValue.
  ///
  /// In en, this message translates to:
  /// **'{valid}/{total} ({percent}%)'**
  String validTrackingSamplesValue(int valid, int total, int percent);

  /// No description provided for @detectionRate.
  ///
  /// In en, this message translates to:
  /// **'Detection rate'**
  String get detectionRate;

  /// No description provided for @framesPerSecondValue.
  ///
  /// In en, this message translates to:
  /// **'{value} FPS'**
  String framesPerSecondValue(String value);

  /// No description provided for @processingDelayMedian.
  ///
  /// In en, this message translates to:
  /// **'Processing delay median'**
  String get processingDelayMedian;

  /// No description provided for @millisecondsValue.
  ///
  /// In en, this message translates to:
  /// **'{value} ms'**
  String millisecondsValue(int value);

  /// No description provided for @droppedFrames.
  ///
  /// In en, this message translates to:
  /// **'Dropped frames'**
  String get droppedFrames;

  /// No description provided for @observedSignalNoise.
  ///
  /// In en, this message translates to:
  /// **'Observed signal/noise'**
  String get observedSignalNoise;

  /// No description provided for @ratioValue.
  ///
  /// In en, this message translates to:
  /// **'{value}×'**
  String ratioValue(String value);

  /// No description provided for @signalRiseToAction.
  ///
  /// In en, this message translates to:
  /// **'Signal rise to action'**
  String get signalRiseToAction;

  /// No description provided for @completeAnAction.
  ///
  /// In en, this message translates to:
  /// **'Complete an action'**
  String get completeAnAction;

  /// No description provided for @millisecondsMedianValue.
  ///
  /// In en, this message translates to:
  /// **'{value} ms median'**
  String millisecondsMedianValue(int value);

  /// No description provided for @engineeringDiagnosticsNote.
  ///
  /// In en, this message translates to:
  /// **'These are engineering diagnostics, not clinical measurements. Signal timing starts when the camera estimate rises above the measured noise floor; it is not a measurement of physical reaction time.'**
  String get engineeringDiagnosticsNote;

  /// No description provided for @fingerDiagnosticSemantics.
  ///
  /// In en, this message translates to:
  /// **'Index finger flexion diagnostic. {value}. {state}. {detail}'**
  String fingerDiagnosticSemantics(String value, String state, String detail);

  /// No description provided for @fingerFlexionTitle.
  ///
  /// In en, this message translates to:
  /// **'Index finger flexion'**
  String get fingerFlexionTitle;

  /// No description provided for @fingerAngleExplanation.
  ///
  /// In en, this message translates to:
  /// **'0° is straight; a larger angle means more bend.'**
  String get fingerAngleExplanation;

  /// No description provided for @fingerStateSteady.
  ///
  /// In en, this message translates to:
  /// **'Steady'**
  String get fingerStateSteady;

  /// No description provided for @fingerStateBending.
  ///
  /// In en, this message translates to:
  /// **'Bending'**
  String get fingerStateBending;

  /// No description provided for @fingerStateStraightening.
  ///
  /// In en, this message translates to:
  /// **'Straightening'**
  String get fingerStateStraightening;

  /// No description provided for @fingerWaitingTracking.
  ///
  /// In en, this message translates to:
  /// **'Waiting for hand tracking to become available.'**
  String get fingerWaitingTracking;

  /// No description provided for @fingerShowHand.
  ///
  /// In en, this message translates to:
  /// **'Show one hand to measure the index finger.'**
  String get fingerShowHand;

  /// No description provided for @fingerWaitingCurrentFrame.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a current tracking frame.'**
  String get fingerWaitingCurrentFrame;

  /// No description provided for @fingerMoveFullyIntoView.
  ///
  /// In en, this message translates to:
  /// **'Move the hand fully into view for a stable measurement.'**
  String get fingerMoveFullyIntoView;

  /// No description provided for @fingerWaitingMeasurement.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a measurement.'**
  String get fingerWaitingMeasurement;

  /// No description provided for @signalGeometryUsable.
  ///
  /// In en, this message translates to:
  /// **'Signal geometry: usable'**
  String get signalGeometryUsable;

  /// No description provided for @signalGeometrySettling.
  ///
  /// In en, this message translates to:
  /// **'Signal geometry: settling'**
  String get signalGeometrySettling;

  /// No description provided for @signalGeometryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Signal geometry: unavailable'**
  String get signalGeometryUnavailable;

  /// No description provided for @firstGameSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'GAMES'**
  String get firstGameSectionLabel;

  /// No description provided for @firstGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Sky Sprint'**
  String get firstGameTitle;

  /// No description provided for @firstGameDescription.
  ///
  /// In en, this message translates to:
  /// **'Help Joybit fly safely through the gates.'**
  String get firstGameDescription;

  /// No description provided for @openGamePreview.
  ///
  /// In en, this message translates to:
  /// **'Choose a game'**
  String get openGamePreview;

  /// No description provided for @gameSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a game'**
  String get gameSelectionTitle;

  /// No description provided for @gameSelectionHeading.
  ///
  /// In en, this message translates to:
  /// **'Pick your next game'**
  String get gameSelectionHeading;

  /// No description provided for @gameSelectionCardDescription.
  ///
  /// In en, this message translates to:
  /// **'Open the game cabinet. Sky Sprint is ready, and a new music game is coming next.'**
  String get gameSelectionCardDescription;

  /// No description provided for @gameSelectionKeyboardDescription.
  ///
  /// In en, this message translates to:
  /// **'Try a game with the large button. On a computer, Space or Enter also works.'**
  String get gameSelectionKeyboardDescription;

  /// No description provided for @gameSelectionMotionDescription.
  ///
  /// In en, this message translates to:
  /// **'Your calibrated movement works with every available game.'**
  String get gameSelectionMotionDescription;

  /// No description provided for @gameSelectionMotionReadyInstruction.
  ///
  /// In en, this message translates to:
  /// **'Your calibrated movement is ready for the selected game.'**
  String get gameSelectionMotionReadyInstruction;

  /// No description provided for @skySprintGameDescription.
  ///
  /// In en, this message translates to:
  /// **'Help Joybit fly through the gates in this first arcade challenge.'**
  String get skySprintGameDescription;

  /// No description provided for @playSelectedGame.
  ///
  /// In en, this message translates to:
  /// **'PLAY'**
  String get playSelectedGame;

  /// No description provided for @musicGameTitle.
  ///
  /// In en, this message translates to:
  /// **'Music Maker'**
  String get musicGameTitle;

  /// No description provided for @musicGameDescription.
  ///
  /// In en, this message translates to:
  /// **'Use one comfortable movement to play an instrument. We will choose and build the instrument in the next stage.'**
  String get musicGameDescription;

  /// No description provided for @comingNext.
  ///
  /// In en, this message translates to:
  /// **'COMING NEXT'**
  String get comingNext;

  /// No description provided for @donePlaying.
  ///
  /// In en, this message translates to:
  /// **'Done playing'**
  String get donePlaying;

  /// No description provided for @gameTitle.
  ///
  /// In en, this message translates to:
  /// **'Sky Sprint'**
  String get gameTitle;

  /// No description provided for @gamePrimaryAction.
  ///
  /// In en, this message translates to:
  /// **'FLY'**
  String get gamePrimaryAction;

  /// No description provided for @gamePrimaryActionSemantics.
  ///
  /// In en, this message translates to:
  /// **'Make Joybit fly'**
  String get gamePrimaryActionSemantics;

  /// No description provided for @gameScore.
  ///
  /// In en, this message translates to:
  /// **'Score: {score}'**
  String gameScore(int score);

  /// No description provided for @gameStatusSemantics.
  ///
  /// In en, this message translates to:
  /// **'Sky Sprint. {status}. Score: {score}. {instruction}'**
  String gameStatusSemantics(String status, int score, String instruction);

  /// No description provided for @gameReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get gameReady;

  /// No description provided for @gameFlying.
  ///
  /// In en, this message translates to:
  /// **'Flying'**
  String get gameFlying;

  /// No description provided for @gameOver.
  ///
  /// In en, this message translates to:
  /// **'Game over'**
  String get gameOver;

  /// No description provided for @gameReadyInstruction.
  ///
  /// In en, this message translates to:
  /// **'Press FLY to start. On a computer, Space or Enter also works.'**
  String get gameReadyInstruction;

  /// No description provided for @gameFlyingInstruction.
  ///
  /// In en, this message translates to:
  /// **'Keep Joybit between the gates.'**
  String get gameFlyingInstruction;

  /// No description provided for @gameOverInstruction.
  ///
  /// In en, this message translates to:
  /// **'Restart to try the same obstacle course again.'**
  String get gameOverInstruction;

  /// No description provided for @gameRestartAction.
  ///
  /// In en, this message translates to:
  /// **'PLAY AGAIN'**
  String get gameRestartAction;

  /// No description provided for @gameOverSemantics.
  ///
  /// In en, this message translates to:
  /// **'Game over. Score: {score}. Play again to restart the same obstacle course.'**
  String gameOverSemantics(int score);

  /// No description provided for @gamePaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get gamePaused;

  /// No description provided for @gameMotionControlReady.
  ///
  /// In en, this message translates to:
  /// **'Motion control ready'**
  String get gameMotionControlReady;

  /// No description provided for @gameMotionReadyInstruction.
  ///
  /// In en, this message translates to:
  /// **'Use your calibrated movement to make Joybit fly.'**
  String get gameMotionReadyInstruction;

  /// No description provided for @gameMotionReturnToRest.
  ///
  /// In en, this message translates to:
  /// **'Return comfortably to rest'**
  String get gameMotionReturnToRest;

  /// No description provided for @gameMotionReturnToRestInstruction.
  ///
  /// In en, this message translates to:
  /// **'The game will resume when the movement control is ready.'**
  String get gameMotionReturnToRestInstruction;

  /// No description provided for @gameMotionTrackingPaused.
  ///
  /// In en, this message translates to:
  /// **'Tracking paused'**
  String get gameMotionTrackingPaused;

  /// No description provided for @gameMotionTrackingPausedInstruction.
  ///
  /// In en, this message translates to:
  /// **'Reposition the tracked body area. The game will wait safely.'**
  String get gameMotionTrackingPausedInstruction;

  /// No description provided for @chooseGamesWithControl.
  ///
  /// In en, this message translates to:
  /// **'Choose a game with this control'**
  String get chooseGamesWithControl;

  /// No description provided for @gamePauseTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pause game'**
  String get gamePauseTooltip;

  /// No description provided for @gameResumeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Resume game'**
  String get gameResumeTooltip;

  /// No description provided for @gameRestartTooltip.
  ///
  /// In en, this message translates to:
  /// **'Restart game'**
  String get gameRestartTooltip;

  /// No description provided for @gameExitTooltip.
  ///
  /// In en, this message translates to:
  /// **'Return to game selection'**
  String get gameExitTooltip;

  /// No description provided for @joybitDescription.
  ///
  /// In en, this message translates to:
  /// **'Joybit, a friendly lavender hedgehog wearing arcade headphones.'**
  String get joybitDescription;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
