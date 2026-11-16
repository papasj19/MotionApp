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
      expect(
        () => MotionInputControllerConfig(
          activationThreshold: 10,
          releaseThreshold: 4,
          cooldown: const Duration(milliseconds: -1),
        ),
        throwsArgumentError,
      );
      expect(
        () => MotionInputControllerConfig(
          activationThreshold: 10,
          releaseThreshold: 4,
          maximumTrackingGap: Duration.zero,
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

    test('tracking loss safely releases a held action', () {
      controller.accept(signal: 12, timestamp: Duration.zero);

      final events = controller.markTrackingLost(
        timestamp: const Duration(milliseconds: 100),
      );

      expect(events.map((event) => event.type), [
        MotionInputEventType.actionUp,
        MotionInputEventType.trackingLost,
      ]);
      expect(controller.state, MotionActionState.released);
      expect(controller.trackingState, MotionTrackingState.lost);
    });

    test('recovery cannot create a phantom action', () {
      controller.accept(signal: 12, timestamp: Duration.zero);
      controller.markTrackingLost(timestamp: const Duration(milliseconds: 100));

      final recoveredHigh = controller.accept(
        signal: 12,
        timestamp: const Duration(milliseconds: 200),
      );
      final stillHigh = controller.accept(
        signal: 12,
        timestamp: const Duration(milliseconds: 300),
      );
      final released = controller.accept(
        signal: 3,
        timestamp: const Duration(milliseconds: 400),
      );
      final deliberateActivation = controller.accept(
        signal: 12,
        timestamp: const Duration(milliseconds: 500),
      );

      expect(recoveredHigh.map((event) => event.type), [
        MotionInputEventType.trackingRecovered,
      ]);
      expect(stillHigh, isEmpty);
      expect(released, isEmpty);
      expect(deliberateActivation.map((event) => event.type), [
        MotionInputEventType.actionDown,
        MotionInputEventType.primaryAction,
      ]);
    });

    test('stale tracking safely releases after the configured gap', () {
      controller.accept(signal: 12, timestamp: Duration.zero);

      final stillCurrent = controller.checkForStaleTracking(
        timestamp: const Duration(milliseconds: 500),
      );
      final stale = controller.checkForStaleTracking(
        timestamp: const Duration(milliseconds: 501),
      );

      expect(stillCurrent, isEmpty);
      expect(stale.map((event) => event.type), [
        MotionInputEventType.actionUp,
        MotionInputEventType.trackingLost,
      ]);
      expect(controller.isPressed, isFalse);
    });

    test('a long sample gap reports loss and recovery without activation', () {
      controller.accept(signal: 12, timestamp: Duration.zero);

      final afterGap = controller.accept(
        signal: 3,
        timestamp: const Duration(milliseconds: 600),
      );

      expect(afterGap.map((event) => event.type), [
        MotionInputEventType.actionUp,
        MotionInputEventType.trackingLost,
        MotionInputEventType.trackingRecovered,
      ]);
      expect(controller.trackingState, MotionTrackingState.available);
      expect(controller.isPressed, isFalse);
    });

    test('ignores out-of-order timestamps without changing state', () {
      controller.accept(
        signal: 12,
        timestamp: const Duration(milliseconds: 100),
      );

      final delayed = controller.accept(
        signal: 0,
        timestamp: const Duration(milliseconds: 50),
      );

      expect(delayed, isEmpty);
      expect(controller.isPressed, isTrue);
    });

    test('cooldown rejects a rapid action without delaying it', () {
      controller = MotionInputController(
        config: MotionInputControllerConfig(
          activationThreshold: 10,
          releaseThreshold: 4,
          cooldown: const Duration(milliseconds: 500),
        ),
      );
      controller.accept(signal: 12, timestamp: Duration.zero);
      controller.accept(
        signal: 3,
        timestamp: const Duration(milliseconds: 100),
      );

      final tooSoon = controller.accept(
        signal: 12,
        timestamp: const Duration(milliseconds: 200),
      );
      final heldPastCooldown = controller.accept(
        signal: 12,
        timestamp: const Duration(milliseconds: 600),
      );
      controller.accept(
        signal: 3,
        timestamp: const Duration(milliseconds: 700),
      );
      final nextDeliberateAction = controller.accept(
        signal: 12,
        timestamp: const Duration(milliseconds: 800),
      );

      expect(tooSoon, isEmpty);
      expect(heldPastCooldown, isEmpty);
      expect(nextDeliberateAction.map((event) => event.type), [
        MotionInputEventType.actionDown,
        MotionInputEventType.primaryAction,
      ]);
    });
  });
}
