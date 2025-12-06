import 'package:flutter/material.dart';

import 'async_state_holder.dart';

extension AsyncStateHolderFlutter<T> on AsyncStateHolder<T> {
  /// Widget builder with built-in state handling.
  ///
  /// Provides sensible defaults for loading and error states.
  /// Only [data] is required; other states have default widgets.
  ///
  /// Example:
  /// ```dart
  /// vm.user.when(
  ///   data: (user) => Text('Hello, ${user.name}'),
  /// )
  /// ```
  Widget displayWhen({
    Widget Function()? empty,
    Widget Function()? loading,
    Widget Function(String message)? error,
    required Widget Function(T data) data,
    Widget Function()? orElse,
  }) {
    return build(
      (state) => state.when(
        empty: () => empty?.call() ?? orElse?.call() ?? const SizedBox.shrink(),
        loading: () =>
            loading?.call() ??
            orElse?.call() ??
            const Center(child: CircularProgressIndicator()),
        error: (msg) =>
            error?.call(msg) ??
            orElse?.call() ??
            Center(
              child: Text(msg, style: const TextStyle(color: Colors.red)),
            ),
        data: data,
      ),
    );
  }

  /// Simplified when with only data handler.
  ///
  /// Uses default widgets for empty, loading, and error states.
  Widget displayWhenData(Widget Function(T data) builder) {
    return displayWhen(data: builder);
  }
}
