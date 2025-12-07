# Comparison

How Piper compares to other Flutter state management solutions.

## vs. Riverpod

| Aspect | Riverpod | Piper |
|--------|----------|-------|
| Dependencies | `ref.watch`, `ref.read` | Constructor injection |
| Learning curve | Provider types, modifiers, scoping rules | Plain Dart classes |
| State declaration | Providers with annotations | `state()` in ViewModel |
| Async state | `AsyncValue`, `.when()` | `AsyncState`, `.when()` |
| Code generation | Optional but common | None |
| Testing | `ProviderContainer` | Plain unit tests |

### Riverpod Example

```dart
@riverpod
Future<User> user(Ref ref) async {
  return ref.watch(userRepositoryProvider).getUser();
}

class UserPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    return user.when(
      data: (user) => Text(user.name),
      loading: () => CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
```

### Piper Equivalent

```dart
class UserViewModel extends ViewModel {
  UserViewModel(this._repo);
  final UserRepository _repo;

  late final user = asyncState<User>();

  void loadUser() => load(user, () => _repo.getUser());
}

class UserPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.vm<UserViewModel>();
    return vm.user.build(
      (state) => switch (state) {
        AsyncData(:final data) => Text(data.name),
        AsyncLoading() => CircularProgressIndicator(),
        AsyncError(:final message) => Text('Error: $message'),
        _ => SizedBox.shrink(),
      },
    );
  }
}
```

## vs. Bloc

| Aspect | Bloc | Piper |
|--------|------|-------|
| State changes | Events → Bloc → States | Methods → State |
| Boilerplate | Event classes, State classes | Just methods |
| Async handling | `emit()` in event handlers | `launch()`, `load()` |
| Testing | `blocTest()` | Plain unit tests |

### Bloc Example

```dart
// Events
abstract class CounterEvent {}
class Increment extends CounterEvent {}
class Decrement extends CounterEvent {}

// Bloc
class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
    on<Decrement>((event, emit) => emit(state - 1));
  }
}

// Widget
BlocBuilder<CounterBloc, int>(
  builder: (context, count) => Text('$count'),
)
```

### Piper Equivalent

```dart
class CounterViewModel extends ViewModel {
  late final count = state(0);

  void increment() => count.update((c) => c + 1);
  void decrement() => count.update((c) => c - 1);
}

// Widget
vm.count.build((count) => Text('$count'))
```

## vs. Provider

| Aspect | Provider | Piper |
|--------|----------|-------|
| State container | ChangeNotifier | StateHolder |
| Lifecycle | Manual or ProxyProvider | Automatic in ViewModel |
| Async support | Manual | Built-in AsyncState |
| Stream handling | StreamProvider | `bind()`, `subscribe()` |

## When to Choose Piper

Choose Piper if you:

- **Prefer explicit dependencies** — Constructor injection makes dependencies obvious
- **Want minimal boilerplate** — No event classes, no code generation
- **Like plain Dart** — ViewModels are testable without framework utilities
- **Are coming from Android/iOS** — Familiar ViewModel patterns
- **Want incremental adoption** — Works alongside existing solutions

## When to Choose Alternatives

Choose **Riverpod** if you:
- Need fine-grained provider scoping
- Want compile-time dependency verification
- Prefer functional/declarative style

Choose **Bloc** if you:
- Want strict separation of events and state
- Need detailed event logging/replay
- Prefer the event-driven pattern

Choose **Provider** if you:
- Need the simplest possible solution
- Are working on a small app
- Want minimal dependencies
