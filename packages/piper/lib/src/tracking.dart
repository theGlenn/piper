/// Anything a [Watch] or [Computed] can subscribe to automatically.
///
/// Implemented by [StateHolder] and [Computed]. When their value is read
/// inside a tracked scope, they register themselves with the active tracker.
abstract interface class Trackable {
  /// Adds a listener called when this value changes.
  void addListener(void Function() listener);

  /// Removes a previously added listener.
  void removeListener(void Function() listener);
}

/// Records which [Trackable]s are read during a scope.
///
/// This is the mechanism behind automatic dependency tracking: run a function
/// through [track], and every [Trackable.value] read inside it reports itself.
/// The `Watch` widget and [Computed] use this to subscribe to exactly the
/// state they read — no manual wiring.
class PiperTracker {
  PiperTracker._();

  static final List<void Function(Trackable)> _stack = [];

  /// Whether a tracked scope (a `Watch` build or a [Computed]) is active.
  static bool get isTracking => _stack.isNotEmpty;

  /// Reports that [source] was read. No-op outside a tracked scope.
  static void reportRead(Trackable source) {
    if (_stack.isNotEmpty) _stack.last(source);
  }

  /// Runs [body], calling [onRead] for each [Trackable] read inside it.
  static T track<T>(T Function() body, void Function(Trackable) onRead) {
    _stack.add(onRead);
    try {
      return body();
    } finally {
      _stack.removeLast();
    }
  }

  /// Runs [body] without tracking any reads.
  static T untracked<T>(T Function() body) {
    _stack.add((_) {});
    try {
      return body();
    } finally {
      _stack.removeLast();
    }
  }
}
