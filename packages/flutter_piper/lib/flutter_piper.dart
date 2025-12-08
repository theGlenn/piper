/// Flutter bindings for Piper state management library.
///
/// This package re-exports everything from `piper` and adds Flutter-specific
/// widgets and extensions.
///
/// For most Flutter apps, just import this package:
/// ```dart
/// import 'package:flutter_piper/flutter_piper.dart';
/// ```
library;

// Re-export everything from piper
export 'package:piper/piper.dart';

// Flutter Widgets
export 'src/state_builder.dart';
export 'src/state_listener.dart';
export 'src/state_effect.dart';
export 'src/scope.dart';

// Flutter Extensions
export 'src/state_holder_flutter.dart';
export 'src/async_state_holder_extensions_flutter.dart';
