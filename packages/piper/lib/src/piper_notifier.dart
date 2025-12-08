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

  PiperNotifier(this._value);

  T get value => _value;

  set value(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      for (final listener in _listeners) {
        listener();
      }
    }
  }

  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  void dispose() => _listeners.clear();
}
