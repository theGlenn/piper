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
