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

  /// Creates a Scoped with access to BuildContext for dependency injection.
  ///
  /// Use this when you need access to the BuildContext to create your ViewModel,
  /// for example to read dependencies from the widget tree.
  ///
  /// Example:
  /// ```dart
  /// Scoped.builder<DetailViewModel>(
  ///   create: (context) => DetailViewModel(
  ///     repository: context.read<Repository>(),
  ///   ),
  ///   builder: (context, vm) => DetailPage(),
  /// )
  /// ```
  static Widget builder<T extends ViewModel>({
    Key? key,
    required T Function(BuildContext context) create,
    required Widget Function(BuildContext context, T viewModel) builder,
  }) {
    return _ScopedBuilder<T>(
      key: key,
      create: create,
      builder: builder,
    );
  }

  @override
  State<Scoped<T>> createState() => _ScopedState<T>();
}

class _ScopedBuilder<T extends ViewModel> extends StatelessWidget {
  final T Function(BuildContext context) create;
  final Widget Function(BuildContext context, T viewModel) builder;

  const _ScopedBuilder({
    super.key,
    required this.create,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Scoped<T>(
      create: () => create(context),
      builder: builder,
    );
  }
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
///
/// ## Named Scopes
///
/// Use [ViewModelScope.named] to create a scope that can be accessed by name,
/// useful when multiple routes need to share the same ViewModel:
///
/// ```dart
/// ViewModelScope.named(
///   name: 'checkout',
///   create: [() => CheckoutViewModel()],
///   child: CheckoutFlow(),
/// )
///
/// // Any descendant can access by name:
/// final vm = context.vm<CheckoutViewModel>(scope: 'checkout');
/// ```
class ViewModelScope extends StatefulWidget {
  /// The widget below this scope in the tree.
  final Widget child;

  /// Factory functions that create ViewModels.
  ///
  /// Each factory is called once during [initState] and the
  /// resulting ViewModels are stored by their runtime type.
  final List<ViewModel Function()> create;

  /// Optional name for this scope.
  ///
  /// When provided, ViewModels in this scope can be accessed by name
  /// using `context.vm<T>(scope: 'name')`.
  final String? name;

  const ViewModelScope({
    super.key,
    required this.child,
    required this.create,
  }) : name = null;

  /// Creates a named scope that can be accessed by name from descendants.
  ///
  /// Example:
  /// ```dart
  /// ViewModelScope.named(
  ///   name: 'checkout',
  ///   create: [() => CheckoutViewModel()],
  ///   child: CheckoutFlow(),
  /// )
  ///
  /// // Access by name:
  /// final vm = context.vm<CheckoutViewModel>(scope: 'checkout');
  /// ```
  const ViewModelScope.named({
    super.key,
    required this.name,
    required this.child,
    required this.create,
  });

  /// Creates a ViewModelScope with access to BuildContext for dependency injection.
  ///
  /// Use this when you need access to the BuildContext to create your ViewModels,
  /// for example to read dependencies from the widget tree.
  ///
  /// Example:
  /// ```dart
  /// ViewModelScope.builder(
  ///   create: (context) => [
  ///     AuthViewModel(context.read<AuthRepository>()),
  ///     TodosViewModel(context.read<TodoRepository>()),
  ///   ],
  ///   child: MyApp(),
  /// )
  /// ```
  static Widget builder({
    Key? key,
    required List<ViewModel> Function(BuildContext context) create,
    required Widget child,
  }) {
    return _ViewModelScopeBuilder(
      key: key,
      create: create,
      child: child,
    );
  }

  /// Creates a named ViewModelScope with access to BuildContext for dependency injection.
  ///
  /// Combines the features of [ViewModelScope.named] and [ViewModelScope.builder].
  ///
  /// Example:
  /// ```dart
  /// ViewModelScope.namedBuilder(
  ///   name: 'checkout',
  ///   create: (context) => [
  ///     CheckoutViewModel(context.read<CartRepository>()),
  ///   ],
  ///   child: CheckoutFlow(),
  /// )
  /// ```
  static Widget namedBuilder({
    Key? key,
    required String name,
    required List<ViewModel> Function(BuildContext context) create,
    required Widget child,
  }) {
    return _ViewModelScopeBuilder(
      key: key,
      name: name,
      create: create,
      child: child,
    );
  }

  @override
  State<ViewModelScope> createState() => _ViewModelScopeState();
}

class _ViewModelScopeBuilder extends StatelessWidget {
  final List<ViewModel> Function(BuildContext context) create;
  final Widget child;
  final String? name;

  const _ViewModelScopeBuilder({
    super.key,
    required this.create,
    required this.child,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    final viewModels = create(context);
    if (name != null) {
      return ViewModelScope.named(
        name: name!,
        create: viewModels.map((vm) => () => vm).toList(),
        child: child,
      );
    }
    return ViewModelScope(
      create: viewModels.map((vm) => () => vm).toList(),
      child: child,
    );
  }
}

class _ViewModelScopeState extends State<ViewModelScope> {
  final Map<Type, ViewModel> _instances = {};

  String? get name => widget.name;

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

  String? get name => state.name;

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
  /// If [scope] is provided, only searches within the named scope.
  ///
  /// Example:
  /// ```dart
  /// final authVm = context.vm<AuthViewModel>();
  ///
  /// // Or from a named scope:
  /// final checkoutVm = context.vm<CheckoutViewModel>(scope: 'checkout');
  /// ```
  T vm<T extends ViewModel>({String? scope}) {
    final instance = _findViewModel<T>(scope: scope);
    if (instance == null) {
      if (scope != null) {
        throw FlutterError(
          'No $T found in scope "$scope".\n'
          'Make sure a ViewModelScope.named(name: "$scope") ancestor provides $T.',
        );
      }
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
  ///
  /// If [scope] is provided, only searches within the named scope.
  T? maybeVm<T extends ViewModel>({String? scope}) =>
      _findViewModel<T>(scope: scope);

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

  T? _findViewModel<T extends ViewModel>({String? scope}) {
    T? result;

    visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is _InheritedViewModelScope) {
        // If scope is specified, only match named scopes with that name
        if (scope != null) {
          if (widget.name == scope) {
            final instance = widget.state.get<T>();
            if (instance != null) {
              result = instance;
              return false; // Stop visiting
            }
          }
          // Continue looking for the named scope
          return true;
        }
        // No scope specified, match any scope
        final instance = widget.state.get<T>();
        if (instance != null) {
          result = instance;
          return false; // Stop visiting
        }
      } else if (widget is _InheritedScoped) {
        // Scoped widgets don't have names, skip if searching for named scope
        if (scope != null) {
          return true; // Continue looking
        }
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
