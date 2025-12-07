# Getting Started

## Installation

Add Piper to your `pubspec.yaml`:

```yaml
dependencies:
  piper: ^0.1.0
  flutter_piper: ^0.1.0
```

- **piper** — Core library (ViewModel, StateHolder, Task). No Flutter dependency.
- **flutter_piper** — Flutter widgets (ViewModelScope, builders). Depends on piper.

## Your First ViewModel

Create a simple counter:

```dart
import 'package:piper/piper.dart';

class CounterViewModel extends ViewModel {
  late final count = state(0);

  void increment() => count.update((c) => c + 1);
  void decrement() => count.update((c) => c - 1);
}
```

That's it. `state(0)` creates a `StateHolder<int>` with initial value `0`.

## Provide to Widget Tree

Wrap your app (or a subtree) with `ViewModelScope`:

```dart
import 'package:flutter_piper/flutter_piper.dart';

void main() {
  runApp(
    ViewModelScope(
      create: [() => CounterViewModel()],
      child: MyApp(),
    ),
  );
}
```

## Use in Widgets

Access the ViewModel and build UI:

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

- `context.vm<T>()` retrieves the ViewModel from the nearest `ViewModelScope`
- `.build()` creates a widget that rebuilds when state changes

## Adding Async Operations

Most apps need async operations. Here's how to fetch data:

```dart
class UserViewModel extends ViewModel {
  final UserRepository _repo;

  UserViewModel(this._repo);

  late final user = asyncState<User>();

  void loadUser(String id) {
    load(user, () => _repo.getUser(id));
  }
}
```

- `asyncState<T>()` creates an `AsyncStateHolder` that tracks loading/error/data
- `load()` sets loading state, runs the async work, then sets data or error

In your widget:

```dart
vm.user.build(
  (state) => switch (state) {
    AsyncData(:final data) => Text('Hello, ${data.name}'),
    AsyncError(:final message) => Text('Error: $message'),
    _ => CircularProgressIndicator(),
  },
);
```

## Binding Streams

If your repository exposes streams, bind them directly:

```dart
class AuthViewModel extends ViewModel {
  final AuthRepository _auth;

  AuthViewModel(this._auth);

  // Updates automatically when stream emits
  late final user = bind(_auth.userStream, initial: null);
}
```

The subscription is automatically cancelled when the ViewModel disposes.

## Next Steps

- [StateHolder](/guide/state-holder) — Synchronous state management
- [AsyncStateHolder](/guide/async-state-holder) — Loading, error, and data states
- [Stream Bindings](/guide/stream-bindings) — Binding streams to state
- [Examples](/examples/counter) — Complete working examples
