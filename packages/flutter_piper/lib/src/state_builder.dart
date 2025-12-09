import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Rebuilds when a single [ValueListenable] changes.
///
/// A thin wrapper around [ValueListenableBuilder] for use with [StateHolder].
///
/// Example:
/// ```dart
/// StateBuilder<int>(
///   listenable: viewModel.counter.listenable,
///   builder: (context, count, child) => Text('$count'),
/// )
/// ```
class StateBuilder<T> extends StatelessWidget {
  /// The listenable to observe for changes.
  final ValueListenable<T> listenable;

  /// Called when the listenable changes.
  ///
  /// The [child] parameter is the same widget passed to this [StateBuilder],
  /// useful for optimization when part of the subtree doesn't depend on the value.
  final Widget Function(BuildContext context, T value, Widget? child) builder;

  /// An optional child widget that doesn't depend on the listenable's value.
  final Widget? child;

  const StateBuilder({
    super.key,
    required this.listenable,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<T>(
      valueListenable: listenable,
      builder: builder,
      child: child,
    );
  }
}

/// Rebuilds when either of two [ValueListenable]s change.
///
/// Convenience widget for combining two listenables.
///
/// Example:
/// ```dart
/// StateBuilder2<String, bool>(
///   first: viewModel.name.listenable,
///   second: viewModel.isLoading.listenable,
///   builder: (context, name, isLoading) => isLoading
///     ? CircularProgressIndicator()
///     : Text(name),
/// )
/// ```
class StateBuilder2<A, B> extends StatelessWidget {
  /// The first listenable to observe.
  final ValueListenable<A> first;

  /// The second listenable to observe.
  final ValueListenable<B> second;

  /// Called when either listenable changes.
  final Widget Function(BuildContext context, A a, B b) builder;

  const StateBuilder2({
    super.key,
    required this.first,
    required this.second,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, _) => ValueListenableBuilder<B>(
        valueListenable: second,
        builder: (context, b, _) => builder(context, a, b),
      ),
    );
  }
}

/// Rebuilds when any of three [ValueListenable]s change.
///
/// Convenience widget for combining three listenables.
///
/// Example:
/// ```dart
/// StateBuilder3<String, bool, int>(
///   first: viewModel.name.listenable,
///   second: viewModel.isLoading.listenable,
///   third: viewModel.count.listenable,
///   builder: (context, name, isLoading, count) => Text('$name: $count'),
/// )
/// ```
class StateBuilder3<A, B, C> extends StatelessWidget {
  /// The first listenable to observe.
  final ValueListenable<A> first;

  /// The second listenable to observe.
  final ValueListenable<B> second;

  /// The third listenable to observe.
  final ValueListenable<C> third;

  /// Called when any of the three listenables changes.
  final Widget Function(BuildContext context, A a, B b, C c) builder;

  const StateBuilder3({
    super.key,
    required this.first,
    required this.second,
    required this.third,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<A>(
      valueListenable: first,
      builder: (context, a, _) => ValueListenableBuilder<B>(
        valueListenable: second,
        builder: (context, b, _) => ValueListenableBuilder<C>(
          valueListenable: third,
          builder: (context, c, _) => builder(context, a, b, c),
        ),
      ),
    );
  }
}
