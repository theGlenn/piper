import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'state_listener.dart';

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

  /// The underlying [ValueListenable] for binding to widgets.
  ValueListenable<T> get listenable => _notifier;

  /// Disposes the underlying notifier.
  ///
  /// After calling dispose, this [StateHolder] should not be used.
  void dispose() => _notifier.dispose();

  /// Direct widget building - primary API for UI binding.
  ///
  /// Builds a widget that rebuilds when this state changes.
  ///
  /// Example:
  /// ```dart
  /// counter.build((value) => Text('$value'));
  /// ```
  Widget build(Widget Function(T value) builder) {
    return ValueListenableBuilder<T>(
      valueListenable: _notifier,
      builder: (_, value, __) => builder(value),
    );
  }

  /// Build with child optimization for static subtrees.
  ///
  /// Use this when part of the widget tree doesn't depend on the value.
  ///
  /// Example:
  /// ```dart
  /// counter.buildWithChild(
  ///   builder: (value, child) => Column(
  ///     children: [Text('$value'), child!],
  ///   ),
  ///   child: const ExpensiveWidget(),
  /// );
  /// ```
  Widget buildWithChild({
    required Widget Function(T value, Widget? child) builder,
    Widget? child,
  }) {
    return ValueListenableBuilder<T>(
      valueListenable: _notifier,
      builder: (_, value, child) => builder(value, child),
      child: child,
    );
  }

  /// Listen to changes without rebuilding.
  ///
  /// Use for side effects like navigation, showing snackbars, etc.
  ///
  /// Example:
  /// ```dart
  /// vm.isDeleted.listen(
  ///   onChange: (previous, current) {
  ///     if (current) Navigator.of(context).pop();
  ///   },
  ///   child: // rest of UI
  /// )
  /// ```
  Widget listen({
    required void Function(T previous, T current) onChange,
    required Widget child,
  }) {
    return StateListener<T>(
      listenable: _notifier,
      onChange: onChange,
      child: child,
    );
  }
}
