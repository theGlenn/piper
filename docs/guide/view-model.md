# ViewModel

Base class for business logic with automatic lifecycle management.

```dart
class CounterViewModel extends ViewModel {
  late final count = state(0);
  void increment() => count.update((c) => c + 1);
}
```

When disposed: state holders dispose, subscriptions cancel, async tasks stop.

## Structure

```dart
class ProfileViewModel extends ViewModel {
  final ProfileRepository _repo;

  ProfileViewModel(this._repo);

  late final profile = asyncState<Profile>();
  late final isEditing = state(false);

  void loadProfile(String id) => load(profile, () => _repo.getProfile(id));
  void toggleEdit() => isEditing.update((v) => !v);
}
```

## Dependencies

Pass through constructor for explicit, testable dependencies:

```dart
class OrderViewModel extends ViewModel {
  final OrderRepository _repo;
  final PaymentService _payment;

  OrderViewModel(this._repo, this._payment);
}
```

## State

```dart
// Sync state
late final count = state(0);
late final name = state('');

// Async state
late final user = asyncState<User>();
late final items = asyncState<List<Item>>();
```

## Streams

```dart
// Bind directly
late final user = bind(repo.userStream, initial: null);

// Or subscribe manually
ChatViewModel(ChatRepository repo) {
  subscribe(repo.messagesStream, (msgs) => messages.value = msgs);
}
```

## Async Operations

```dart
// launch() — returns Task for cancellation
_task = launch(() async {
  await _repo.save(data);
  isSaved.value = true;
});

// launchWith() — callbacks
launchWith(
  () => _repo.delete(id),
  onSuccess: (_) => isDeleted.value = true,
  onError: (e) => error.value = e.toString(),
);

// load() — updates AsyncStateHolder
load(user, () => _repo.getUser(id));
```

All cancel on dispose. See [Task](/guide/task) for debouncing patterns.

## Custom Cleanup

```dart
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

## Automatic Cleanup

| Resource | On Dispose |
|----------|------------|
| `state()` / `asyncState()` | Disposed |
| `bind()` / `bindAsync()` | Cancelled, disposed |
| `subscribe()` | Cancelled |
| `launch()` / `load()` | Cancelled |
