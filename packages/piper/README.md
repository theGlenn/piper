<p align="center">
  <img src="https://raw.githubusercontent.com/theGlenn/piper/main/docs/public/logo.png" alt="Piper" width="100" />
</p>

# Piper State

[![pub package](https://img.shields.io/pub/v/piper_state.svg)](https://pub.dev/packages/piper_state)
[![likes](https://img.shields.io/pub/likes/piper_state)](https://pub.dev/packages/piper_state/score)
[![popularity](https://img.shields.io/pub/popularity/piper_state)](https://pub.dev/packages/piper_state/score)
[![pub points](https://img.shields.io/pub/points/piper_state)](https://pub.dev/packages/piper_state/score)
[![CI](https://github.com/theGlenn/piper/actions/workflows/ci.yml/badge.svg)](https://github.com/theGlenn/piper/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/theGlenn/piper/branch/main/graph/badge.svg)](https://codecov.io/gh/theGlenn/piper)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart)](https://dart.dev)
[![style: lints](https://img.shields.io/badge/style-flutter__lints-4BC0F5.svg)](https://pub.dev/packages/lints)

**Flutter state management with lifecycle-aware ViewModels.**

- ✅ Automatic cleanup — streams and cooperative tasks cancel
- ✅ Explicit dependencies — constructor injection
- ✅ Zero boilerplate — no code generation
- ✅ Testable — plain Dart classes

## Installation

For Dart-only projects:

```yaml
dependencies:
  piper_state: ^0.1.0
```

Flutter apps can install `flutter_piper: ^0.1.0` instead; it re-exports this
package and adds scopes, builders, and listeners.

## Quick Example
```dart
class CounterViewModel extends ViewModel {
  late final count = state(0);

  void increment() => count.update((c) => c + 1);
}

// In your widget
vm.count.build((count) => Text('$count'));
```

## Stream Binding
```dart
class AuthViewModel extends ViewModel {
  final AuthRepository _auth;

  AuthViewModel(this._auth);

  late final user = bind(_auth.userStream, initial: null);
}
```

## Async Operations
```dart
late final profile = asyncState<Profile>();

void loadProfile() => load(profile, () => _repo.fetchProfile());
```

## Why Piper?

|  | Piper | Riverpod | Bloc |
|---|---|---|---|
| Dependencies | constructor | `ref.watch` / `ref.read` | constructor |
| State changes | methods | providers + notifiers | methods (Cubit) or events (Bloc) |
| Code generation | none | optional | optional |
| Testing | plain Dart `test()` | `ProviderContainer.test()` | `blocTest` |

Piper favors plain objects over a provider graph or event log. See the
[full comparison](https://glennso.dev/piper/guide/comparison) for the
trade-offs and async cancellation details.

## Documentation

📖 **[Full docs](https://glennso.dev/piper/)** · [GitHub](https://github.com/theGlenn/piper) · [flutter_piper](https://pub.dev/packages/flutter_piper)

## License

MIT
