# Getting Started

Install Piper and create your first ViewModel in under 5 minutes.

## Installation

```yaml
dependencies:
  piper_state: ^0.1.0
  flutter_piper: ^0.1.0
```

- **piper_state** — Core library (ViewModel, StateHolder, Task). No Flutter dependency.
- **flutter_piper** — Flutter widgets (ViewModelScope, builders).

## Your First ViewModel

```dart
import 'package:piper_state/piper_state.dart';

class CounterViewModel extends ViewModel {
  late final count = state(0);

  void increment() => count.update((c) => c + 1);
  void decrement() => count.update((c) => c - 1);
}
```

## Provide to Widget Tree

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

- `context.vm<T>()` — retrieves ViewModel from nearest scope
- `.build()` — rebuilds widget when a single value changes

For a widget that reads several values, wrap the body in `Watch` — it
subscribes to whatever state you read inside it:

```dart
Watch((context) => vm.loading.value
    ? const CircularProgressIndicator()
    : Text(vm.name.value))
```

See [Watch & Computed](/guide/reactive) for derived state and automatic
dependency tracking.

## Async Operations

```dart
class UserViewModel extends ViewModel {
  final UserRepository _repo;

  UserViewModel(this._repo);

  late final user = asyncState<User>();

  void loadUser(String id) => load(user, () => _repo.getUser(id));
}
```

- `asyncState<T>()` — tracks loading/error/data
- `load()` — sets loading, runs async, sets data or error

In widgets:

```dart
vm.user.build(
  (state) => switch (state) {
    AsyncData(:final data) => Text('Hello, ${data.name}'),
    AsyncError(:final message) => Text('Error: $message'),
    _ => CircularProgressIndicator(),
  },
)
```

## Stream Bindings

```dart
class AuthViewModel extends ViewModel {
  late final user = bind(repo.userStream, initial: null);
}
```

Subscription auto-cancels when ViewModel disposes.

## Next Steps

- [StateHolder](/guide/state-holder) — Sync state
- [AsyncStateHolder](/guide/async-state-holder) — Async state
- [Watch & Computed](/guide/reactive) — Automatic rebuilds and derived state
- [Stream Bindings](/guide/stream-bindings) — Stream handling
- [Examples](/examples/counter) — Complete examples
