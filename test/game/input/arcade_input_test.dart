import 'package:adaptive_motion_arcade/game/input/arcade_input.dart';
import 'package:adaptive_motion_arcade/game/input/motion_arcade_input_adapter.dart';
import 'package:adaptive_motion_arcade/input_controller/motion_input_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('motion adapter forwards only one-shot primary actions', () {
    final input = ArcadeInputController();
    final adapter = MotionArcadeInputAdapter(arcadeInput: input);
    final received = <ArcadeInputEvent>[];
    input.addListener(received.add);

    adapter.acceptAll([
      const MotionInputEvent(
        type: MotionInputEventType.actionDown,
        timestamp: Duration(milliseconds: 100),
      ),
      const MotionInputEvent(
        type: MotionInputEventType.primaryAction,
        timestamp: Duration(milliseconds: 100),
      ),
      const MotionInputEvent(
        type: MotionInputEventType.actionUp,
        timestamp: Duration(milliseconds: 200),
      ),
      const MotionInputEvent(
        type: MotionInputEventType.trackingLost,
        timestamp: Duration(milliseconds: 300),
      ),
      const MotionInputEvent(
        type: MotionInputEventType.trackingRecovered,
        timestamp: Duration(milliseconds: 400),
      ),
    ]);

    expect(received, hasLength(1));
    expect(received.single.action, ArcadeInputAction.primaryAction);
    expect(received.single.source, ArcadeInputSource.motion);
    expect(received.single.timestamp, const Duration(milliseconds: 100));
  });

  test('touch and keyboard use the same game action boundary', () {
    final input = ArcadeInputController();
    final received = <ArcadeInputEvent>[];
    input.addListener(received.add);

    input.triggerPrimaryAction(
      source: ArcadeInputSource.touch,
      timestamp: const Duration(milliseconds: 10),
    );
    input.triggerPrimaryAction(
      source: ArcadeInputSource.keyboard,
      timestamp: const Duration(milliseconds: 20),
    );

    expect(
      received.map((event) => event.action),
      everyElement(ArcadeInputAction.primaryAction),
    );
    expect(
      received.map((event) => event.source),
      [ArcadeInputSource.touch, ArcadeInputSource.keyboard],
    );
  });

  test('disposed input controller no longer publishes actions', () {
    final input = ArcadeInputController();
    var actionCount = 0;
    input.addListener((_) => actionCount += 1);

    input.dispose();
    input.triggerPrimaryAction(
      source: ArcadeInputSource.touch,
      timestamp: Duration.zero,
    );

    expect(actionCount, 0);
    expect(() => input.addListener((_) {}), throwsStateError);
  });
}
