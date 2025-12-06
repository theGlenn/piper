/// A lightweight, pure Dart state management library.
///
/// Piper prioritizes:
/// - Constructor injection for explicit dependency graphs
/// - Plain Dart classes for business logic
/// - Clear separation between UI-local state and remote state
/// - Framework-agnostic ViewModels that are testable without Flutter
///
/// For Flutter widgets and extensions, use `package:flutter_piper/flutter_piper.dart`.
library;

// Listenable (pure Dart alternative to Flutter's ValueNotifier)
export 'src/listenable.dart';

// State
export 'src/async_state.dart';
export 'src/state_holder.dart';
export 'src/async_state_holder.dart';

// Task
export 'src/task.dart';

// ViewModel
export 'src/view_model.dart';

// Testing
export 'src/testing.dart';
