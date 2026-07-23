import 'piper_notifier.dart';
import 'tracking.dart';

/// Synchronous state container with change notification support.
///
/// Wraps [PiperNotifier] to provide a simple interface for managing
/// state with automatic listener notification.
///
/// Example:
/// ```dart
/// final counter = StateHolder(0);
/// counter.value = 1;
/// counter.update((current) => current + 1);
/// ```
class StateHolder<T> implements Trackable {
  final PiperNotifier<T> _notifier;

  /// Creates a [StateHolder] with the given initial value.
  ///
  /// [equals] customizes change detection (defaults to `==`).
  StateHolder(T initial, {bool Function(T a, T b)? equals})
      : _notifier = PiperNotifier(initial, equals: equals);

  /// The current value.
  ///
  /// Reading this inside a `Watch` or [Computed] automatically subscribes
  /// the reader to future changes.
  T get value {
    PiperTracker.reportRead(this);
    return _notifier.value;
  }

  /// Sets a new value, notifying listeners if it changed.
  set value(T val) => _notifier.value = val;

  /// Updates the value using a transformation function.
  ///
  /// Useful for updates that depend on the current value.
  void update(T Function(T current) updater) {
    _notifier.value = updater(_notifier.value);
  }

  /// The underlying [PiperNotifier] for adding listeners.
  PiperNotifier<T> get notifier => _notifier;

  /// Disposes the underlying notifier.
  ///
  /// After calling dispose, this [StateHolder] should not be used.
  void dispose() => _notifier.dispose();

  /// Adds a listener that will be called when the value changes.
  @override
  void addListener(void Function() listener) => _notifier.addListener(listener);

  /// Removes a previously added listener.
  @override
  void removeListener(void Function() listener) =>
      _notifier.removeListener(listener);
}
