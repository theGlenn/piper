# Piper 🚰

State management that gets out of your way.

Lifecycle-aware ViewModels, explicit dependencies, automatic cleanup. Patterns that have worked for years, now in Flutter.

## Long story short

Define a ViewModel with stream binding:

```dart
class UserViewModel extends ViewModel {
  final AuthRepository _auth;

  UserViewModel(this._auth) {
    load(profile, () => _auth.fetchProfile());
  }

  late final user = bind(_auth.userStream, initial: null);
  late final profile = asyncState<Profile>();
}
```

Listen to state in your UI and handle loading/error states:

```dart
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.vm<UserViewModel>();

    return vm.profile.build(
      (state) => switch (state) {
        AsyncData(:final data) => Text('Hello, ${data.name}'),
        AsyncError(:final message) => Text('Error: $message'),
        _ => const CircularProgressIndicator(),
      },
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
  piper: ^0.1.0
  flutter_piper: ^0.1.0
```

## Learn more

- [Examples](examples/) — Counter, Auth, Todos, Search with cancellation
- [Core Concepts](docs/concepts.md) — StateHolder, AsyncState, ViewModel, Task
- [Comparison](docs/comparison.md) — vs. Riverpod, vs. Bloc

## License

MIT
