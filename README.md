# Adaptive Motion Arcade

Adaptive Motion Arcade is an accessible Flutter application for iOS and
Android. Its goal is to turn a child's comfortable hand or finger movement into
a simple, reusable game control.

## Current scope

Stage 2 adds an accessible front-camera preview to the mobile scaffold. It
selects the front camera, requests camera-only permission, reports unavailable,
denied and restricted states, and releases the camera while the app is in the
background.

The preview does not capture images, record video, start an image stream or
perform hand tracking. Movement analysis, calibration, games, profiles,
persistence, Firebase and cloud services are deliberately absent.

## Planned architecture

Future stages will keep the processing flow separated:

```text
front camera -> hand observation -> movement measurement -> calibration
             -> universal control action -> diagnostic UI or future game
```

Camera setup is kept behind a small service so permission and device states can
be tested without hardware. Camera and future MediaPipe-specific types will
stop at their adapters. Movement, calibration and controller logic will be pure
Dart so it can be tested without a camera or child participant.

## Privacy and measurement

- Raw camera frames will not be recorded or uploaded by default.
- Audio is disabled and the app does not request microphone permission.
- Processing should remain on-device wherever possible.
- Hand landmarks are estimates and must not be presented as millimeter-accurate
  or clinical measurements.

## Platform baseline

- Android 9 (API 28) or newer.
- iOS 15 or newer.

These floors match the currently planned Google-published MediaPipe Flutter
runtime. That dependency is not included yet and will be verified again before
the hand-tracking stage.

## Run and validate

Use a supported Flutter SDK and a connected Android or iOS device, or an
installed simulator:

```sh
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter devices
flutter run -d <device-id>
```

Stage 2 was verified with Flutter 3.50.0, Dart 3.14.0 and `camera` 0.12.2. The
project requires Flutter 3.41 or newer. Android release lint with Android Gradle
Plugin 9.3 requires a JDK 21 runtime; debug builds work with the Android Studio
JDK 17 bundled on the development machine.

Useful camera breakpoints are `DeviceCameraService._initialize`,
`CameraScreen._initializeCamera` and
`CameraScreen.didChangeAppLifecycleState`. Android camera open/close events can
be inspected with `adb logcat` while backgrounding and resuming the app.
