import 'package:adaptive_motion_arcade/game/flap_to_fly_mechanics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlapToFlyMechanics', () {
    test('starts only after a flap and applies gravity', () {
      final mechanics = FlapToFlyMechanics();
      final startingY = mechanics.flyerY;

      mechanics.update(1);
      expect(mechanics.status, FlapToFlyRunStatus.ready);
      expect(mechanics.flyerY, startingY);

      mechanics.flap();
      mechanics.update(0.1);

      expect(mechanics.status, FlapToFlyRunStatus.running);
      expect(mechanics.flyerY, lessThan(startingY));
      expect(mechanics.velocityY, greaterThan(mechanics.config.flapVelocity));
    });

    test('scores each cleared obstacle exactly once', () {
      final mechanics = FlapToFlyMechanics(config: _safeScoringConfig);

      mechanics.flap();
      mechanics.update(1.7);
      expect(mechanics.score, 1);

      mechanics.update(0.5);
      expect(mechanics.score, 1);
      expect(mechanics.status, FlapToFlyRunStatus.running);
    });

    test('detects an obstacle crossed during one large update', () {
      final mechanics = FlapToFlyMechanics(
        config: _safeScoringConfig.copyWith(
          initialFlyerY: 230,
          flapVelocity: -1,
          obstacleSpeed: 100,
          obstacleGapHeight: 100,
          gapPattern: const [0],
        ),
      );

      mechanics.flap();
      mechanics.update(1);

      expect(mechanics.status, FlapToFlyRunStatus.gameOver);
      expect(mechanics.score, 0);
    });

    test('world edges end the run', () {
      final mechanics = FlapToFlyMechanics(
        config: _safeScoringConfig.copyWith(
          initialFlyerY: 50,
          flapVelocity: -100,
          initialObstacleX: 1000,
        ),
      );

      mechanics.flap();
      mechanics.update(1);

      expect(mechanics.status, FlapToFlyRunStatus.gameOver);
    });

    test('restart restores the identical initial course and run state', () {
      final mechanics = FlapToFlyMechanics(config: _safeScoringConfig);
      final initialObstacles = mechanics.obstacles;

      mechanics.flap();
      mechanics.update(1.7);
      expect(mechanics.score, 1);

      mechanics.restart();

      expect(mechanics.status, FlapToFlyRunStatus.ready);
      expect(mechanics.score, 0);
      expect(mechanics.flyerY, _safeScoringConfig.initialFlyerY);
      expect(mechanics.velocityY, 0);
      _expectSameObstacles(mechanics.obstacles, initialObstacles);
    });

    test('the same timed inputs reproduce the same run', () {
      final first = FlapToFlyMechanics(config: _safeScoringConfig);
      final second = FlapToFlyMechanics(config: _safeScoringConfig);

      first.flap();
      second.flap();
      first.update(0.4);
      for (var i = 0; i < 40; i += 1) {
        second.update(0.01);
      }
      first.flap();
      second.flap();
      first.update(0.6);
      for (var i = 0; i < 60; i += 1) {
        second.update(0.01);
      }

      expect(first.status, second.status);
      expect(first.score, second.score);
      expect(first.flyerY, closeTo(second.flyerY, 1e-9));
      expect(first.velocityY, closeTo(second.velocityY, 1e-9));
      _expectSameObstacles(first.obstacles, second.obstacles);
    });

    test('ignores further flaps and updates after collision', () {
      final mechanics = FlapToFlyMechanics(
        config: _safeScoringConfig.copyWith(
          initialFlyerY: 50,
          flapVelocity: -100,
          initialObstacleX: 1000,
        ),
      );
      mechanics.flap();
      mechanics.update(1);
      final stoppedY = mechanics.flyerY;

      mechanics.flap();
      mechanics.update(2);

      expect(mechanics.status, FlapToFlyRunStatus.gameOver);
      expect(mechanics.flyerY, stoppedY);
      expect(mechanics.score, 0);
    });

    test('rejects unsafe tuning values', () {
      expect(
        () => FlapToFlyMechanics(
          config: _safeScoringConfig.copyWith(gapPattern: const []),
        ),
        throwsArgumentError,
      );
      expect(
        () => FlapToFlyMechanics(
          config: _safeScoringConfig.copyWith(obstacleGapHeight: 15),
        ),
        throwsArgumentError,
      );
      expect(
        () => FlapToFlyMechanics(
          config: _safeScoringConfig.copyWith(obstacleSpacing: 20),
        ),
        throwsArgumentError,
      );
    });
  });
}

const _safeScoringConfig = FlapToFlyConfig(
  worldWidth: 400,
  worldHeight: 300,
  flyerX: 80,
  initialFlyerY: 150,
  flyerWidth: 20,
  flyerHeight: 20,
  gravity: 0,
  flapVelocity: -1,
  obstacleWidth: 20,
  obstacleSpeed: 50,
  obstacleGapHeight: 200,
  obstacleSpacing: 180,
  initialObstacleX: 130,
  safeMargin: 10,
  initialObstacleCount: 2,
  simulationStep: 0.01,
  gapPattern: [0.5],
);

void _expectSameObstacles(
  List<FlapToFlyObstacle> actual,
  List<FlapToFlyObstacle> expected,
) {
  expect(actual, hasLength(expected.length));
  for (var i = 0; i < actual.length; i += 1) {
    expect(actual[i].id, expected[i].id);
    expect(actual[i].x, closeTo(expected[i].x, 1e-9));
    expect(actual[i].gapCenterY, closeTo(expected[i].gapCenterY, 1e-9));
    expect(actual[i].scored, expected[i].scored);
  }
}

extension on FlapToFlyConfig {
  FlapToFlyConfig copyWith({
    double? initialFlyerY,
    double? flapVelocity,
    double? obstacleSpeed,
    double? obstacleGapHeight,
    double? obstacleSpacing,
    double? initialObstacleX,
    List<double>? gapPattern,
  }) {
    return FlapToFlyConfig(
      worldWidth: worldWidth,
      worldHeight: worldHeight,
      flyerX: flyerX,
      initialFlyerY: initialFlyerY ?? this.initialFlyerY,
      flyerWidth: flyerWidth,
      flyerHeight: flyerHeight,
      gravity: gravity,
      flapVelocity: flapVelocity ?? this.flapVelocity,
      obstacleWidth: obstacleWidth,
      obstacleSpeed: obstacleSpeed ?? this.obstacleSpeed,
      obstacleGapHeight: obstacleGapHeight ?? this.obstacleGapHeight,
      obstacleSpacing: obstacleSpacing ?? this.obstacleSpacing,
      initialObstacleX: initialObstacleX ?? this.initialObstacleX,
      safeMargin: safeMargin,
      initialObstacleCount: initialObstacleCount,
      simulationStep: simulationStep,
      gapPattern: gapPattern ?? this.gapPattern,
    );
  }
}
