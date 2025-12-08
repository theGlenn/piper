import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:piper/piper.dart';

import 'state_listener.dart';

/// Adapts piper's [StateHolder] to Flutter's [ValueListenable].
class _StateHolderListenable<T> implements ValueListenable<T> {
  final StateHolder<T> _holder;

  _StateHolderListenable(this._holder);

  @override
  T get value => _holder.value;

  @override
  void addListener(VoidCallback listener) => _holder.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _holder.removeListener(listener);
}

/// Flutter extensions for [StateHolder].
extension StateHolderFlutter<T> on StateHolder<T> {
  /// Exposes this [StateHolder] as a Flutter [ValueListenable].
  ValueListenable<T> get listenable => _StateHolderListenable(this);

  /// Builds a widget that rebuilds when this state changes.
  ///
  /// Example:
  /// ```dart
  /// vm.counter.build((count) => Text('$count'))
  /// ```
  Widget build(Widget Function(T value) builder) {
    return ValueListenableBuilder<T>(
      valueListenable: listenable,
      builder: (_, value, __) => builder(value),
    );
  }

  /// Builds a widget with child optimization for static subtrees.
  ///
  /// Example:
  /// ```dart
  /// vm.counter.buildWithChild(
  ///   builder: (value, child) => Column(
  ///     children: [Text('$value'), child!],
  ///   ),
  ///   child: const ExpensiveWidget(),
  /// )
  /// ```
  Widget buildWithChild({
    required Widget Function(T value, Widget? child) builder,
    Widget? child,
  }) {
    return ValueListenableBuilder<T>(
      valueListenable: listenable,
      builder: (_, value, child) => builder(value, child),
      child: child,
    );
  }

  /// Listens to changes without rebuilding.
  ///
  /// Use for side effects like navigation, snackbars, etc.
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
      listenable: listenable,
      onChange: onChange,
      child: child,
    );
  }
}
