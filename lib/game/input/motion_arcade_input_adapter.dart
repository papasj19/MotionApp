import '../../input_controller/motion_input_controller.dart';
import 'arcade_input.dart';

/// Converts the universal Stage 6 motion events into game actions.
///
/// Only the one-shot primary event is forwarded. Action-down, action-up, and
/// tracking state events remain controller concerns and cannot create extra
/// game actions.
class MotionArcadeInputAdapter {
  const MotionArcadeInputAdapter({required this.arcadeInput});

  final ArcadeInputController arcadeInput;

  void accept(MotionInputEvent event) {
    if (event.type != MotionInputEventType.primaryAction) {
      return;
    }
    arcadeInput.triggerPrimaryAction(
      source: ArcadeInputSource.motion,
      timestamp: event.timestamp,
    );
  }

  void acceptAll(Iterable<MotionInputEvent> events) {
    for (final event in events) {
      accept(event);
    }
  }
}
