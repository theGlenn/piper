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
  T _value;

  /// Creates a [PiperNotifier] with the given initial value.
  PiperNotifier(this._value);

  /// The current value.
  T get value => _value;

  /// Sets a new value and notifies listeners if it changed.
  set value(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      for (final listener in _listeners) {
        listener();
      }
    }
  }

  /// Adds a listener that will be called when the value changes.
  void addListener(void Function() listener) => _listeners.add(listener);

  /// Removes a previously added listener.
  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// Disposes this notifier by clearing all listeners.
  void dispose() => _listeners.clear();
}
