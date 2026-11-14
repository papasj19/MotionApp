# Adaptive Motion Arcade

Adaptive Motion Arcade is an accessible Flutter application for iOS and
Android. Its goal is to turn a child's comfortable hand or finger movement into
a simple, reusable game control.

## Current scope

Stage 1 contains only the mobile application scaffold and one accessible home
screen. Camera access, hand tracking, movement analysis, calibration, games,
profiles, persistence, Firebase and cloud services are deliberately absent.

The home screen states this clearly so a development build cannot be mistaken
for a working tracking prototype.

## Planned architecture

Future stages will keep the processing flow separated:

```text
front camera -> hand observation -> movement measurement -> calibration
             -> universal control action -> diagnostic UI or future game
```

Camera and MediaPipe-specific types will stop at their adapters. Movement,
calibration and controller logic will be pure Dart so it can be tested without
a camera or child participant.

## Privacy and measurement

- Raw camera frames will not be recorded or uploaded by default.
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
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter devices
flutter run -d <device-id>
```

The project was initially scaffolded with Flutter 3.16.0 and Dart 3.2.0. Upgrade
the toolchain before Stage 2 so the current camera dependency can be evaluated;
Flutter 3.44 or newer is required before adding the currently planned MediaPipe
package.
