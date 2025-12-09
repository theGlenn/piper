import 'package:flutter/widgets.dart';
import 'package:piper_state/piper_state.dart';

/// A widget that scopes a single ViewModel of type [T] and provides it to descendants.
///
/// Unlike [ViewModelScope] which holds multiple ViewModels, [Scoped] is designed
/// for cases where you want to scope a single ViewModel with a builder pattern.
///
/// The ViewModel is created once and disposed when the widget is removed from the tree.
///
/// ## Basic Usage
///
/// ```dart
/// Scoped<DetailViewModel>(
///   create: () => DetailViewModel(id),
///   builder: (context, vm) => DetailPage(),
/// )
/// ```
///
/// ## With BuildContext (for dependency injection)
///
/// Use [Scoped.withContext] when you need access to the widget tree:
///
/// ```dart
/// Scoped<DetailViewModel>.withContext(
///   create: (context) => DetailViewModel(context.read<Repository>()),
///   builder: (context, vm) => DetailPage(),
/// )
/// ```
///
/// ## Accessing the ViewModel
///
/// From descendants:
/// ```dart
/// final vm = context.vm<DetailViewModel>();
/// // or
/// final vm = context.scoped<DetailViewModel>();
/// ```
class Scoped<T extends ViewModel> extends StatefulWidget {
  final T Function()? _create;
  final T Function(BuildContext)? _createWithContext;

  /// Builder function that receives the context and the ViewModel.
  final Widget Function(BuildContext context, T viewModel) builder;

  /// Creates a [Scoped] widget with a factory that doesn't require context.
  const Scoped({
    super.key,
    required T Function() create,
    required this.builder,
  })  : _create = create,
        _createWithContext = null;

  /// Creates a [Scoped] widget with access to [BuildContext] for dependency injection.
  ///
  /// Use this when you need to read dependencies from the widget tree.
  const Scoped.withContext({
    super.key,
    required T Function(BuildContext) create,
    required this.builder,
  })  : _create = null,
        _createWithContext = create;

  @override
  State<Scoped<T>> createState() => _ScopedState<T>();
}

class _ScopedState<T extends ViewModel> extends State<Scoped<T>> {
  late final T _instance;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _instance = widget._create?.call() ?? widget._createWithContext!(context);
    }
  }

  @override
  void dispose() {
    _instance.dispose();
    super.dispose();
  }

  /// Retrieves the ViewModel if [U] matches [T], otherwise returns null.
  U? get<U extends ViewModel>() => U == T ? _instance as U : null;

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

/// Widget that holds multiple ViewModels and provides them to descendants.
///
/// ViewModels are created once and disposed when the scope is removed from the tree.
///
/// ## Basic Usage
///
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
/// ## With BuildContext (for dependency injection)
///
/// Use [ViewModelScope.withContext] when you need access to the widget tree:
///
/// ```dart
/// ViewModelScope.withContext(
///   create: [
///     (context) => AuthViewModel(context.read<AuthRepository>()),
///     (context) => TodosViewModel(context.read<TodoRepository>()),
///   ],
///   child: MyApp(),
/// )
/// ```
///
/// ## Named Scopes
///
/// Use the optional [name] parameter to create a scope that can be accessed by name,
/// useful when you need to access a specific scope from anywhere in the subtree:
///
/// ```dart
/// ViewModelScope(
///   name: 'checkout',
///   create: [() => CheckoutViewModel()],
///   child: CheckoutFlow(),
/// )
///
/// // Any descendant can access by name:
/// final vm = context.vm<CheckoutViewModel>(scope: 'checkout');
/// ```
///
/// Named scopes work with both constructors:
///
/// ```dart
/// ViewModelScope.withContext(
///   name: 'checkout',
///   create: [(context) => CheckoutViewModel(context.read<CartRepo>())],
///   child: CheckoutFlow(),
/// )
/// ```
class ViewModelScope extends StatefulWidget {
  final Widget child;
  final List<ViewModel Function()>? _create;
  final List<ViewModel Function(BuildContext)>? _createWithContext;

  /// Optional name for this scope.
  ///
  /// When provided, ViewModels in this scope can be accessed by name
  /// using `context.vm<T>(scope: 'name')`.
  final String? name;

  /// Creates a [ViewModelScope] with factories that don't require context.
  const ViewModelScope({
    super.key,
    required this.child,
    required List<ViewModel Function()> create,
    this.name,
  })  : _create = create,
        _createWithContext = null;

  /// Creates a [ViewModelScope] with access to [BuildContext] for dependency injection.
  ///
  /// Use this when you need to read dependencies from the widget tree.
  const ViewModelScope.withContext({
    super.key,
    required List<ViewModel Function(BuildContext)> create,
    required this.child,
    this.name,
  })  : _create = null,
        _createWithContext = create;

  @override
  State<ViewModelScope> createState() => _ViewModelScopeState();
}

class _ViewModelScopeState extends State<ViewModelScope> {
  final Map<Type, ViewModel> _instances = {};
  bool _initialized = false;

  String? get name => widget.name;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      _createViewModels();
    }
  }

  void _createViewModels() {
    if (widget._create != null) {
      for (final factory in widget._create!) {
        final instance = factory();
        _instances[instance.runtimeType] = instance;
      }
    } else if (widget._createWithContext != null) {
      for (final factory in widget._createWithContext!) {
        final instance = factory(context);
        _instances[instance.runtimeType] = instance;
      }
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
  bool updateShouldNotify(covariant _InheritedViewModelScope oldWidget) =>
      false;
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
          'Make sure a ViewModelScope(name: "$scope") ancestor provides $T.',
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
