import 'package:flutter/widgets.dart';
import 'package:piper/piper.dart';

import 'flutter_listenable_adapter.dart';
import 'state_listener.dart';

/// Flutter widget extensions for [StateHolder].
extension StateHolderWidgets<T> on StateHolder<T> {
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
      valueListenable: flutterListenable,
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
      valueListenable: flutterListenable,
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
      listenable: flutterListenable,
      onChange: onChange,
      child: child,
    );
  }
}
