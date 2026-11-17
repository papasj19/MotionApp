enum ArcadeInputAction { primaryAction }

enum ArcadeInputSource { motion, touch, keyboard }

class ArcadeInputEvent {
  const ArcadeInputEvent({
    required this.action,
    required this.source,
    required this.timestamp,
  });

  final ArcadeInputAction action;
  final ArcadeInputSource source;
  final Duration timestamp;
}

typedef ArcadeInputListener = void Function(ArcadeInputEvent event);

/// A camera-free input boundary shared by every arcade game.
///
/// Games listen only for arcade actions. Motion, touch, and keyboard adapters
/// decide how their source becomes an action before it reaches this class.
class ArcadeInputController {
  final Set<ArcadeInputListener> _listeners = {};
  bool _disposed = false;

  void addListener(ArcadeInputListener listener) {
    if (_disposed) {
      throw StateError('Cannot listen to a disposed arcade input controller.');
    }
    _listeners.add(listener);
  }

  void removeListener(ArcadeInputListener listener) {
    _listeners.remove(listener);
  }

  void triggerPrimaryAction({
    required ArcadeInputSource source,
    required Duration timestamp,
  }) {
    if (_disposed) {
      return;
    }
    final event = ArcadeInputEvent(
      action: ArcadeInputAction.primaryAction,
      source: source,
      timestamp: timestamp,
    );
    for (final listener in List<ArcadeInputListener>.of(_listeners)) {
      listener(event);
    }
  }

  void dispose() {
    _disposed = true;
    _listeners.clear();
  }
}
