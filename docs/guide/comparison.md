# Comparison

Side-by-side comparison with other Flutter state management solutions.

## vs. Riverpod

| Aspect | Riverpod | Piper |
|--------|----------|-------|
| Dependencies | `ref.watch`, `ref.read` | Constructor |
| Learning curve | Provider types, modifiers, scoping | Plain Dart |
| State | Providers + notifiers | `state()` |
| Reactivity | `ref.watch` auto-tracks | `Watch` / `computed` auto-track |
| Async | `AsyncValue` | `AsyncState` |
| Code generation | Optional | None |
| Testing | `ProviderContainer.test()` | Plain tests |

### Riverpod

```dart
@riverpod
Future<User> user(Ref ref) async {
  return ref.watch(userRepositoryProvider).getUser();
}

class UserPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(userProvider).when(
      data: (user) => Text(user.name),
      loading: () => CircularProgressIndicator(),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
```

Shown here in Riverpod's code-generated syntax. A manual, codegen-free syntax is
equally supported — since the Dart macros cancellation, Riverpod's docs treat
code generation as optional rather than the default.

### Piper

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

The `bloc` package ships two primitives, and they compare differently. `Cubit`
needs only a state plus methods — close to a ViewModel in shape. `Bloc` adds an
event hierarchy and handlers, buying traceability and event transformers.

| Aspect | Cubit | Bloc | Piper |
|--------|-------|------|-------|
| State changes | Methods → `emit()` | Events → handlers → states | Methods → State |
| Boilerplate | State class | Event + State classes | Methods |
| Async | `emit()` in methods | `emit()` in handlers | `launch()`, `load()` |
| Cancellation | Manual | `bloc_concurrency` `restartable()` | `cancellation.wait` |
| Testing | `blocTest()` | `blocTest()` | Plain tests |

### Cubit

```dart
class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment() => emit(state + 1);
  void decrement() => emit(state - 1);
}

BlocBuilder<CounterCubit, int>(
  builder: (context, count) => Text('$count'),
)
```

### Bloc

```dart
abstract class CounterEvent {}
class Increment extends CounterEvent {}
class Decrement extends CounterEvent {}

class CounterBloc extends Bloc<CounterEvent, int> {
  CounterBloc() : super(0) {
    on<Increment>((event, emit) => emit(state + 1));
    on<Decrement>((event, emit) => emit(state - 1));
  }
}

BlocBuilder<CounterBloc, int>(
  builder: (context, count) => Text('$count'),
)
```

### Piper

```dart
class CounterViewModel extends ViewModel {
  late final count = state(0);
  void increment() => count.update((c) => c + 1);
  void decrement() => count.update((c) => c - 1);
}

vm.count.build((count) => Text('$count'))
```

## vs. Provider

| Aspect | Provider | Piper |
|--------|----------|-------|
| State | ChangeNotifier | StateHolder |
| Lifecycle | Manual/ProxyProvider | Automatic |
| Async | Manual | Built-in |
| Streams | StreamProvider | `bind()` |

## When to Choose

### Choose Piper if you:
- Prefer constructor injection
- Want minimal boilerplate
- Like plain Dart / testable ViewModels
- Are coming from Android/iOS
- Want incremental adoption

### Choose Riverpod if you:
- Need fine-grained provider scoping
- Want compile-time dependency verification
- Prefer functional style

### Choose Bloc if you:
- Want strict event/state separation
- Need event logging/replay
- Prefer event-driven architecture

(If you like the Bloc ecosystem but not the event boilerplate, `Cubit` is the
library's own recommended starting point — its docs suggest starting with Cubit
and scaling up to Bloc when you need transformers or an event log.)

### Choose Provider if you:
- Need the simplest solution
- Have a small app
- Want minimal dependencies
