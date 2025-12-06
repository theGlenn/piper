import 'package:flutter/widgets.dart';

import 'view_model.dart';

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
        'No $T found in ViewModelScope hierarchy.\n'
        'Make sure a ViewModelScope ancestor provides $T.',
      );
    }
    return instance;
  }

  /// Retrieves a ViewModel of type [T], or null if not found.
  ///
  /// Use this when the ViewModel may not be available.
  T? maybeVm<T extends ViewModel>() => _findViewModel<T>();

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
      }
      return true; // Continue visiting
    });

    return result;
  }
}
