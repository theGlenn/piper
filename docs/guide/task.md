# Task

Handle to async work with cancellation. Cancelled tasks don't update state.

```dart
Task<void>? _task;

void search(String query) {
  _task?.cancel();
  _task = launch(() async {
    await Future.delayed(Duration(milliseconds: 300));
    results.setData(await repo.search(query));  // Won't run if cancelled
  });
}
```

## Why Tasks?

Without Piper, async operations need manual `mounted` checks:

```dart
void loadData() async {
  final data = await repo.getData();
  if (mounted) setState(() => _data = data);  // Tedious
}
```

With Piper, cancelled tasks simply don't update state:

```dart
void loadData() => load(data, () => repo.getData());
```

## How It Works

Tasks use "ignore-on-cancel":
- The Future runs to completion (can't stop a Future)
- If cancelled, results are discarded
- Callbacks don't fire, state doesn't update

## launch()

Returns a `Task` handle for manual control:

```dart
Task<void>? _task;

void search(String query) {
  _task?.cancel();
  _task = launch(() async {
    await Future.delayed(Duration(milliseconds: 300));
    results.setData(await repo.search(query));
  });
}
```

## launchWith()

Inline success/error callbacks:

```dart
launchWith(
  () => repo.save(data),
  onSuccess: (_) => isSaved.value = true,
  onError: (e) => error.value = e.toString(),
);
```

## Task Properties

```dart
task.isCancelled  // cancel() was called
task.isCompleted  // Future completed
task.isActive     // running and not cancelled
```

## Await Results

```dart
final task = launch(() => fetchData());
final result = await task.result;  // T? - null if cancelled
```

## TaskScope

Manage multiple tasks:

```dart
final scope = TaskScope();
scope.launch(() => fetchUsers());
scope.launch(() => fetchPosts());
scope.cancelAll();
scope.dispose();
```

ViewModels have a built-in `taskScope`.

## Patterns

### Debounced Search

```dart
Task<void>? _task;

void onQueryChanged(String query) {
  _task?.cancel();
  if (query.isEmpty) return results.setEmpty();

  results.setLoading();
  _task = launch(() async {
    await Future.delayed(Duration(milliseconds: 300));
    results.setData(await repo.search(query));
  });
}
```

### Cancel Previous

```dart
Task<void>? _task;

void loadCategory(String id) {
  _task?.cancel();
  _task = launch(() async {
    items.setLoading();
    items.setData(await repo.getItems(id));
  });
}
```

### Sequential Operations

```dart
void checkout() {
  launch(() async {
    state.setLoading();
    await cartRepo.validateCart();
    await paymentService.processPayment();
    await orderRepo.createOrder();
    state.setData(null);  // Won't run if user leaves
  });
}
```
