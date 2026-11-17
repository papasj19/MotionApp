import 'dart:math' as math;

enum FlapToFlyRunStatus { ready, running, gameOver }

class FlapToFlyConfig {
  const FlapToFlyConfig({
    this.worldWidth = 1000,
    this.worldHeight = 600,
    this.flyerX = 220,
    this.initialFlyerY = 300,
    this.flyerWidth = 84,
    this.flyerHeight = 64,
    this.gravity = 760,
    this.flapVelocity = -310,
    this.obstacleWidth = 104,
    this.obstacleSpeed = 170,
    this.obstacleGapHeight = 245,
    this.obstacleSpacing = 430,
    this.initialObstacleX = 800,
    this.safeMargin = 44,
    this.initialObstacleCount = 3,
    this.simulationStep = 1 / 120,
    this.gapPattern = const [0.42, 0.60, 0.36, 0.55, 0.47],
  });

  final double worldWidth;
  final double worldHeight;
  final double flyerX;
  final double initialFlyerY;
  final double flyerWidth;
  final double flyerHeight;
  final double gravity;
  final double flapVelocity;
  final double obstacleWidth;
  final double obstacleSpeed;
  final double obstacleGapHeight;
  final double obstacleSpacing;
  final double initialObstacleX;
  final double safeMargin;
  final int initialObstacleCount;
  final double simulationStep;

  /// Repeatable vertical positions expressed from 0 (highest) to 1 (lowest).
  final List<double> gapPattern;

  void validate() {
    final positiveValues = <String, double>{
      'worldWidth': worldWidth,
      'worldHeight': worldHeight,
      'flyerWidth': flyerWidth,
      'flyerHeight': flyerHeight,
      'obstacleWidth': obstacleWidth,
      'obstacleSpeed': obstacleSpeed,
      'obstacleGapHeight': obstacleGapHeight,
      'obstacleSpacing': obstacleSpacing,
      'simulationStep': simulationStep,
    };
    for (final entry in positiveValues.entries) {
      if (!entry.value.isFinite || entry.value <= 0) {
        throw ArgumentError.value(entry.value, entry.key, 'Must be positive.');
      }
    }
    final finiteValues = <String, double>{
      'flyerX': flyerX,
      'initialFlyerY': initialFlyerY,
      'gravity': gravity,
      'flapVelocity': flapVelocity,
      'initialObstacleX': initialObstacleX,
      'safeMargin': safeMargin,
    };
    for (final entry in finiteValues.entries) {
      if (!entry.value.isFinite) {
        throw ArgumentError.value(entry.value, entry.key, 'Must be finite.');
      }
    }
    if (gravity < 0) {
      throw ArgumentError.value(gravity, 'gravity', 'Cannot be negative.');
    }
    if (flapVelocity >= 0) {
      throw ArgumentError.value(
        flapVelocity,
        'flapVelocity',
        'Must move the flyer upward.',
      );
    }
    if (safeMargin < 0 || obstacleGapHeight + (safeMargin * 2) >= worldHeight) {
      throw ArgumentError(
        'The obstacle gap and safe margins must fit inside the world.',
      );
    }
    if (obstacleGapHeight <= flyerHeight) {
      throw ArgumentError(
        'The obstacle gap must be larger than the flyer height.',
      );
    }
    if (obstacleSpacing <= obstacleWidth) {
      throw ArgumentError(
        'Obstacle spacing must be larger than obstacle width.',
      );
    }
    if (initialObstacleCount < 1) {
      throw ArgumentError.value(
        initialObstacleCount,
        'initialObstacleCount',
        'Must be at least one.',
      );
    }
    if (flyerX - flyerWidth / 2 <= 0 ||
        flyerX + flyerWidth / 2 >= worldWidth ||
        initialFlyerY - flyerHeight / 2 <= 0 ||
        initialFlyerY + flyerHeight / 2 >= worldHeight) {
      throw ArgumentError('The initial flyer rectangle must fit in the world.');
    }
    if (gapPattern.isEmpty ||
        gapPattern.any((value) => !value.isFinite || value < 0 || value > 1)) {
      throw ArgumentError.value(
        gapPattern,
        'gapPattern',
        'Use at least one finite value from 0 to 1.',
      );
    }
  }
}

class FlapToFlyObstacle {
  const FlapToFlyObstacle({
    required this.id,
    required this.x,
    required this.gapCenterY,
    required this.scored,
  });

  final int id;
  final double x;
  final double gapCenterY;
  final bool scored;
}

class FlapToFlyMechanics {
  FlapToFlyMechanics({this.config = const FlapToFlyConfig()}) {
    config.validate();
    restart();
  }

  final FlapToFlyConfig config;
  final List<_MutableObstacle> _obstacles = [];

  late double _flyerY;
  double _velocityY = 0;
  double _accumulator = 0;
  int _score = 0;
  int _nextObstacleId = 0;
  int _nextGapIndex = 0;
  FlapToFlyRunStatus _status = FlapToFlyRunStatus.ready;

  double get flyerY => _flyerY;
  double get velocityY => _velocityY;
  int get score => _score;
  FlapToFlyRunStatus get status => _status;
  List<FlapToFlyObstacle> get obstacles => List.unmodifiable(
        _obstacles.map(
          (obstacle) => FlapToFlyObstacle(
            id: obstacle.id,
            x: obstacle.x,
            gapCenterY: obstacle.gapCenterY,
            scored: obstacle.scored,
          ),
        ),
      );

  void flap() {
    if (_status == FlapToFlyRunStatus.gameOver) {
      return;
    }
    _status = FlapToFlyRunStatus.running;
    _velocityY = config.flapVelocity;
  }

  void update(double deltaSeconds) {
    if (!deltaSeconds.isFinite || deltaSeconds < 0) {
      throw ArgumentError.value(
        deltaSeconds,
        'deltaSeconds',
        'Must be finite and non-negative.',
      );
    }
    if (_status != FlapToFlyRunStatus.running || deltaSeconds == 0) {
      return;
    }

    _accumulator += deltaSeconds;
    while (_accumulator + 1e-12 >= config.simulationStep &&
        _status == FlapToFlyRunStatus.running) {
      _simulateStep(config.simulationStep);
      _accumulator = math.max(0, _accumulator - config.simulationStep);
    }
  }

  void restart() {
    _flyerY = config.initialFlyerY;
    _velocityY = 0;
    _accumulator = 0;
    _score = 0;
    _status = FlapToFlyRunStatus.ready;
    _nextObstacleId = 0;
    _nextGapIndex = 0;
    _obstacles
      ..clear()
      ..addAll(
        List.generate(
          config.initialObstacleCount,
          (index) => _createObstacle(
            config.initialObstacleX + (index * config.obstacleSpacing),
          ),
        ),
      );
  }

  void _simulateStep(double dt) {
    _velocityY += config.gravity * dt;
    _flyerY += _velocityY * dt;

    for (final obstacle in _obstacles) {
      obstacle.x -= config.obstacleSpeed * dt;
    }

    if (_hitsWorldEdge() || _hitsObstacle()) {
      _status = FlapToFlyRunStatus.gameOver;
      _accumulator = 0;
      return;
    }

    final flyerLeft = config.flyerX - config.flyerWidth / 2;
    for (final obstacle in _obstacles) {
      if (!obstacle.scored && obstacle.x + config.obstacleWidth < flyerLeft) {
        obstacle.scored = true;
        _score += 1;
      }
    }

    for (final obstacle in _obstacles) {
      if (obstacle.x + config.obstacleWidth < 0) {
        final furthestX = _obstacles
            .where((candidate) => !identical(candidate, obstacle))
            .fold<double>(
                0, (value, candidate) => math.max(value, candidate.x));
        final replacement = _createObstacle(furthestX + config.obstacleSpacing);
        obstacle
          ..id = replacement.id
          ..x = replacement.x
          ..gapCenterY = replacement.gapCenterY
          ..scored = false;
      }
    }
  }

  bool _hitsWorldEdge() {
    final halfHeight = config.flyerHeight / 2;
    return _flyerY - halfHeight <= 0 ||
        _flyerY + halfHeight >= config.worldHeight;
  }

  bool _hitsObstacle() {
    final flyerLeft = config.flyerX - config.flyerWidth / 2;
    final flyerRight = config.flyerX + config.flyerWidth / 2;
    final flyerTop = _flyerY - config.flyerHeight / 2;
    final flyerBottom = _flyerY + config.flyerHeight / 2;

    for (final obstacle in _obstacles) {
      final overlapsHorizontally =
          flyerLeft < obstacle.x + config.obstacleWidth &&
              flyerRight > obstacle.x;
      if (!overlapsHorizontally) {
        continue;
      }
      final gapTop = obstacle.gapCenterY - config.obstacleGapHeight / 2;
      final gapBottom = obstacle.gapCenterY + config.obstacleGapHeight / 2;
      if (flyerTop < gapTop || flyerBottom > gapBottom) {
        return true;
      }
    }
    return false;
  }

  _MutableObstacle _createObstacle(double x) {
    final fraction =
        config.gapPattern[_nextGapIndex % config.gapPattern.length];
    _nextGapIndex += 1;
    final availableTravel =
        config.worldHeight - (config.safeMargin * 2) - config.obstacleGapHeight;
    final highestCenter = config.safeMargin + config.obstacleGapHeight / 2;
    return _MutableObstacle(
      id: _nextObstacleId++,
      x: x,
      gapCenterY: highestCenter + (availableTravel * fraction),
    );
  }
}

class _MutableObstacle {
  _MutableObstacle({
    required this.id,
    required this.x,
    required this.gapCenterY,
  }) : scored = false;

  int id;
  double x;
  double gapCenterY;
  bool scored;
}
