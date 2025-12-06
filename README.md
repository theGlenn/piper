# Piper 🚰

State management that gets out of your way.

Lifecycle-aware ViewModels, explicit dependencies, automatic cleanup. Patterns that have worked for years — now in Flutter.

## Why Piper?

- **Explicit dependencies** — Constructor injection, not magic. You can trace the dependency graph by reading the code.
- **Automatic lifecycle management** — No more `if (mounted)` checks. Subscriptions cancel, tasks stop, state disposes.
- **Plain Dart classes** — ViewModels are just Dart. Test without Flutter, mock without framework internals.
- **Incremental adoption** — Works alongside your existing state solution. Migrate at your own pace.

## Installation

```yaml
dependencies:
  piper: ^0.1.0
  flutter_piper: ^0.1.0  # Flutter widgets
```

## Quick Start

```dart
// 1. Define your ViewModel
class CounterViewModel extends ViewModel {
  late final count = state(0);

  void increment() => count.update((c) => c + 1);
}

// 2. Provide it to the widget tree
ViewModelScope(
  create: [() => CounterViewModel()],
  child: MyApp(),
)

// 3. Use it in widgets
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.vm<CounterViewModel>();

    return StateBuilder(
      listenable: vm.count.listenable,
      builder: (context, count) => Text('Count: $count'),
    );
  }
}
```

## Real-World Example: Search with Cancellation

Search with debounce usually requires RxDart or complex stream manipulation. With Piper:

```dart
class SearchViewModel extends ViewModel {
  final SearchRepository _repo;

  SearchViewModel(this._repo);

  late final query = state('');
  late final results = asyncState<List<SearchResult>>();

  Task<void>? _searchTask;

  void onQueryChanged(String value) {
    query.value = value;

    // Cancel previous search — no stale results
    _searchTask?.cancel();

    if (value.isEmpty) {
      results.setEmpty();
      return;
    }

    results.setLoading();

    _searchTask = launch(() async {
      // Debounce — just wait
      await Future.delayed(const Duration(milliseconds: 300));

      final data = await _repo.search(value);
      results.setData(data);
    });
  }
}
```

The widget:

```dart
StateBuilder(
  listenable: vm.results.listenable,
  builder: (context, state) => state.when(
    empty: () => Text('Start typing to search'),
    loading: () => CircularProgressIndicator(),
    error: (msg) => Text('Error: $msg'),
    data: (items) => ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, i) => ListTile(title: Text(items[i].title)),
    ),
  ),
)
```

No RxDart. No stream transformers. Cancel, wait, search.

## Core Concepts

### StateHolder

Synchronous state container. Wraps `ValueNotifier` with a cleaner API.

```dart
late final count = state(0);

count.value = 1;                      // Set directly
count.update((c) => c + 1);           // Transform
count.listenable                      // Bind to widgets
```

### AsyncStateHolder

For async operations. Handles loading, error, and data states.

```dart
late final user = asyncState<User>();

user.setLoading();
user.setData(fetchedUser);
user.setError('Failed to load');
user.setEmpty();

// Or use the load() helper:
void loadUser() => load(user, () => _repo.getUser());
```

### Stream Bindings

Bind streams directly to state. Subscription auto-cancels on dispose.

```dart
// Bind stream to StateHolder
late final user = streamTo<User?>(_authRepo.userStream, initial: null);

// Bind with transformation
late final userName = stateFrom<User, String>(
  _authRepo.userStream,
  initial: '',
  transform: (user) => user.name,
);

// Bind to AsyncStateHolder (auto loading/error handling)
late final todos = streamToAsync<List<Todo>>(_todoRepo.watchAll());
```

### ViewModel

Lifecycle-aware base class. Manages state, subscriptions, and async tasks.

```dart
class AuthViewModel extends ViewModel {
  final AuthRepository _authRepo;

  AuthViewModel(this._authRepo);

  // Stream bound to state — one line
  late final user = streamTo<User?>(_authRepo.userStream, initial: null);
  late final loginState = asyncState<void>();

  void login(String email, String password) {
    load(loginState, () => _authRepo.login(email, password));
  }

  void logout() {
    load(loginState, () => _authRepo.logout());
  }
}
```

**Managed automatically:**
- `state()` / `asyncState()` — disposed
- `streamTo()` / `stateFrom()` / `streamToAsync()` — subscriptions cancelled
- `subscribe()` — cancelled
- `launch()` / `launchWith()` / `load()` — cancelled

### ViewModelScope

Provides ViewModels to the widget tree.

```dart
ViewModelScope(
  create: [
    () => AuthViewModel(authRepo),
    () => TodosViewModel(todoRepo),
  ],
  child: MyApp(),
)

// Access anywhere below:
final vm = context.vm<AuthViewModel>();
```

### Task

Handle to async work with cancellation support.

```dart
Task<void>? _saveTask;

void save() {
  _saveTask?.cancel();  // Cancel previous
  _saveTask = launch(() async {
    await _repo.save(data);
    saved.value = true;
  });
}
```

Cancelled tasks don't update state. No race conditions.

## Comparison

### vs. Riverpod

| Aspect | Riverpod | Piper |
|--------|----------|-------|
| Dependencies | `ref.watch`, `ref.read` | Constructor injection |
| Learning curve | Provider types, modifiers, scoping | Plain Dart classes |
| State declaration | Providers with annotations | `state()` in ViewModel |
| Async state | `AsyncValue`, `.when()` | `AsyncState`, `.when()` |
| Testing | `ProviderContainer` | Plain unit tests |

### vs. Bloc

| Aspect | Bloc | Piper |
|--------|------|-------|
| State changes | Events → Bloc → States | Methods → State |
| Boilerplate | Event classes, State classes | Just methods |
| Async handling | `emit()` with streams | `launch()`, `load()` |
| Testing | `blocTest()` | Plain unit tests |

## Testing

ViewModels are plain Dart. Test them directly:

```dart
void main() {
  late TestScope scope;
  late MockTodoRepo mockRepo;
  late TodosViewModel vm;

  setUp(() {
    scope = TestScope();
    mockRepo = MockTodoRepo();
    vm = scope.create(() => TodosViewModel(mockRepo));
  });

  tearDown(() => scope.dispose());

  test('loads todos from repository', () async {
    when(() => mockRepo.fetchTodos()).thenAnswer((_) async => [todo]);

    vm.loadTodos();
    await Future.delayed(Duration.zero);

    expect(vm.todos.hasData, isTrue);
    expect(vm.todos.dataOrNull, [todo]);
  });
}
```

## Incremental Adoption

Piper works alongside existing solutions. Start with one feature:

1. Create a ViewModel for a new feature
2. Wrap that feature's widget subtree in `ViewModelScope`
3. Existing code continues to work unchanged

No big-bang migration required.

## Package Structure

- **`piper`** — Core library (ViewModel, StateHolder, Task). No Flutter dependency.
- **`flutter_piper`** — Flutter widgets (ViewModelScope, StateBuilder). Depends on `piper`.

Use `piper` alone for pure Dart projects. Add `flutter_piper` for Flutter apps.

## License

MIT
