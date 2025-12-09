<p align="center">
  <img src="docs/public/logo.png" alt="Piper" width="120" />
</p>

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

## "Just show me a counter"

```dart
class CounterViewModel extends ViewModel {
  late final count = state(0);

  void increment() => count.update((c) => c + 1);
}
```

```dart
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.vm<CounterViewModel>();

    return Scaffold(
      body: Center(
        child: vm.count.build((count) => Text('$count')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: vm.increment,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

## Why Piper?

- **Explicit dependencies** — Constructor injection, not magic
- **Automatic lifecycle** — No `if (mounted)` checks
- **Plain Dart** — Test without Flutter
- **Incremental** — Adopt one feature at a time

## Installation

```yaml
dependencies:
  piper_state: ^0.0.2
  flutter_piper: ^0.0.2
```

## Learn more

- [Examples](examples/) — Counter, Auth, Todos, Search, Form validation, Navigation
- [Core Concepts](docs/concepts.md) — StateHolder, AsyncState, ViewModel, Task
- [Comparison](docs/comparison.md) — vs. Riverpod, vs. Bloc

## Roadmap

- [ ] **Derived state** — `select()` API for computed values with automatic dependency tracking
- [ ] **DevTools extension** — Inspect ViewModels and state in real-time
- [ ] **Code generation** — Optional codegen for boilerplate reduction

## License

MIT
