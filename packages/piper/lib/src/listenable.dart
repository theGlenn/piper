/// A callback type for value change listeners.
typedef ValueCallback<T> = void Function(T value);

/// A pure Dart interface for objects that can be listened to.
///
/// This is a minimal alternative to Flutter's [Listenable] that doesn't
/// depend on the Flutter framework.
abstract class Listenable {
  /// Register a listener callback.
  void addListener(void Function() listener);

  /// Remove a previously registered listener.
  void removeListener(void Function() listener);
}

/// A pure Dart interface for objects that hold a value and notify on changes.
///
/// This is a minimal alternative to Flutter's [ValueListenable].
abstract class ValueListenable<T> extends Listenable {
  /// The current value.
  T get value;
}

/// A simple implementation of [ValueListenable] for pure Dart.
///
/// Notifies listeners when [value] changes.
///
/// This is the pure Dart equivalent of Flutter's [ValueNotifier].
class ValueNotifier<T> implements ValueListenable<T> {
  ValueNotifier(this._value);

  final List<void Function()> _listeners = [];
  T _value;
  bool _disposed = false;

  @override
  T get value => _value;

  set value(T newValue) {
    if (_disposed) {
      throw StateError('Cannot set value on disposed ValueNotifier');
    }
    if (_value != newValue) {
      _value = newValue;
      _notifyListeners();
    }
  }

  @override
  void addListener(void Function() listener) {
    if (_disposed) {
      throw StateError('Cannot add listener to disposed ValueNotifier');
    }
    _listeners.add(listener);
  }

  @override
  void removeListener(void Function() listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    // Create a copy to handle modifications during iteration
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  /// Disposes this notifier, preventing further updates.
  void dispose() {
    _disposed = true;
    _listeners.clear();
  }
}
