import 'package:flutter/material.dart';
import 'package:flutter_piper/flutter_piper.dart';

/// Flutter widget extensions for [AsyncStateHolder].
extension AsyncStateHolderFlutter<T> on AsyncStateHolder<T> {
  /// Widget builder with built-in state handling.
  ///
  /// Provides sensible defaults for loading and error states.
  /// Only [data] is required; other states have default widgets.
  ///
  /// Example:
  /// ```dart
  /// vm.user.displayWhen(
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

  /// Listen to async state changes for side effects.
  ///
  /// Provides type-safe callbacks for each async state type.
  /// Use for side effects like showing snackbars on error, navigation, etc.
  ///
  /// Example:
  /// ```dart
  /// vm.saveState.listenAsync(
  ///   onData: (data) => Navigator.of(context).pop(),
  ///   onError: (msg) => ScaffoldMessenger.of(context).showSnackBar(
  ///     SnackBar(content: Text(msg)),
  ///   ),
  ///   child: // rest of UI
  /// )
  /// ```
  Widget listenAsync({
    void Function(T data)? onData,
    void Function(String message)? onError,
    void Function()? onLoading,
    required Widget child,
  }) {
    return StateListener<AsyncState<T>>(
      listenable: listenable,
      onChange: (previous, current) {
        if (onData != null && current is AsyncData<T>) {
          onData(current.data);
        }
        if (onError != null && current is AsyncError<T>) {
          onError(current.message);
        }
        if (onLoading != null && current is AsyncLoading<T>) {
          onLoading();
        }
      },
      child: child,
    );
  }
}
