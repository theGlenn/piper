# Task

Handle async work with cooperative cancellation. Cancelling a task settles its
result immediately, skips callbacks, and stops its body at the next
cancellation-aware boundary.

```dart
Task<void>? _task;

void search(String query) {
  _task?.cancel();
  _task = launch((cancellation) async {
    await cancellation.wait(
      Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    final data = await cancellation.wait(repo.search(query));
    results.setData(data);
  });
}
```

## How cancellation works

Dart cannot forcibly stop an arbitrary `Future`. Piper makes cancellation
cooperative:

- `task.cancel()` signals the task's `TaskCancellationToken`.
- `cancellation.wait(future)` stops waiting and throws internally when
  cancellation is requested.
- The task body unwinds, so statements after that await do not run.
- `task.result` settles with `null`.
- `launchWith` success and error callbacks do not run.

Code that never reads the token can continue running in the background. Put
`cancellation.wait(...)` around every meaningful async boundary, or call
`cancellation.throwIfCancelled()` before a side effect.

## launch()

`launch` supplies a cancellation token and returns a `Task` for manual control:

```dart
Task<void>? _task;

void search(String query) {
  _task?.cancel();
  _task = launch((cancellation) async {
    final data = await cancellation.wait(repo.search(query));
    results.setData(data);
  });
}
```

## launchWith()

Use inline success and error callbacks when the work is one operation:

```dart
final task = launchWith(
  (cancellation) => cancellation.wait(repo.save(data)),
  onSuccess: (_) => isSaved.value = true,
  onError: (e) => error.value = e.toString(),
);
```

`launchWith` returns the task, so callers can cancel it directly.

## Aborting the underlying operation

If a client exposes its own abort API, connect it with `onCancel`:

```dart
final task = launch((cancellation) async {
  final operation = repo.startUpload(file);
  final unregister = cancellation.onCancel(operation.abort);

  try {
    return await cancellation.wait(operation.result);
  } finally {
    unregister();
  }
});
```

The abort callback runs synchronously and at most once. Registering after
cancellation runs it immediately.

## Task properties

```dart
task.isCancelled  // cancel() was called
task.isCompleted  // completed, failed, or settled through cancellation
task.isActive     // running and not cancelled
```

## Awaiting results

```dart
final task = launch(
  (cancellation) => cancellation.wait(fetchData()),
);
final result = await task.result; // T? — null if cancelled
```

Non-cancellation errors keep their original error and stack trace.

## TaskScope

Manage multiple tasks:

```dart
final scope = TaskScope();
scope.launch((cancellation) => cancellation.wait(fetchUsers()));
scope.launch((cancellation) => cancellation.wait(fetchPosts()));
scope.cancelAll();
scope.dispose();
```

Completed tasks are removed from the scope automatically. ViewModels have a
built-in `taskScope`, and disposing a ViewModel disposes that scope.

## load()

`load` wraps its single future in a cancellation-aware wait automatically:

```dart
Task<User> loadUser() => load(user, () => repo.getUser());
```

Cancellation prevents the `AsyncStateHolder` from receiving data or an error.
Use `launch` directly when the work has several awaits or performs side effects.

## Patterns

### Debounced search

```dart
Task<void>? _task;

void onQueryChanged(String query) {
  _task?.cancel();
  if (query.isEmpty) {
    results.setEmpty();
    return;
  }

  results.setLoading();
  _task = launch((cancellation) async {
    await cancellation.wait(
      Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    final data = await cancellation.wait(repo.search(query));
    results.setData(data);
  });
}
```

### Sequential operations

```dart
void checkout() {
  launch((cancellation) async {
    state.setLoading();
    await cancellation.wait(cartRepo.validateCart());
    await cancellation.wait(paymentService.processPayment());
    await cancellation.wait(orderRepo.createOrder());
    state.setData(null);
  });
}
```
