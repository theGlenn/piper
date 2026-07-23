import 'notification_batch.dart';
import 'tracking.dart';

/// Derived state that recomputes automatically when its dependencies change.
///
/// The compute function is tracked: any [StateHolder] or other [Computed] read
/// inside it becomes a dependency. When a dependency changes, the value is
/// recomputed, and listeners are notified only if the result actually changed.
///
/// Example:
/// ```dart
/// final first = StateHolder('Ada');
/// final last = StateHolder('Lovelace');
/// final fullName = computed(() => '${first.value} ${last.value}');
///
/// fullName.value; // 'Ada Lovelace'
/// first.value = 'Grace';
/// fullName.value; // 'Grace Lovelace' — recomputed automatically
/// ```
class Computed<T> implements Trackable {
  final T Function() _compute;
  final bool Function(T a, T b)? _equals;
  final List<void Function()> _listeners = [];
  final Set<Trackable> _dependencies = {};
  late T _value;
  bool _stale = true;
  bool _computing = false;
  bool _notificationPending = false;

  /// Creates a [Computed] from a derivation function.
  ///
  /// [equals] customizes when a recomputation counts as a change (defaults to
  /// `==`). Provide a structural comparison when [compute] allocates a new
  /// instance each run (e.g. `.toList()`), so unchanged results don't notify.
  Computed(this._compute, {bool Function(T a, T b)? equals}) : _equals = equals;

  /// The current derived value.
  ///
  /// Recomputes if a dependency has changed since the last read. Reading this
  /// inside a `Watch` or another [Computed] subscribes the reader to changes.
  T get value {
    if (_stale) _recompute();
    PiperTracker.reportRead(this);
    return _value;
  }

  void _recompute() {
    if (_computing) {
      throw StateError(
        'Cyclic dependency detected: a computed() read itself while computing.',
      );
    }
    _stale = true;
    _computing = true;
    try {
      for (final dep in _dependencies) {
        dep.removeListener(_onDependencyChanged);
      }
      _dependencies.clear();
      _value = PiperTracker.track(_compute, (source) {
        if (_dependencies.add(source)) {
          source.addListener(_onDependencyChanged);
        }
      });
      _stale = false;
    } finally {
      _computing = false;
    }
  }

  void _onDependencyChanged() {
    _stale = true;
    if (_listeners.isEmpty || _notificationPending) return;
    _notificationPending = true;
    final previous = _value;
    PiperNotificationBatch.schedule(() => _notifyIfChanged(previous));
  }

  void _notifyIfChanged(T previous) {
    _notificationPending = false;
    if (_listeners.isEmpty) return;
    if (_stale) _recompute();
    final unchanged = _equals?.call(previous, _value) ?? (previous == _value);
    if (unchanged) return;
    PiperNotificationBatch.notify(_listeners);
  }

  @override
  void addListener(void Function() listener) {
    // Ensure dependencies are subscribed so change notifications flow.
    if (_stale) _recompute();
    _listeners.add(listener);
  }

  @override
  void removeListener(void Function() listener) => _listeners.remove(listener);

  /// Releases dependency subscriptions and listeners.
  void dispose() {
    for (final dep in _dependencies) {
      dep.removeListener(_onDependencyChanged);
    }
    _dependencies.clear();
    _listeners.clear();
    _notificationPending = false;
  }
}

/// Creates a [Computed] from a derivation function.
///
/// Convenience for `Computed(compute, equals: equals)`.
Computed<T> computed<T>(
  T Function() compute, {
  bool Function(T a, T b)? equals,
}) =>
    Computed<T>(compute, equals: equals);
