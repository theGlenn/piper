/// A lightweight, dependency-free state management library for Flutter.
///
/// Piper prioritizes:
/// - Constructor injection for explicit dependency graphs
/// - Plain Dart classes for business logic
/// - Clear separation between UI-local state and remote state
/// - Lifecycle-aware scoping via the widget tree
/// - Framework-agnostic ViewModels that are testable without Flutter
library;

// State
export 'src/async_state.dart';
export 'src/state_holder.dart';
export 'src/async_state_holder.dart';

// Task
export 'src/task.dart';

// ViewModel
export 'src/view_model.dart';

// Scope
export 'src/scope.dart';

// Widgets
export 'src/state_builder.dart';
export 'src/state_listener.dart';
export 'src/state_effect.dart';

// Testing
export 'src/testing.dart';
