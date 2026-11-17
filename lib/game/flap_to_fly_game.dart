import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import 'input/arcade_input.dart';

class FlapToFlyGameState extends ChangeNotifier {
  int _actionCount = 0;
  bool _paused = false;
  ArcadeInputSource? _lastInputSource;

  int get actionCount => _actionCount;
  bool get paused => _paused;
  ArcadeInputSource? get lastInputSource => _lastInputSource;

  void recordAction(ArcadeInputSource source) {
    _actionCount += 1;
    _lastInputSource = source;
    notifyListeners();
  }

  void setPaused(bool paused) {
    if (_paused == paused) {
      return;
    }
    _paused = paused;
    notifyListeners();
  }

  void reset() {
    _actionCount = 0;
    _lastInputSource = null;
    notifyListeners();
  }
}

/// Stage 9A Flame shell for the first one-action arcade game.
///
/// This class deliberately knows nothing about cameras, landmarks, movement
/// measurements, or calibration. Stage 9B will add deterministic flight and
/// obstacle mechanics behind the same [ArcadeInputController] boundary.
class FlapToFlyGame extends FlameGame with KeyboardEvents {
  FlapToFlyGame({
    required this.input,
    required this.gameState,
  });

  static const _background = Color(0xFF17102F);
  static const _deepViolet = Color(0xFF24134F);
  static const _royalPurple = Color(0xFF6E2CC8);
  static const _lavender = Color(0xFFB05AE8);
  static const _softPink = Color(0xFFF486B9);
  static const _electricCyan = Color(0xFF43DCEB);
  static const _warmCream = Color(0xFFFFE8CB);
  static const _arcadeYellow = Color(0xFFFFD15A);
  static const _pulseDuration = 0.24;

  final ArcadeInputController input;
  final FlapToFlyGameState gameState;

  double _pulseRemaining = 0;

  @override
  Color backgroundColor() => _background;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    input.addListener(_handleInput);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _pulseRemaining = math.max(0, _pulseRemaining - dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final width = size.x;
    final height = size.y;
    if (width <= 0 || height <= 0) {
      return;
    }

    _drawArcadeGrid(canvas, width, height);
    _drawStars(canvas, width, height);
    _drawFlightPath(canvas, width, height);
    _drawJoybitFlyer(canvas, width, height);
  }

  void pauseGame() {
    if (gameState.paused) {
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
    resumeEngine();
  }

  void restartGame() {
    _pulseRemaining = 0;
    gameState.reset();
    if (gameState.paused) {
      resumeGame();
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
    if (gameState.paused || event.action != ArcadeInputAction.primaryAction) {
      return;
    }
    _pulseRemaining = _pulseDuration;
    gameState.recordAction(event.source);
  }

  void _drawArcadeGrid(Canvas canvas, double width, double height) {
    final gridPaint = Paint()
      ..color = _royalPurple.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    const spacing = 24.0;
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
    ];
    for (final star in stars) {
      canvas.drawRect(
        Rect.fromCenter(center: star, width: 5, height: 5),
        starPaint,
      );
    }
  }

  void _drawFlightPath(Canvas canvas, double width, double height) {
    final pathPaint = Paint()
      ..color = _electricCyan.withValues(alpha: 0.75)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final y = height * 0.58;
    canvas.drawLine(
      Offset(width * 0.10, y),
      Offset(width * 0.90, y),
      pathPaint,
    );
  }

  void _drawJoybitFlyer(Canvas canvas, double width, double height) {
    final pulseProgress = _pulseRemaining / _pulseDuration;
    final lift = math.sin(pulseProgress * math.pi) * 28;
    final scale = math.max(0.72, math.min(width / 520, height / 320));
    canvas.save();
    canvas.translate(width * 0.5, height * 0.58 - lift);
    canvas.scale(scale, scale);

    final outlinePaint = Paint()..color = _deepViolet;
    final bodyPaint = Paint()..color = _lavender;
    final facePaint = Paint()..color = _warmCream;
    final wingPaint = Paint()..color = _softPink;
    final headsetPaint = Paint()..color = _electricCyan;

    canvas.drawRect(const Rect.fromLTWH(-58, -36, 116, 72), outlinePaint);
    canvas.drawRect(const Rect.fromLTWH(-50, -30, 100, 60), bodyPaint);
    canvas.drawRect(const Rect.fromLTWH(4, -22, 38, 44), facePaint);
    canvas.drawRect(const Rect.fromLTWH(-74, -15, 24, 30), wingPaint);
    canvas.drawRect(const Rect.fromLTWH(50, -15, 24, 30), wingPaint);
    canvas.drawRect(const Rect.fromLTWH(-36, -43, 72, 9), headsetPaint);
    canvas.drawRect(const Rect.fromLTWH(-47, -34, 10, 28), headsetPaint);
    canvas.drawRect(const Rect.fromLTWH(37, -34, 10, 28), headsetPaint);
    canvas.drawRect(const Rect.fromLTWH(15, -10, 7, 7), outlinePaint);
    canvas.drawRect(const Rect.fromLTWH(32, -10, 7, 7), outlinePaint);
    canvas.drawRect(const Rect.fromLTWH(42, 4, 8, 8), outlinePaint);

    canvas.restore();
  }
}
