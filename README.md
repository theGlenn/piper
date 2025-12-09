<p align="center">
  <img src="docs/public/logo.png" alt="Piper" width="120" />
</p>

<h1 align="center">Piper</h1>

<p align="center">
  <strong>Flutter state management, simplified.</strong><br>
  ViewModels with automatic lifecycle. Just Dart.
</p>

<p align="center">
  <a href="https://pub.dev/packages/piper_state"><img src="https://img.shields.io/pub/v/piper_state.svg" alt="pub package"></a>
  <a href="https://pub.dev/packages/piper_state/score"><img src="https://img.shields.io/pub/likes/piper_state" alt="likes"></a>
  <a href="https://pub.dev/packages/piper_state/score"><img src="https://img.shields.io/pub/points/piper_state" alt="pub points"></a>
  <a href="https://github.com/theGlenn/piper/actions/workflows/ci.yml"><img src="https://github.com/theGlenn/piper/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://codecov.io/gh/theGlenn/piper"><img src="https://codecov.io/gh/theGlenn/piper/branch/main/graph/badge.svg" alt="codecov"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter" alt="Flutter"></a>
</p>

---

- ✅ **Automatic cleanup** — streams cancel, tasks abort on dispose
- ✅ **Explicit dependencies** — constructor injection, no magic
- ✅ **Zero boilerplate** — no code generation required
- ✅ **Testable** — plain Dart classes

## Quick Start
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

## Stream Binding

Subscriptions auto-cancel on dispose:
```dart
class AuthViewModel extends ViewModel {
  final AuthRepository _auth;

  AuthViewModel(this._auth);

  late final user = bind(_auth.userStream, initial: null);
}
```

## Async Operations

Loading, error, and data states handled automatically:
```dart
late final profile = asyncState<Profile>();

void load() => load(profile, () => _repo.fetchProfile());
```
```dart
vm.profile.build(
(state) => switch (state) {
AsyncData(:final data) => Text(data.name),
AsyncError(:final message) => Text('Error: $message'),
_ => CircularProgressIndicator(),
},
);
```

## Installation
```yaml
dependencies:
  piper_state: ^0.0.3
  flutter_piper: ^0.0.3
```

## Documentation

📖 **[Full Documentation](https://theglenn.github.io/piper)**

## Packages

| Package | pub.dev |
|---------|---------|
| [piper_state](packages/piper) | [![pub](https://img.shields.io/pub/v/piper_state.svg)](https://pub.dev/packages/piper_state) |
| [flutter_piper](packages/flutter_piper) | [![pub](https://img.shields.io/pub/v/flutter_piper.svg)](https://pub.dev/packages/flutter_piper) |

## License

MIT