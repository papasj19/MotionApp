import 'dart:math' as math;

import 'package:adaptive_motion_arcade/hand_tracking/hand_observation.dart';
import 'package:adaptive_motion_arcade/movement/finger_movement_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects unsafe tuning values', () {
    expect(
      () => FingerMovementAnalyzerConfig(smoothingTimeConstant: Duration.zero),
      throwsArgumentError,
    );
    expect(
      () => FingerMovementAnalyzerConfig(
        motionDeadbandDegreesPerSecond: double.nan,
      ),
      throwsArgumentError,
    );
  });

  group('index-finger PIP flexion geometry', () {
    test('defines straight as 0 degrees and bend as positive degrees', () {
      final straightAnalyzer = IndexFingerMovementAnalyzer();
      final bentAnalyzer = IndexFingerMovementAnalyzer();

      final straight = straightAnalyzer.analyze(
        _observation(flexionDegrees: 0, timestamp: Duration.zero),
      );
      final bent = bentAnalyzer.analyze(
        _observation(flexionDegrees: 90, timestamp: Duration.zero),
      );

      expect(straight.isValid, isTrue);
      expect(straight.rawFlexionDegrees, closeTo(0, 1e-9));
      expect(straight.flexionDegrees, closeTo(0, 1e-9));
      expect(bent.rawFlexionDegrees, closeTo(90, 1e-9));
      expect(straight.units, 'degrees');
    });

    test('is invariant to front-camera mirroring', () {
      final rear = IndexFingerMovementAnalyzer().analyze(
        _observation(
          flexionDegrees: 63,
          timestamp: Duration.zero,
          mirrored: false,
        ),
      );
      final front = IndexFingerMovementAnalyzer().analyze(
        _observation(
          flexionDegrees: 63,
          timestamp: Duration.zero,
          mirrored: true,
        ),
      );

      expect(front.rawFlexionDegrees, closeTo(rear.rawFlexionDegrees!, 1e-9));
    });

    test('corrects normalized coordinates for image aspect ratio', () {
      final square = IndexFingerMovementAnalyzer().analyze(
        _observation(flexionDegrees: 48, timestamp: Duration.zero),
      );
      final wide = IndexFingerMovementAnalyzer().analyze(
        _observation(
          flexionDegrees: 48,
          timestamp: Duration.zero,
          imageWidth: 1000,
          imageHeight: 500,
        ),
      );

      expect(wide.rawFlexionDegrees, closeTo(square.rawFlexionDegrees!, 1e-9));
    });

    test('rejects nonfinite and zero-length joint geometry', () {
      final nonFinite = IndexFingerMovementAnalyzer().analyze(
        _observation(
          flexionDegrees: 30,
          timestamp: Duration.zero,
          nonFiniteMcp: true,
        ),
      );
      final degenerate = IndexFingerMovementAnalyzer().analyze(
        _observation(
          flexionDegrees: 30,
          timestamp: Duration.zero,
          degenerateJoint: true,
        ),
      );

      expect(nonFinite.validity, FingerMovementValidity.nonFiniteLandmarks);
      expect(degenerate.validity, FingerMovementValidity.degenerateGeometry);
      expect(nonFinite.flexionDegrees, isNull);
      expect(degenerate.flexionDegrees, isNull);
    });

    test('near-collinear vectors stay finite', () {
      final reading = IndexFingerMovementAnalyzer().analyze(
        _observation(flexionDegrees: 0.000001, timestamp: Duration.zero),
      );

      expect(reading.isValid, isTrue);
      expect(reading.flexionDegrees, isNotNaN);
      expect(reading.flexionDegrees!.isFinite, isTrue);
    });
  });

  group('timestamp-aware movement state', () {
    test('positive velocity is flexing and negative velocity is extending', () {
      final analyzer = IndexFingerMovementAnalyzer();
      analyzer.analyze(
        _observation(flexionDegrees: 0, timestamp: Duration.zero),
      );
      final flexing = analyzer.analyze(
        _observation(
          flexionDegrees: 90,
          timestamp: const Duration(milliseconds: 100),
        ),
      );
      final extending = analyzer.analyze(
        _observation(
          flexionDegrees: 0,
          timestamp: const Duration(milliseconds: 200),
        ),
      );

      expect(flexing.state, FingerMotionState.flexing);
      expect(flexing.velocityDegreesPerSecond, greaterThan(0));
      expect(extending.state, FingerMotionState.extending);
      expect(extending.velocityDegreesPerSecond, lessThan(0));
    });

    test('smoothing depends on elapsed time, not frame count', () {
      final once = IndexFingerMovementAnalyzer(
        config: FingerMovementAnalyzerConfig(
          smoothingTimeConstant: const Duration(milliseconds: 100),
        ),
      );
      final twice = IndexFingerMovementAnalyzer(
        config: FingerMovementAnalyzerConfig(
          smoothingTimeConstant: const Duration(milliseconds: 100),
        ),
      );
      once.analyze(_observation(flexionDegrees: 0, timestamp: Duration.zero));
      twice.analyze(_observation(flexionDegrees: 0, timestamp: Duration.zero));

      final oneStep = once.analyze(
        _observation(
          flexionDegrees: 90,
          timestamp: const Duration(milliseconds: 100),
        ),
      );
      twice.analyze(
        _observation(
          flexionDegrees: 90,
          timestamp: const Duration(milliseconds: 50),
        ),
      );
      final twoSteps = twice.analyze(
        _observation(
          flexionDegrees: 90,
          timestamp: const Duration(milliseconds: 100),
        ),
      );

      expect(twoSteps.flexionDegrees, closeTo(oneStep.flexionDegrees!, 1e-9));
    });

    test(
      'small noise stays steady while small, slow and fast moves survive',
      () {
        final config = FingerMovementAnalyzerConfig(
          smoothingTimeConstant: const Duration(milliseconds: 100),
          resetAfterGap: const Duration(seconds: 5),
          motionDeadbandDegreesPerSecond: 5,
        );
        final noisyAnalyzer = IndexFingerMovementAnalyzer(config: config);
        noisyAnalyzer.analyze(
          _observation(flexionDegrees: 0, timestamp: Duration.zero),
        );
        final noisy = noisyAnalyzer.analyze(
          _observation(
            flexionDegrees: 0.5,
            timestamp: const Duration(milliseconds: 100),
          ),
        );
        final small = noisyAnalyzer.analyze(
          _observation(
            flexionDegrees: 3,
            timestamp: const Duration(milliseconds: 300),
          ),
        );

        final slowAnalyzer = IndexFingerMovementAnalyzer(config: config);
        slowAnalyzer.analyze(
          _observation(flexionDegrees: 0, timestamp: Duration.zero),
        );
        final slow = slowAnalyzer.analyze(
          _observation(
            flexionDegrees: 20,
            timestamp: const Duration(seconds: 2),
          ),
        );

        final fastAnalyzer = IndexFingerMovementAnalyzer(config: config);
        fastAnalyzer.analyze(
          _observation(flexionDegrees: 0, timestamp: Duration.zero),
        );
        final fast = fastAnalyzer.analyze(
          _observation(
            flexionDegrees: 90,
            timestamp: const Duration(milliseconds: 100),
          ),
        );

        expect(noisy.state, FingerMotionState.stationary);
        expect(small.rawFlexionDegrees, closeTo(3, 1e-9));
        expect(small.state, FingerMotionState.flexing);
        expect(slow.state, FingerMotionState.flexing);
        expect(fast.state, FingerMotionState.flexing);
        expect(
          fast.velocityDegreesPerSecond,
          greaterThan(slow.velocityDegreesPerSecond!),
        );
      },
    );

    test('dropped frames use the longer interval without creating backlog', () {
      final analyzer = IndexFingerMovementAnalyzer();
      analyzer.analyze(
        _observation(flexionDegrees: 0, timestamp: Duration.zero),
      );
      final afterGap = analyzer.analyze(
        _observation(
          flexionDegrees: 90,
          timestamp: const Duration(milliseconds: 300),
        ),
      );

      expect(afterGap.isValid, isTrue);
      expect(
        afterGap.quality.sampleInterval,
        const Duration(milliseconds: 300),
      );
      expect(afterGap.quality.smoothingApplied, isTrue);
      expect(afterGap.flexionDegrees, inExclusiveRange(0, 90));
    });

    test('missing and long-gap observations restart without stale motion', () {
      final analyzer = IndexFingerMovementAnalyzer();
      analyzer.analyze(
        _observation(flexionDegrees: 10, timestamp: Duration.zero),
      );
      final missing = analyzer.markMissing(const Duration(milliseconds: 100));
      final reacquired = analyzer.analyze(
        _observation(
          flexionDegrees: 80,
          timestamp: const Duration(milliseconds: 200),
        ),
      );
      final longGap = analyzer.analyze(
        _observation(
          flexionDegrees: 25,
          timestamp: const Duration(milliseconds: 800),
        ),
      );

      expect(missing.validity, FingerMovementValidity.missingObservation);
      expect(missing.flexionDegrees, isNull);
      expect(reacquired.flexionDegrees, closeTo(80, 1e-9));
      expect(reacquired.velocityDegreesPerSecond, isNull);
      expect(reacquired.quality.reacquired, isTrue);
      expect(longGap.flexionDegrees, closeTo(25, 1e-9));
      expect(longGap.velocityDegreesPerSecond, isNull);
      expect(longGap.quality.reacquired, isTrue);
    });

    test('out-of-order samples are rejected without corrupting state', () {
      final analyzer = IndexFingerMovementAnalyzer();
      analyzer.analyze(
        _observation(
          flexionDegrees: 0,
          timestamp: const Duration(milliseconds: 100),
        ),
      );
      final old = analyzer.analyze(
        _observation(
          flexionDegrees: 90,
          timestamp: const Duration(milliseconds: 90),
        ),
      );
      final current = analyzer.analyze(
        _observation(
          flexionDegrees: 90,
          timestamp: const Duration(milliseconds: 200),
        ),
      );

      expect(old.validity, FingerMovementValidity.outOfOrderTimestamp);
      expect(current.isValid, isTrue);
      expect(current.state, FingerMotionState.flexing);
      expect(current.quality.sampleInterval, const Duration(milliseconds: 100));
    });
  });

  test(
    'uses reported landmark scores only when the detector supplies them',
    () {
      final withoutScores = IndexFingerMovementAnalyzer();
      withoutScores.analyze(
        _observation(flexionDegrees: 20, timestamp: Duration.zero),
      );
      final noScoreReading = withoutScores.analyze(
        _observation(
          flexionDegrees: 20,
          timestamp: const Duration(milliseconds: 100),
        ),
      );

      final lowScore = IndexFingerMovementAnalyzer();
      lowScore.analyze(
        _observation(
          flexionDegrees: 20,
          timestamp: Duration.zero,
          reportedScore: 0.1,
        ),
      );
      final lowScoreReading = lowScore.analyze(
        _observation(
          flexionDegrees: 20,
          timestamp: const Duration(milliseconds: 100),
          reportedScore: 0.1,
        ),
      );

      expect(noScoreReading.quality.minimumReportedLandmarkScore, isNull);
      expect(noScoreReading.quality.quality, MovementSignalQuality.good);
      expect(lowScoreReading.quality.minimumReportedLandmarkScore, 0.1);
      expect(lowScoreReading.quality.quality, MovementSignalQuality.caution);
    },
  );
}

HandObservation _observation({
  required double flexionDegrees,
  required Duration timestamp,
  bool mirrored = false,
  int imageWidth = 1000,
  int imageHeight = 1000,
  bool nonFiniteMcp = false,
  bool degenerateJoint = false,
  double? reportedScore,
}) {
  final yScale = imageHeight / imageWidth;
  final radians = flexionDegrees * math.pi / 180;
  const pip = (x: 0.5, y: 0.15);
  const mcp = (x: 0.4, y: 0.15);
  final dip = degenerateJoint
      ? pip
      : (
          x: pip.x + 0.1 * math.cos(radians),
          y: pip.y + 0.1 * math.sin(radians),
        );

  HandLandmark landmark((double, double) point) {
    final x = mirrored ? 1 - point.$1 : point.$1;
    return HandLandmark(
      x: x,
      y: point.$2 / yScale,
      z: 0,
      visibility: reportedScore,
      presence: reportedScore,
    );
  }

  final landmarks = List.generate(
    21,
    (_) => landmark((0.5, 0.2)),
    growable: false,
  );
  landmarks[IndexFingerMovementAnalyzer.wristIndex] = landmark((0.5, 0.4));
  landmarks[IndexFingerMovementAnalyzer.middleMcpIndex] = landmark((0.5, 0.25));
  landmarks[IndexFingerMovementAnalyzer.indexMcpIndex] = nonFiniteMcp
      ? HandLandmark(x: double.nan, y: mcp.y / yScale, z: 0)
      : landmark((mcp.x, mcp.y));
  landmarks[IndexFingerMovementAnalyzer.indexPipIndex] = landmark((
    pip.x,
    pip.y,
  ));
  landmarks[IndexFingerMovementAnalyzer.indexDipIndex] = landmark((
    dip.x,
    dip.y,
  ));

  return HandObservation(
    timestamp: timestamp,
    landmarks: landmarks,
    imageWidth: imageWidth,
    imageHeight: imageHeight,
    rotationDegrees: 0,
    isMirrored: mirrored,
    handedness: Handedness.unknown,
  );
}
