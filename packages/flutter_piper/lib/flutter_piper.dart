/// Flutter bindings for Piper state management library.
///
/// This package re-exports everything from `piper` and adds Flutter-specific
/// extensions.
///
/// For most Flutter apps, just import this package:
/// ```dart
/// import 'package:flutter_piper/flutter_piper.dart';
/// ```
library;

// Re-export everything from piper
export 'package:piper/piper.dart';

// Flutter-specific extensions
export 'src/async_state_holder_extensions_flutter.dart';
