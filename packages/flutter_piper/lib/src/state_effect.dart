import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// For one-shot effects triggered by state changes.
///
/// Automatically handles post-frame callbacks to ensure effects run
/// after the widget tree is built.
///
/// Example:
/// ```dart
/// StateEffect<bool>(
///   listenable: vm.isDeleted.listenable,
///   when: (prev, curr) => !prev && curr, // only when becomes true
///   effect: (value, context) => Navigator.of(context).pop(),
///   child: // rest of UI
/// )
/// ```
class StateEffect<T> extends StatefulWidget {
  /// The listenable to observe for changes.
  final ValueListenable<T> listenable;

  /// The effect to run when the value changes.
  ///
  /// Receives the current value and build context.
  /// Runs after the current frame completes.
  final void Function(T value, BuildContext context) effect;

  /// Optional condition for when to fire the effect.
  ///
  /// If provided, the effect only fires when this returns true.
  /// If not provided, the effect fires on every change.
  final bool Function(T previous, T current)? when;

  /// The child widget that doesn't rebuild on changes.
  final Widget child;

  const StateEffect({
    super.key,
    required this.listenable,
    required this.effect,
    this.when,
    required this.child,
  });

  @override
  State<StateEffect<T>> createState() => _StateEffectState<T>();
}

class _StateEffectState<T> extends State<StateEffect<T>> {
  late T _previous;

  @override
  void initState() {
    super.initState();
    _previous = widget.listenable.value;
    widget.listenable.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant StateEffect<T> oldWidget) {
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
    final shouldFire = widget.when?.call(_previous, current) ?? true;

    if (shouldFire) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.effect(current, context);
      });
    }
    _previous = current;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
