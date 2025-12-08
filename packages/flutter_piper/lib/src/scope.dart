import 'package:flutter/widgets.dart';
import 'package:piper/piper.dart';

/// A widget that scopes a single ViewModel of type [T] and provides it to descendants.
///
/// Unlike [ViewModelScope] which holds multiple ViewModels, [Scoped] is designed
/// for cases where you want to scope a single ViewModel with a builder pattern.
///
/// The ViewModel is eagerly instantiated in [initState] and disposed
/// when the scope is removed from the tree.
///
/// Example:
/// ```dart
/// Scoped<DetailViewModel>(
///   create: () => DetailViewModel(id),
///   builder: (context, vm) => DetailPage(),
/// )
/// ```
///
/// Access the ViewModel from descendants using:
/// ```dart
/// final vm = context.vm<DetailViewModel>();
/// // or
/// final vm = context.scoped<DetailViewModel>();
/// ```
class Scoped<T extends ViewModel> extends StatefulWidget {
  /// Factory function that creates the ViewModel.
  ///
  /// Called once during [initState].
  final T Function() create;

  /// Builder function that receives the context and the ViewModel.
  ///
  /// The ViewModel is guaranteed to be non-null when this is called.
  final Widget Function(BuildContext context, T viewModel) builder;

  const Scoped({
    super.key,
    required this.create,
    required this.builder,
  });

  @override
  State<Scoped<T>> createState() => _ScopedState<T>();
}

class _ScopedState<T extends ViewModel> extends State<Scoped<T>> {
  late final T _instance;

  @override
  void initState() {
    super.initState();
    _instance = widget.create();
  }

  @override
  void dispose() {
    _instance.dispose();
    super.dispose();
  }

  /// Retrieves the ViewModel if [U] matches [T], otherwise returns null.
  U? get<U extends ViewModel>() {
    if (U == T) {
      return _instance as U;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedScoped<T>(
      state: this,
      child: Builder(
        builder: (context) => widget.builder(context, _instance),
      ),
    );
  }
}

class _InheritedScoped<T extends ViewModel> extends InheritedWidget {
  final _ScopedState<T> state;

  const _InheritedScoped({
    required this.state,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant _InheritedScoped<T> oldWidget) => false;
}

/// Widget that holds ViewModels and provides them to descendants.
///
/// ViewModels are eagerly instantiated in [initState] and disposed
/// when the scope is removed from the tree.
///
/// Example:
/// ```dart
/// ViewModelScope(
///   create: [
///     () => AuthViewModel(authRepo),
///     () => TodosViewModel(todoRepo),
///   ],
///   child: MyApp(),
/// )
/// ```
class ViewModelScope extends StatefulWidget {
  /// The widget below this scope in the tree.
  final Widget child;

  /// Factory functions that create ViewModels.
  ///
  /// Each factory is called once during [initState] and the
  /// resulting ViewModels are stored by their runtime type.
  final List<ViewModel Function()> create;

  const ViewModelScope({
    super.key,
    required this.child,
    required this.create,
  });

  @override
  State<ViewModelScope> createState() => _ViewModelScopeState();
}

class _ViewModelScopeState extends State<ViewModelScope> {
  final Map<Type, ViewModel> _instances = {};

  @override
  void initState() {
    super.initState();
    for (final factory in widget.create) {
      final instance = factory();
      _instances[instance.runtimeType] = instance;
    }
  }

  @override
  void dispose() {
    for (final vm in _instances.values) {
      vm.dispose();
    }
    super.dispose();
  }

  /// Retrieves a ViewModel by type, or null if not found in this scope.
  T? get<T extends ViewModel>() => _instances[T] as T?;

  @override
  Widget build(BuildContext context) {
    return _InheritedViewModelScope(
      state: this,
      child: widget.child,
    );
  }
}

class _InheritedViewModelScope extends InheritedWidget {
  final _ViewModelScopeState state;

  const _InheritedViewModelScope({
    required this.state,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant _InheritedViewModelScope oldWidget) => false;
}

/// Extension for retrieving ViewModels from the widget tree.
extension ViewModelContext on BuildContext {
  /// Retrieves a ViewModel of type [T] from the nearest ancestor scope.
  ///
  /// Throws a [FlutterError] if no ViewModel of type [T] is found.
  ///
  /// Searches both [ViewModelScope] and [Scoped] widgets.
  /// Uses shadowing behavior: if the same ViewModel type exists in
  /// multiple ancestor scopes, the nearest scope wins.
  ///
  /// Example:
  /// ```dart
  /// final authVm = context.vm<AuthViewModel>();
  /// ```
  T vm<T extends ViewModel>() {
    final instance = _findViewModel<T>();
    if (instance == null) {
      throw FlutterError(
        'No $T found in scope hierarchy.\n'
        'Make sure a ViewModelScope or Scoped<$T> ancestor provides $T.',
      );
    }
    return instance;
  }

  /// Retrieves a ViewModel of type [T], or null if not found.
  ///
  /// Searches both [ViewModelScope] and [Scoped] widgets.
  /// Use this when the ViewModel may not be available.
  T? maybeVm<T extends ViewModel>() => _findViewModel<T>();

  /// Alias for [vm] that makes the [Scoped] usage more explicit.
  ///
  /// Example:
  /// ```dart
  /// Scoped<DetailViewModel>(
  ///   create: () => DetailViewModel(id),
  ///   builder: (context, vm) => DetailPage(),
  /// )
  ///
  /// // Later in DetailPage:
  /// final vm = context.scoped<DetailViewModel>();
  /// ```
  T scoped<T extends ViewModel>() => vm<T>();

  T? _findViewModel<T extends ViewModel>() {
    T? result;

    visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is _InheritedViewModelScope) {
        final instance = widget.state.get<T>();
        if (instance != null) {
          result = instance;
          return false; // Stop visiting
        }
      } else if (widget is _InheritedScoped) {
        final instance = widget.state.get<T>();
        if (instance != null) {
          result = instance;
          return false; // Stop visiting
        }
      }
      return true; // Continue visiting
    });

    return result;
  }
}
