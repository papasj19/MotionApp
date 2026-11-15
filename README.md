# Adaptive Motion Arcade

Adaptive Motion Arcade is an accessible Flutter application for iOS and
Android. Its goal is to turn a child's comfortable hand or finger movement into
a simple, reusable game control.

## Current scope

Stage 3 adds on-device, single-hand landmark tracking to the front-camera
preview. The screen draws the standard 21-point hand skeleton, clearly reports
when no hand is detected, and shows a small live frame-rate and processing-
latency diagnostic.

The app does not yet recognize gestures, measure movement, calibrate a range of
motion, create a controller signal, run a game, or save a profile. Those remain
separate later stages.

## Architecture

The processing path is intentionally split at technology boundaries:

```text
camera frames -> MediaPipe adapter -> HandObservation -> preview overlay
                                      |
                                      +-> later movement and control stages
```

`HandObservation` is an app-owned type containing a timestamp, 21 normalized
landmarks, source dimensions, orientation and mirroring metadata. MediaPipe
types remain inside the adapter, so later motion logic can be pure Dart and can
be tested without a camera or child participant.

The live-stream task processes one frame while retaining only the newest
waiting frame. Frames it replaces are counted and never converted, preventing
an inference backlog. YUV conversion runs outside the UI isolate. A missing or
stale result removes the skeleton instead of freezing the last detected hand.

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

On the hand-tracking screen, check that:

1. `Show one hand` changes to `Hand detected` when one hand is visible.
2. All 21 points and connecting lines follow the mirrored front-camera image.
3. Removing the hand clears the skeleton promptly.
4. Portrait and both landscape orientations keep the preview and skeleton
   aligned after the camera restarts.
5. Backgrounding and resuming the app restarts camera and tracking safely.

Android release lint with Android Gradle Plugin 9.3 requires a JDK 21 runtime;
debug builds work with the Android Studio JDK 17 bundled on the development
machine.
