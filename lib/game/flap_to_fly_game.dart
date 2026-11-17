import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import 'flap_to_fly_mechanics.dart';
import 'input/arcade_input.dart';

class FlapToFlyGameState extends ChangeNotifier {
  int _actionCount = 0;
  int _score = 0;
  bool _paused = false;
  bool _inputSuspended = false;
  FlapToFlyRunStatus _runStatus = FlapToFlyRunStatus.ready;
  ArcadeInputSource? _lastInputSource;

  int get actionCount => _actionCount;
  int get score => _score;
  bool get paused => _paused;
  bool get inputSuspended => _inputSuspended;
  FlapToFlyRunStatus get runStatus => _runStatus;
  ArcadeInputSource? get lastInputSource => _lastInputSource;

  void recordAction(
    ArcadeInputSource source,
    FlapToFlyMechanics mechanics,
  ) {
    _actionCount += 1;
    _lastInputSource = source;
    _score = mechanics.score;
    _runStatus = mechanics.status;
    notifyListeners();
  }

  void syncFrom(FlapToFlyMechanics mechanics) {
    if (_score == mechanics.score && _runStatus == mechanics.status) {
      return;
    }
    _score = mechanics.score;
    _runStatus = mechanics.status;
    notifyListeners();
  }

  void setPaused(bool paused) {
    if (_paused == paused) {
      return;
    }
    _paused = paused;
    notifyListeners();
  }

  void setInputSuspended(bool suspended) {
    if (_inputSuspended == suspended) {
      return;
    }
    _inputSuspended = suspended;
    notifyListeners();
  }

  void resetFrom(FlapToFlyMechanics mechanics) {
    _actionCount = 0;
    _lastInputSource = null;
    _score = mechanics.score;
    _runStatus = mechanics.status;
    notifyListeners();
  }
}

/// Camera-free Flame presentation for Sky Sprint.
///
/// Deterministic movement, collisions, scoring, and restart state live in
/// [FlapToFlyMechanics]. This class owns only the game loop, drawing, and the
/// shared [ArcadeInputController] boundary that Stage 9C can connect to motion.
class FlapToFlyGame extends FlameGame with KeyboardEvents {
  FlapToFlyGame({
    required this.input,
    required this.gameState,
    FlapToFlyMechanics? mechanics,
  }) : mechanics = mechanics ?? FlapToFlyMechanics();

  static const _background = Color(0xFF17102F);
  static const _deepViolet = Color(0xFF24134F);
  static const _royalPurple = Color(0xFF6E2CC8);
  static const _lavender = Color(0xFFB05AE8);
  static const _softPink = Color(0xFFF486B9);
  static const _electricCyan = Color(0xFF43DCEB);
  static const _warmCream = Color(0xFFFFE8CB);
  static const _arcadeYellow = Color(0xFFFFD15A);
  static const _pulseDuration = 0.18;

  final ArcadeInputController input;
  final FlapToFlyGameState gameState;
  final FlapToFlyMechanics mechanics;

  double _pulseRemaining = 0;

  @override
  Color backgroundColor() => _background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    input.addListener(_handleInput);
    gameState.syncFrom(mechanics);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseRemaining = math.max(0, _pulseRemaining - dt);
    mechanics.update(dt);
    gameState.syncFrom(mechanics);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final width = size.x;
    final height = size.y;
    if (width <= 0 || height <= 0) {
      return;
    }

    final config = mechanics.config;
    final worldScale = math.min(
      width / config.worldWidth,
      height / config.worldHeight,
    );
    final horizontalInset = (width - config.worldWidth * worldScale) / 2;
    final verticalInset = (height - config.worldHeight * worldScale) / 2;

    canvas.save();
    canvas.translate(horizontalInset, verticalInset);
    canvas.scale(worldScale, worldScale);
    _drawArcadeGrid(canvas, config.worldWidth, config.worldHeight);
    _drawStars(canvas, config.worldWidth, config.worldHeight);
    _drawObstacles(canvas);
    _drawJoybitFlyer(canvas);
    canvas.restore();
  }

  void pauseGame() {
    if (gameState.paused ||
        gameState.runStatus == FlapToFlyRunStatus.gameOver) {
      return;
    }
    gameState.setPaused(true);
    pauseEngine();
  }

  void resumeGame() {
    if (!gameState.paused) {
      return;
    }
    gameState.setPaused(false);
    if (!gameState.inputSuspended) {
      resumeEngine();
    }
  }

  void suspendForInput() {
    if (gameState.inputSuspended) {
      return;
    }
    gameState.setInputSuspended(true);
    pauseEngine();
  }

  void resumeAfterInput() {
    if (!gameState.inputSuspended) {
      return;
    }
    gameState.setInputSuspended(false);
    if (!gameState.paused) {
      resumeEngine();
    }
  }

  void restartGame() {
    if (gameState.paused) {
      resumeGame();
    }
    _pulseRemaining = 0;
    mechanics.restart();
    gameState.resetFrom(mechanics);
    if (gameState.inputSuspended) {
      pauseEngine();
    }
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    final isPrimaryKey = event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (event is KeyDownEvent && isPrimaryKey) {
      input.triggerPrimaryAction(
        source: ArcadeInputSource.keyboard,
        timestamp: event.timeStamp,
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  void onDispose() {
    input.removeListener(_handleInput);
    super.onDispose();
  }

  void _handleInput(ArcadeInputEvent event) {
    if (gameState.paused ||
        gameState.inputSuspended ||
        mechanics.status == FlapToFlyRunStatus.gameOver ||
        event.action != ArcadeInputAction.primaryAction) {
      return;
    }
    _pulseRemaining = _pulseDuration;
    mechanics.flap();
    gameState.recordAction(event.source, mechanics);
  }

  void _drawArcadeGrid(Canvas canvas, double width, double height) {
    final gridPaint = Paint()
      ..color = _royalPurple.withValues(alpha: 0.20)
      ..strokeWidth = 2;
    const spacing = 48.0;
    for (var x = 0.0; x <= width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }
    for (var y = 0.0; y <= height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }
  }

  void _drawStars(Canvas canvas, double width, double height) {
    final starPaint = Paint()..color = _arcadeYellow;
    final stars = <Offset>[
      Offset(width * 0.12, height * 0.18),
      Offset(width * 0.34, height * 0.10),
      Offset(width * 0.70, height * 0.20),
      Offset(width * 0.88, height * 0.12),
      Offset(width * 0.55, height * 0.82),
    ];
    for (final star in stars) {
      canvas.drawRect(
        Rect.fromCenter(center: star, width: 8, height: 8),
        starPaint,
      );
    }
  }

  void _drawObstacles(Canvas canvas) {
    final config = mechanics.config;
    final fillPaint = Paint()..color = _royalPurple;
    final capPaint = Paint()..color = _softPink;
    final outlinePaint = Paint()
      ..color = _electricCyan
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    for (final obstacle in mechanics.obstacles) {
      final gapTop = obstacle.gapCenterY - config.obstacleGapHeight / 2;
      final gapBottom = obstacle.gapCenterY + config.obstacleGapHeight / 2;
      final top = Rect.fromLTWH(
        obstacle.x,
        0,
        config.obstacleWidth,
        gapTop,
      );
      final bottom = Rect.fromLTWH(
        obstacle.x,
        gapBottom,
        config.obstacleWidth,
        config.worldHeight - gapBottom,
      );
      canvas.drawRect(top, fillPaint);
      canvas.drawRect(bottom, fillPaint);
      canvas.drawRect(top, outlinePaint);
      canvas.drawRect(bottom, outlinePaint);

      const capHeight = 24.0;
      final capInset = config.obstacleWidth * 0.12;
      canvas.drawRect(
        Rect.fromLTWH(
          obstacle.x - capInset,
          math.max(0, gapTop - capHeight),
          config.obstacleWidth + capInset * 2,
          capHeight,
        ),
        capPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          obstacle.x - capInset,
          gapBottom,
          config.obstacleWidth + capInset * 2,
          capHeight,
        ),
        capPaint,
      );
    }
  }

  void _drawJoybitFlyer(Canvas canvas) {
    final config = mechanics.config;
    final pulseProgress = _pulseRemaining / _pulseDuration;
    final wingLift = math.sin(pulseProgress * math.pi) * 8;
    final width = config.flyerWidth;
    final height = config.flyerHeight;

    canvas.save();
    canvas.translate(config.flyerX, mechanics.flyerY);

    final outlinePaint = Paint()..color = _deepViolet;
    final bodyPaint = Paint()..color = _lavender;
    final facePaint = Paint()..color = _warmCream;
    final wingPaint = Paint()..color = _softPink;
    final headsetPaint = Paint()..color = _electricCyan;

    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: width, height: height),
      outlinePaint,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset.zero,
        width: width - 10,
        height: height - 10,
      ),
      bodyPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, -height * 0.32, width * 0.34, height * 0.64),
      facePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(-width * 0.62, -10 - wingLift, width * 0.16, 22),
      wingPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(width * 0.46, -10 - wingLift, width * 0.16, 22),
      wingPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(-width * 0.28, -height * 0.65, width * 0.56, 8),
      headsetPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(width * 0.10, -7, 6, 6),
      outlinePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(width * 0.27, -7, 6, 6),
      outlinePaint,
    );
    canvas.restore();
  }
}
