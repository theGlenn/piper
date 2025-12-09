# Piper

State management that gets out of your way.

Lifecycle-aware ViewModels, explicit dependencies, automatic cleanup. Patterns that have worked for years, now in Flutter.

## Features

- **StateHolder** — Reactive state containers with automatic widget rebuilds
- **AsyncState** — Built-in loading/error/data states for async operations
- **Stream bindings** — Bind streams to state with automatic subscription management
- **ViewModel** — Lifecycle-aware base class with automatic resource cleanup
- **Plain Dart** — Core library has no Flutter dependency, test without widgets

## Getting started

```yaml
dependencies:
  piper: ^0.0.2
  flutter_piper: ^0.0.2  # For Flutter widgets
```

## Usage

### Basic state

```dart
class CounterViewModel extends ViewModel {
  late final count = state(0);

  void increment() => count.update((c) => c + 1);
}
```

### Stream binding

State updates automatically, subscription auto-cancels on dispose:

```dart
class AuthViewModel extends ViewModel {
  AuthViewModel(AuthRepository auth);

  late final user = bind(_auth.userStream, initial: null);

  bool get isLoggedIn => user.value != null;
}
```

### Async operations

Loading/error/data handled automatically:

```dart
late final profile = asyncState<Profile>();

void loadProfile() => load(profile, () => _repo.fetchProfile());
```

## Why Piper?

- **Explicit dependencies** — Constructor injection, not magic
- **Automatic lifecycle** — No `if (mounted)` checks
- **Plain Dart** — Test without Flutter
- **Incremental** — Adopt one feature at a time

## Additional information

- [GitHub Repository](https://github.com/glennsonna/piper)
- [flutter_piper](https://pub.dev/packages/flutter_piper) — Flutter widgets for Piper

## License

MIT
