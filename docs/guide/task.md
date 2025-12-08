# Task

`Task<T>` is a handle to async work that supports cancellation using the "ignore-on-cancel" pattern.

## The Problem

In Flutter, async operations often complete after a widget disposes:

```dart
// Without Piper: manual mounted checks
void loadData() async {
  final data = await _repo.getData();
  if (mounted) {  // Tedious and error-prone
    setState(() => _data = data);
  }
}
```

## The Solution

With Piper, cancelled tasks simply don't update state:

```dart
void loadData() {
  load(data, () => _repo.getData());
  // If ViewModel disposes, the callback won't run
}
```

## How Tasks Work

Tasks use the "ignore-on-cancel" pattern:
- The underlying `Future` runs to completion (can't stop a Future)
- But if cancelled, the result is discarded
- Callbacks don't fire, state doesn't update

## Using launch()

Get a `Task` handle for manual control:

```dart
Task<void>? _searchTask;

void search(String query) {
  // Cancel previous search
  _searchTask?.cancel();

  _searchTask = launch(() async {
    // Debounce
    await Future.delayed(Duration(milliseconds: 300));

    final results = await _repo.search(query);
    searchResults.setData(results);  // Won't run if cancelled
  });
}
```

## Task Properties

```dart
task.isCancelled  // true if cancel() was called
task.isCompleted  // true if Future completed
task.isActive     // true if running and not cancelled
```

## Awaiting Results

Get the result (or null if cancelled):

```dart
final task = launch(() => fetchData());
final result = await task.result;  // T? - null if cancelled
```

## Using launchWith()

For inline callbacks:

```dart
void save() {
  launchWith(
    () => _repo.save(data),
    onSuccess: (result) {
      isSaved.value = true;
      // Won't run if ViewModel disposed
    },
    onError: (error) {
      this.error.value = error.toString();
      // Won't run if ViewModel disposed
    },
  );
}
```

## TaskScope

`TaskScope` manages multiple tasks:

```dart
final scope = TaskScope();

scope.launch(() => fetchUsers());
scope.launch(() => fetchPosts());

scope.cancelAll();  // Cancel all tasks
scope.dispose();    // Cancel and prevent new launches
```

ViewModels have a built-in TaskScope accessible via `taskScope`.

## Common Patterns

### Debounced Search

```dart
Task<void>? _searchTask;

void onQueryChanged(String query) {
  _searchTask?.cancel();

  if (query.isEmpty) {
    results.setEmpty();
    return;
  }

  results.setLoading();

  _searchTask = launch(() async {
    await Future.delayed(Duration(milliseconds: 300));
    final data = await _repo.search(query);
    results.setData(data);
  });
}
```

### Cancel Previous Request

```dart
Task<void>? _loadTask;

void loadCategory(String id) {
  _loadTask?.cancel();  // Cancel if user switches quickly
  _loadTask = launch(() async {
    items.setLoading();
    final data = await _repo.getItems(id);
    items.setData(data);
  });
}
```

### Sequential Operations

```dart
void checkout() {
  launch(() async {
    checkoutState.setLoading();

    await _cartRepo.validateCart();
    await _paymentService.processPayment();
    await _orderRepo.createOrder();

    checkoutState.setData(null);
    // None of this runs if user leaves the page
  });
}
```
