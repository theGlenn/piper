import 'listenable.dart';

/// Synchronous state container wrapping [ValueNotifier].
///
/// Provides a simple interface for managing UI-local state with
/// change notification support.
///
/// Example:
/// ```dart
/// final counter = StateHolder(0);
/// counter.value = 1;
/// counter.update((current) => current + 1);
/// ```
class StateHolder<T> {
  final ValueNotifier<T> _notifier;

  /// Creates a [StateHolder] with the given initial value.
  StateHolder(T initial) : _notifier = ValueNotifier(initial);

  /// The current value.
  T get value => _notifier.value;

  /// Sets a new value, notifying listeners if it changed.
  set value(T val) => _notifier.value = val;

  /// Updates the value using a transformation function.
  ///
  /// Useful for updates that depend on the current value.
  void update(T Function(T current) updater) {
    _notifier.value = updater(_notifier.value);
  }

  /// The underlying [ValueListenable] for binding to widgets or listeners.
  ValueListenable<T> get listenable => _notifier;

  /// Disposes the underlying notifier.
  ///
  /// After calling dispose, this [StateHolder] should not be used.
  void dispose() => _notifier.dispose();
}
