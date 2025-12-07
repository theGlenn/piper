# ViewModel

`ViewModel` is the base class for your business logic. It manages state, subscriptions, and async tasks with automatic lifecycle handling.

## Basic Structure

```dart
class ProfileViewModel extends ViewModel {
  final ProfileRepository _repo;

  ProfileViewModel(this._repo);

  // State
  late final profile = asyncState<Profile>();
  late final isEditing = state(false);

  // Methods
  void loadProfile(String id) {
    load(profile, () => _repo.getProfile(id));
  }

  void toggleEdit() {
    isEditing.update((v) => !v);
  }
}
```

## Dependency Injection

Pass dependencies through the constructor:

```dart
class OrderViewModel extends ViewModel {
  final OrderRepository _orderRepo;
  final PaymentService _paymentService;
  final AnalyticsService _analytics;

  OrderViewModel(
    this._orderRepo,
    this._paymentService,
    this._analytics,
  );
}
```

This makes dependencies explicit and testable.

## State Management

Create state holders with `state()` and `asyncState()`:

```dart
// Synchronous state
late final count = state(0);
late final name = state('');
late final isEnabled = state(true);

// Async state (loading/error/data)
late final user = asyncState<User>();
late final items = asyncState<List<Item>>();
```

## Stream Subscriptions

Subscribe to streams with automatic cleanup:

```dart
class ChatViewModel extends ViewModel {
  ChatViewModel(ChatRepository repo) {
    subscribe(repo.messagesStream, (messages) {
      this.messages.value = messages;
    });
  }

  late final messages = state<List<Message>>([]);
}
```

Or bind directly to a StateHolder:

```dart
late final user = bind(_auth.userStream, initial: null);
```

## Async Operations

### launch()

For async work where you handle the result yourself:

```dart
Task<void>? _saveTask;

void save() {
  _saveTask?.cancel();
  _saveTask = launch(() async {
    await _repo.save(data);
    isSaved.value = true;
  });
}
```

### launchWith()

For async work with success/error callbacks:

```dart
void delete(String id) {
  launchWith(
    () => _repo.delete(id),
    onSuccess: (_) => isDeleted.value = true,
    onError: (e) => error.value = e.toString(),
  );
}
```

### load()

For async work that updates an AsyncStateHolder:

```dart
void loadUser(String id) {
  load(user, () => _repo.getUser(id));
}
```

## Lifecycle

Override `dispose()` for additional cleanup (always call `super.dispose()`):

```dart
@override
void dispose() {
  // Custom cleanup
  _customController.dispose();
  super.dispose();
}
```

## What's Managed Automatically

When the ViewModel disposes:

| Resource | Cleanup |
|----------|---------|
| `state()` / `asyncState()` | Disposed |
| `bind()` / `bindAsync()` | Subscription cancelled, holder disposed |
| `subscribe()` | Cancelled |
| `launch()` / `launchWith()` / `load()` | Cancelled |

## Testing

ViewModels are plain Dart classes:

```dart
void main() {
  late TestScope scope;
  late MockRepo mockRepo;
  late MyViewModel vm;

  setUp(() {
    scope = TestScope();
    mockRepo = MockRepo();
    vm = scope.create(() => MyViewModel(mockRepo));
  });

  tearDown(() => scope.dispose());

  test('loads data', () async {
    when(() => mockRepo.getData()).thenAnswer((_) async => data);

    vm.loadData();
    await Future.delayed(Duration.zero);

    expect(vm.data.hasData, isTrue);
  });
}
```
