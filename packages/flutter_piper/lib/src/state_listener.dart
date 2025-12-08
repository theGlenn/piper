import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Listens to state changes without rebuilding.
///
/// Use for side effects like navigation, showing snackbars, analytics, etc.
///
/// Example:
/// ```dart
/// StateListener<bool>(
///   listenable: vm.isDeleted.listenable,
///   onChange: (previous, current) {
///     if (current) Navigator.of(context).pop();
///   },
///   child: // rest of UI
/// )
/// ```
class StateListener<T> extends StatefulWidget {
  /// The listenable to observe for changes.
  final ValueListenable<T> listenable;

  /// Called when the value changes.
  ///
  /// Provides both the previous and current values for comparison.
  final void Function(T previous, T current) onChange;

  /// The child widget that doesn't rebuild on changes.
  final Widget child;

  const StateListener({
    super.key,
    required this.listenable,
    required this.onChange,
    required this.child,
  });

  @override
  State<StateListener<T>> createState() => _StateListenerState<T>();
}

class _StateListenerState<T> extends State<StateListener<T>> {
  late T _previous;

  @override
  void initState() {
    super.initState();
    _previous = widget.listenable.value;
    widget.listenable.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant StateListener<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenable != widget.listenable) {
      oldWidget.listenable.removeListener(_onChanged);
      _previous = widget.listenable.value;
      widget.listenable.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final current = widget.listenable.value;
    widget.onChange(_previous, current);
    _previous = current;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
