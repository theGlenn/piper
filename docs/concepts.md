# Core Concepts

## StateHolder

Synchronous state container with change notification. Pure Dart, no Flutter dependency.

```dart
late final count = state(0);

count.value = 1;                      // Set directly
count.update((c) => c + 1);           // Transform
count.addListener(() => ...);         // Add listeners
```

## AsyncStateHolder

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

## Stream Bindings

Bind streams directly to state. Subscription auto-cancels on dispose.

```dart
// Bind stream to StateHolder
late final user = bind(_authRepo.userStream, initial: null);

// Bind with transformation
late final userName = stateFrom<User, String>(
  _authRepo.userStream,
  initial: '',
  transform: (user) => user.name,
);

// Bind to AsyncStateHolder (auto loading/error handling)
late final todos = bindAsync(_todoRepo.watchAll());
```

## ViewModel

Lifecycle-aware base class. Manages state, subscriptions, and async tasks.

```dart
class AuthViewModel extends ViewModel {
  final AuthRepository _authRepo;

  AuthViewModel(this._authRepo);

  late final user = bind(_authRepo.userStream, initial: null);
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
- `bind()` / `stateFrom()` / `bindAsync()` — subscriptions cancelled
- `subscribe()` — cancelled
- `launch()` / `launchWith()` / `load()` — cancelled

## ViewModelScope

Provides ViewModels to the widget tree.

```dart
ViewModelScope(
  create: [
    () => AuthViewModel(authRepo),
    () => TodosViewModel(todoRepo),
  ],
  child: MyApp(), // All descendants can access both VMs
)

// Access anywhere below:
final vm = context.vm<AuthViewModel>();
```

## Task

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
