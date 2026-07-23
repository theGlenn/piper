import 'package:flutter/widgets.dart';
import 'package:piper_state/piper_state.dart';

/// Rebuilds automatically when any state read inside [builder] changes.
///
/// This is the Compose-style primitive: instead of wrapping a specific
/// listenable, you just *read* state inside the builder and [Watch] subscribes
/// to exactly what you touched — one holder, five holders, or a [Computed].
///
/// Example:
/// ```dart
/// Watch((context) => Text('${vm.count.value}'))
/// ```
///
/// Reading multiple values in one place replaces [StateBuilder2]/[StateBuilder3]:
/// ```dart
/// Watch((context) => vm.loading.value
///   ? const CircularProgressIndicator()
///   : Text(vm.name.value))
/// ```
class Watch extends StatefulWidget {
  /// Builds the subtree. Every `state.value` read here is tracked.
  final Widget Function(BuildContext context) builder;

  const Watch(this.builder, {super.key});

  @override
  State<Watch> createState() => _WatchState();
}

class _WatchState extends State<Watch> {
  final Set<Trackable> _dependencies = {};

  @override
  void dispose() {
    for (final dep in _dependencies) {
      dep.removeListener(_onChange);
    }
    _dependencies.clear();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final next = <Trackable>{};
    final child = PiperTracker.track(() => widget.builder(context), next.add);

    // Subscribe to newly read state, drop state no longer read.
    for (final dep in next) {
      if (!_dependencies.contains(dep)) dep.addListener(_onChange);
    }
    for (final dep in _dependencies) {
      if (!next.contains(dep)) dep.removeListener(_onChange);
    }
    _dependencies
      ..clear()
      ..addAll(next);

    return child;
  }
}
