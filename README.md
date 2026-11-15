# Adaptive Motion Arcade

Adaptive Motion Arcade is an accessible Flutter application for iOS and
Android. Its goal is to turn a child's comfortable hand or finger movement into
a simple, reusable game control.

## Current scope

Stage 4 adds pure-Dart index-finger movement analysis to the on-device hand
tracking preview. The screen now shows an estimated flexion angle and whether
the finger is steady, bending or straightening. The existing 21-point skeleton,
frame-rate and processing-latency diagnostics remain visible.

The app does not yet calibrate a personal range of motion, create a controller
signal, recognize a game gesture, run a game, or save a profile. Those remain
separate later stages.

## Architecture

The processing path is intentionally split at technology boundaries:

```text
camera frames -> MediaPipe adapter -> HandObservation -> skeleton overlay
                                      |
                                      +-> finger movement analyzer
                                                    |
                                                    +-> diagnostic card
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

```sh
flutter pub get
dart run mediapipe_core:bundle_models --check
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter devices
flutter run -d <device-id>
```

On the movement diagnostic screen, check that:

1. A mostly straight index finger reads near `0°`.
2. Bending the index PIP joint increases the approximate angle and shows
   `Bending`; reversing direction shows `Straightening`.
3. Holding still settles on `Steady` without hiding small angle changes.
4. Removing the hand clears both the skeleton and number promptly; reacquiring
   it starts from the current position without a jump from the old value.
5. Mirroring and phone orientation do not change the angle for the same pose.
6. Backgrounding and resuming the app restarts the diagnostic safely.

This is a motion diagnostic, not a clinical goniometer. The UI rounds the
estimate to whole degrees and prefixes it with `~` to avoid implying clinical
or millimeter precision.

Useful debugger breakpoints are `IndexFingerMovementAnalyzer.analyze` for each
accepted sample, `_analyzeGeometry` for joint validity, and
`CameraScreen._movementReadingFor` where tracking state becomes a diagnostic
state.

Android release lint with Android Gradle Plugin 9.3 requires a JDK 21 runtime;
debug builds work with the Android Studio JDK 17 bundled on the development
machine.
