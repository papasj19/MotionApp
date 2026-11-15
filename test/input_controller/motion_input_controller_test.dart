import 'package:adaptive_motion_arcade/input_controller/motion_input_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MotionInputControllerConfig', () {
    test('rejects invalid hysteresis thresholds', () {
      expect(
        () => MotionInputControllerConfig(
          activationThreshold: 0,
          releaseThreshold: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => MotionInputControllerConfig(
          activationThreshold: 10,
          releaseThreshold: -1,
        ),
        throwsArgumentError,
      );
      expect(
        () => MotionInputControllerConfig(
          activationThreshold: 10,
          releaseThreshold: 10,
        ),
        throwsArgumentError,
      );
      expect(
        () => MotionInputControllerConfig(
          activationThreshold: double.nan,
          releaseThreshold: 4,
        ),
        throwsArgumentError,
      );
    });
  });

  group('MotionInputController', () {
    late MotionInputController controller;

    setUp(() {
      controller = MotionInputController(
        config: MotionInputControllerConfig(
          activationThreshold: 10,
          releaseThreshold: 4,
        ),
      );
    });

    test('emits action down then one primary action at activation', () {
      final belowThreshold = controller.accept(
        signal: 9.9,
        timestamp: const Duration(milliseconds: 100),
      );
      final activated = controller.accept(
        signal: 10,
        timestamp: const Duration(milliseconds: 200),
      );
      final held = controller.accept(
        signal: 15,
        timestamp: const Duration(milliseconds: 300),
      );

      expect(belowThreshold, isEmpty);
      expect(activated.map((event) => event.type), [
        MotionInputEventType.actionDown,
        MotionInputEventType.primaryAction,
      ]);
      expect(
        activated.map((event) => event.timestamp),
        everyElement(const Duration(milliseconds: 200)),
      );
      expect(held, isEmpty);
      expect(controller.isPressed, isTrue);
    });

    test('stays pressed inside the hysteresis band', () {
      controller.accept(signal: 12, timestamp: Duration.zero);

      final firstJitter = controller.accept(
        signal: 9,
        timestamp: const Duration(milliseconds: 10),
      );
      final secondJitter = controller.accept(
        signal: 4.1,
        timestamp: const Duration(milliseconds: 20),
      );

      expect(firstJitter, isEmpty);
      expect(secondJitter, isEmpty);
      expect(controller.state, MotionActionState.pressed);
    });

    test('releases and rearms before another activation', () {
      controller.accept(signal: 12, timestamp: Duration.zero);

      final released = controller.accept(
        signal: 4,
        timestamp: const Duration(milliseconds: 100),
      );
      final reactivated = controller.accept(
        signal: 11,
        timestamp: const Duration(milliseconds: 200),
      );

      expect(released.map((event) => event.type), [
        MotionInputEventType.actionUp,
      ]);
      expect(reactivated.map((event) => event.type), [
        MotionInputEventType.actionDown,
        MotionInputEventType.primaryAction,
      ]);
      expect(controller.state, MotionActionState.pressed);
    });

    test('rejects a nonfinite movement signal', () {
      expect(
        () => controller.accept(
          signal: double.infinity,
          timestamp: Duration.zero,
        ),
        throwsArgumentError,
      );
      expect(controller.state, MotionActionState.released);
    });
  });
}
