# Adaptive Motion Arcade

Adaptive Motion Arcade is an accessible Flutter application for iOS and
Android. Its goal is to turn a child's comfortable hand or finger movement into
a simple, reusable game control.

## Current scope

The app currently tracks index-finger bend, wrist bend and left/right head tilt.
A caregiver-guided calibration measures comfortable rest variation and one
intentional movement before creating a game-independent one-button controller.
The Control Test verifies rearming, tracking loss and one-action-per-movement
behavior without running a game.

Stage 7 adds caregiver validation diagnostics, a repeatable real-device
protocol and synthetic acceptance scenarios. One adult tester reported a pass
of the minimum core checklist on a physical Android device at commit `2da9fae`
on 2026-11-17. Quantitative diagnostics, the broader device/condition matrix
and iPhone/iPad observations remain pending. Calibration remains in memory;
full game mechanics, student profiles, session persistence and results are not
implemented.

## Architecture

The processing path is intentionally split at technology boundaries:

```text
camera frames -> MediaPipe adapter -> HandObservation -> skeleton overlay
                                      |
                                      +-> finger movement analyzer
                                                    |
                                                    +-> baseline session
                                                              |
                                                              +-> comfortable
                                                                  movement
                                                                  analysis
                                                                        |
                                                                        +-> caregiver
                                                                            review
                                                                        |
                                                                        +-> in-memory
                                                                            profile
                                                                                  |
                                                                                  +-> universal
                                                                                      input events
                                                                                           |
                                                                                           +-> Control Test
```

`HandObservation` is an app-owned type containing a timestamp, 21 normalized
landmarks, source dimensions, orientation and mirroring metadata. MediaPipe
types remain inside the adapter, so later motion logic can be pure Dart and can
be tested without a camera or child participant.

The live-stream task processes one frame while retaining only the newest
waiting frame. Frames it replaces are counted and never converted, preventing
an inference backlog. YUV conversion runs outside the UI isolate. A missing or
stale result removes the skeleton instead of freezing the last detected hand.

## Finger movement math

The Stage 4 diagnostic measures the index finger's proximal interphalangeal
(PIP) joint using MediaPipe landmarks 5, 6 and 7:

- landmark 5: index metacarpophalangeal joint (MCP);
- landmark 6: index proximal interphalangeal joint (PIP), the angle vertex;
- landmark 7: index distal interphalangeal joint (DIP).

The analyzer forms vectors from PIP to MCP and from PIP to DIP. It computes the
interior angle with a clamped dot product, then reports:

```text
flexion = 180° - interior joint angle
```

`0°` therefore means approximately straight and positive values mean more
bend. The calculation uses relative 3D hand geometry rather than screen-pixel
movement. Normalized x/y coordinates are corrected for the camera image's
aspect ratio. Mirroring does not change the angle.

The displayed value uses an exponential low-pass filter with a 120 ms time
constant. Its weight is calculated from each sample's timestamp, so it does not
assume a particular camera frame rate. A gap of 500 ms or a missing hand resets
the filter instead of carrying stale motion into a reacquired hand. Direction
uses a 5 degrees-per-second deadband to keep tiny tracking noise labeled
`Steady`; the angle itself is not discarded.

Required landmarks must be finite, and both finger segments must be long
enough relative to the wrist-to-middle-MCP palm reference. Optional detector
visibility/presence values are recorded only when the detector actually
provides them. They are never invented. The output includes the smoothed and
raw angles, degrees-per-second velocity, timestamp, validity, signal-quality
notes and reacquisition state.

## Stage 5A baseline foundation

`BaselineCalibrationSession` keeps only timestamps and the Stage 4 angle; it
does not retain camera frames or landmarks. A default baseline needs at least
eight samples spanning two seconds. A tracking interruption or a gap longer
than 350 ms restarts that stable interval so stale readings are not combined.
Delayed samples are ignored without erasing valid progress.

The resting baseline is the median angle. Signal noise is estimated with the
median absolute deviation multiplied by 1.4826, a robust estimate that is less
affected by an occasional unusual reading. A default estimate above 6 degrees
is reported as too variable for an automatic setting, but never as a failure by
the child. These are engineering defaults for the future caregiver workflow,
not clinical limits. Stage 5B compares a comfortable intentional movement
against this noise before recommending a threshold.

## Stage 5B comfortable-movement analysis

`ComfortableMovementCalibrationSession` observes one intentional movement for
at least 1.5 seconds without asking for a maximum range. It uses robust 10th and
90th percentiles around the rest baseline to detect whether comfortable motion
decreases or increases the flexion angle.

The default noise floor is three times the Stage 5A noise estimate. A reliable
offset must also exceed a conservative 4-degree engineering minimum. If the
observed amplitude does not exceed the larger of those values, no automatic
threshold is produced. Otherwise, the starting threshold is halfway toward
the comfortable value, raised to the reliable floor when necessary. This
guarantees that a recommendation is never below the measured noise floor and
never asks for movement beyond what was observed.

## Stage 5C–5D caregiver workflow

The calibration screen guides the caregiver through rest measurement,
comfortable movement and review. Direction can be changed between more bend
and more straight. Sensitivity is limited to the range from measured noise to
the observed comfortable amplitude. A setting below noise or beyond observed
comfort cannot be accepted as reliable.

When a small movement is above measured noise but below the conservative
automatic 4-degree minimum, the caregiver may review a manual fallback. No
manual fallback is offered when movement overlaps noise. The completed model
includes movement type, degrees, baseline, noise estimate, noise floor,
threshold, direction, timestamps, threshold source, camera facing, preview
mirroring and device orientation. It is not persisted.

## Stage 6 controller and Stage 7 validation gate

All supported movements are converted into the same direction-normalized
signal and universal action events. Hysteresis requires a return to rest before
another action, while tracking loss safely releases a held action and requires
rest after recovery. Camera and MediaPipe types remain outside this controller.

The Control Test exposes a collapsed caregiver validation section with valid
tracking samples, detection rate, processing delay, dropped frames, observed
signal/noise and signal-rise-to-action timing. The executable device protocol
and worksheet are in `validation/STAGE_07_DEVICE_VALIDATION.md`. The recorded
Android POC pass covers the core observable behaviors; unrecorded quantitative
fields and additional device conditions remain explicitly pending.

## English and Spanish support

The current POC journey fully supports English and Spanish. English remains the
source catalog in `lib/l10n/app_en.arb`, with the matching Spanish catalog in
`lib/l10n/app_es.arb`. The app initially follows the device language, falling
back to English, and the lobby provides a one-tap English/Español switch. The
selection is stored locally on that device and restored the next time the app
opens.

Lobby, Quick Play, camera, calibration, control-test, status, error, tooltip
and screen-reader wording are translated. Numeric diagnostics also use the
active language's decimal format, and the iOS camera-permission explanation is
available in both languages. Motion and calibration logic continue to expose
semantic states so internal diagnostic sentences do not leak into the
interface. New screens must add matching entries to both ARB catalogs and test
both locales before they are considered complete.

## Stage 9 game integration

The Quick Play screen includes a bilingual preview of the first original game,
**Sky Sprint**. Its Flame shell renders an original pixel-style Joybit flyer
with deterministic gravity, obstacles, collision, scoring and restart. The
same primary arcade action can come from a large touch button, the Space and
Enter keys, or a validated calibrated movement. Pause, resume, restart and exit
remain available without requiring a camera, so the game boundary can still be
tested independently.

`ArcadeInputController` is the camera-free contract used by the game. The
`MotionArcadeInputAdapter` forwards only Stage 6 one-shot primary events;
action-down, action-up and tracking-state events cannot create duplicate game
actions. `CalibratedArcadeInputSession` keeps the selected calibration as
in-memory movement-session context while exposing only camera-free game input.
Tracking loss suspends play, and recovery requires a comfortable return to rest
before the game resumes. Game score remains separate from physical movement
data and is not presented as motor improvement. Sessions are not persisted yet.

After Control Test, the calibrated input now opens a responsive game-selection
screen based on the cartridge-style wireframe. Sky Sprint is playable and
returns to that screen when closed. A disabled Music Maker cartridge reserves
the second slot without pretending that its instrument interaction has already
been designed or implemented. The same selection screen is available from
Quick Play for camera-free button and keyboard testing.

Game difficulty and physical control sensitivity must remain independent.
`FlapToFlyConfig` already isolates game-only values such as gravity, obstacle
speed, spacing and gap size. Sky Sprint's current values remain unchanged for
the POC. Before additional games or caregiver difficulty controls are added,
define clear presets such as slower speed and larger gaps, test every preset,
and never automatically require a larger physical movement from a child.

## Hand-tracking technology decision

Stage 3 uses Google's maintained `mediapipe_vision` Flutter package, pinned to
`0.3.0`, and Google's bundled Hand Landmarker model. It supports both Android
and iOS and runs Google's live-stream graph with temporal tracking. The other
packages reviewed were third-party, Android-only, or required recreating the
palm detection, rotated crop and tracking pipeline directly with LiteRT.

The model is checksum-verified and bundled in the app, so it is not downloaded
at runtime. Rebuild or verify the bundle with:

```sh
dart run mediapipe_core:bundle_models
dart run mediapipe_core:bundle_models --check
```

## Privacy and measurement

- Camera images are processed on the device and are not recorded, saved or
  uploaded by this app.
- Audio is disabled and the app does not request microphone permission.
- The bundled model needs no network connection at runtime.
- Hand landmarks are estimates and must not be presented as millimeter-accurate
  or clinical measurements.

Google's native MediaPipe runtime does send usage metrics to Google when a task
closes. According to Google's package documentation, these metrics include the
task, running mode, latency/input counts, platform and app/device metadata, but
never the images being processed. The package does not provide an opt-out.
Before release—especially for children—the product owner must address consent,
privacy policy, store disclosures and whether the logging is acceptable. The
iOS target includes the required-reason API privacy manifest; App Store privacy
answers are still a separate responsibility.

## Platform baseline

- Android 9 (API 28) or newer.
- iOS 15 or newer.
- Flutter 3.44 / Dart 3.12 or newer.

An Android emulator runs MediaPipe on the CPU. Physical phones can use the
accelerator offered by Google's runtime and are the meaningful performance
test target.

## Run and validate

Use a connected Android or iOS device, or an installed simulator:

### Launch the Pixel emulator from VS Code

To restore the standalone Pixel test window, press **Command–Shift–P** in VS
Code, select **Flutter: Launch Emulator**, and choose **Pixel XL API 32**. Wait
for the Android home screen before pressing F5 to debug the app.

If the camera shows the green Android or another artificial scene, stop the
emulator and edit **Pixel XL API 32** in Android Studio's Device Manager. Under
**Show Advanced Settings → Camera**, set the front camera to **Webcam0**, save,
and cold-boot the emulator. Android Studio is only needed to configure the
virtual device; the app should still be launched from VS Code.

```sh
flutter pub get
dart run mediapipe_core:bundle_models --check
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter devices
flutter run -d <device-id>
```

On the selected movement's calibration screen, check that:

1. The start button is available only while the selected body area is tracked.
2. Resting comfortably for about two seconds completes step 1.
3. One comfortable bend or straighten movement completes step 2 without any
   request for a maximum range.
4. The caregiver can review more bend/more straight and adjust sensitivity only
   between the measured noise floor and observed comfortable movement.
5. A tiny or noisy attempt offers a neutral retry; manual review appears only
   when the observed movement is still above measured noise.
6. Removing the hand during either measurement clears partial samples and says
   tracking paused without implying failure by the child.
7. Completing review reports that the calibration is not saved and clears when
   the screen is closed.
8. Rotating, backgrounding and resuming safely restarts camera tracking.

This is a control calibration, not a clinical goniometer. The UI uses `~` and
rounded values to avoid implying clinical or millimeter precision.

Useful debugger breakpoints are `IndexFingerMovementAnalyzer.analyze` for each
accepted sample, `BaselineCalibrationSession.accept` for rest measurement,
`ComfortableMovementCalibrationSession.accept` for movement separation,
`CalibrationProfileEditor.validate` for caregiver settings and
`MotionInputController.accept` for controller events.

Android release lint with Android Gradle Plugin 9.3 requires a JDK 21 runtime;
debug builds work with the Android Studio JDK 17 bundled on the development
machine.
