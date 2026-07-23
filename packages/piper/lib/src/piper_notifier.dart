import 'notification_batch.dart';
import 'tracking.dart';

/// A lightweight change notifier for reactive state management.
///
/// Pure Dart implementation with no Flutter dependency, enabling
/// usage and testing in any Dart environment.
///
/// Notifies listeners when [value] changes.
///
/// Example:
/// ```dart
/// final notifier = PiperNotifier(0);
/// notifier.addListener(() => print('Changed to ${notifier.value}'));
/// notifier.value = 1; // Prints: Changed to 1
/// ```
class PiperNotifier<T> {
  final List<void Function()> _listeners = [];
  final bool Function(T a, T b)? _equals;
  T _value;

  /// Creates a [PiperNotifier] with the given initial value.
  ///
  /// [equals] customizes change detection. Defaults to `==`. Provide a
  /// structural comparison (e.g. `listEquals`) for values that allocate a new
  /// instance on every update, such as a freshly-mapped list.
  PiperNotifier(this._value, {bool Function(T a, T b)? equals})
      : _equals = equals;

  /// The current value.
  T get value => _value;

  /// Sets a new value and notifies listeners if it changed.
  set value(T newValue) {
    if (PiperTracker.isTracking) {
      throw StateError(
        'State was written during a tracked build or computed(). '
        'Reads are tracked here; writes are not allowed. Move the write out '
        'of the Watch builder or computed function.',
      );
    }
    final unchanged = _equals?.call(_value, newValue) ?? (_value == newValue);
    if (unchanged) return;
    _value = newValue;
    PiperNotificationBatch.notify(_listeners);
  }

  /// Adds a listener that will be called when the value changes.
  void addListener(void Function() listener) => _listeners.add(listener);

  /// Removes a previously added listener.
  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// Disposes this notifier by clearing all listeners.
  void dispose() => _listeners.clear();
}
