# Piper 🚰

State management that gets out of your way.

Lifecycle-aware ViewModels, explicit dependencies, automatic cleanup. Patterns that have worked for years, now in Flutter.

## In a nutshell

**Bind a stream** — state updates automatically, subscription auto-cancels on dispose:

```dart
class AuthViewModel extends ViewModel {
  AuthViewModel(AuthRepository auth);

  late final user = bind(_auth.userStream, initial: null);

  bool get isLoggedIn => user.value != null;
}
```

```dart
// In your widget
vm.user.build((user) => Text('Hello, ${user?.name ?? "Guest"}'));
```

**Async operations** — loading/error/data handled automatically:

```dart
late final profile = asyncState<Profile>();

void loadProfile() => load(profile, () => _repo.fetchProfile());
```

```dart
vm.profile.build(
  (state) => switch (state) {
    AsyncData(:final data) => Text(data.name),
    AsyncError(:final message) => Text('Error: $message'),
    _ => const CircularProgressIndicator(),
  },
);
```

**Simple state** — just values:

```dart
late final count = state(0);

void increment() => count.update((c) => c + 1);
```

## Why Piper?

- **Explicit dependencies** — Constructor injection, not magic
- **Automatic lifecycle** — No `if (mounted)` checks
- **Plain Dart** — Test without Flutter
- **Incremental** — Adopt one feature at a time

## Installation

```yaml
dependencies:
  piper: ^0.1.0
  flutter_piper: ^0.1.0
```

## Learn more

- [Examples](examples/) — Counter, Auth, Todos, Search with cancellation
- [Core Concepts](docs/concepts.md) — StateHolder, AsyncState, ViewModel, Task
- [Comparison](docs/comparison.md) — vs. Riverpod, vs. Bloc

## License

MIT
