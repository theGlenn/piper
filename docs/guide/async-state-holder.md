# AsyncStateHolder

`AsyncStateHolder<T>` manages async operation states: empty, loading, error, and data.

## Creating Async State

Inside a ViewModel, use `asyncState<T>()`:

```dart
class UserViewModel extends ViewModel {
  late final user = asyncState<User>();
  late final posts = asyncState<List<Post>>();
}
```

## AsyncState

The holder wraps an `AsyncState<T>` sealed class with four states:

```dart
sealed class AsyncState<T> {
  // States
  AsyncEmpty()
  AsyncLoading()
  AsyncError(String message, {Object? error})
  AsyncData(T data)
}
```

## Manual State Transitions

Set states directly:

```dart
user.setLoading();
user.setData(fetchedUser);
user.setError('Failed to load user');
user.setEmpty();
```

## Using load()

The `load()` helper manages the lifecycle automatically:

```dart
void loadUser(String id) {
  load(user, () => _repo.getUser(id));
}
```

This:
1. Sets state to `AsyncLoading`
2. Runs the async work
3. Sets `AsyncData` on success or `AsyncError` on failure
4. Cancels if ViewModel disposes mid-operation

## Convenience Getters

Check state without pattern matching:

```dart
user.isLoading   // true if AsyncLoading
user.hasData     // true if AsyncData
user.hasError    // true if AsyncError
user.isEmpty     // true if AsyncEmpty

user.dataOrNull  // T? - data if available, null otherwise
user.errorOrNull // String? - error message if available
```

## Building UI

Use `.build()` with pattern matching:

```dart
vm.user.build(
  (state) => switch (state) {
    AsyncEmpty() => Text('No user'),
    AsyncLoading() => CircularProgressIndicator(),
    AsyncError(:final message) => Text('Error: $message'),
    AsyncData(:final data) => Text('Hello, ${data.name}'),
  },
)
```

Or use the `.when()` method on the state:

```dart
vm.user.build(
  (state) => state.when(
    empty: () => Text('No user'),
    loading: () => CircularProgressIndicator(),
    error: (msg) => Text('Error: $msg'),
    data: (user) => Text('Hello, ${user.name}'),
  ),
)
```

## displayWhen Helper

For common patterns, use `displayWhen()` which provides defaults:

```dart
vm.user.displayWhen(
  data: (user) => Text('Hello, ${user.name}'),
  // loading defaults to CircularProgressIndicator
  // error defaults to red error text
  // empty defaults to SizedBox.shrink()
)
```

Or just handle data with `displayWhenData()`:

```dart
vm.user.displayWhenData((user) => Text('Hello, ${user.name}'))
```

## Listening for Side Effects

React to state changes without rebuilding:

```dart
vm.saveState.listenAsync(
  onData: (data) => Navigator.of(context).pop(),
  onError: (msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg)),
  ),
  child: // rest of UI
)
```

## Summary

| Operation | Code |
|-----------|------|
| Create | `late final user = asyncState<User>();` |
| Load | `load(user, () => _repo.getUser(id))` |
| Set loading | `user.setLoading()` |
| Set data | `user.setData(data)` |
| Set error | `user.setError('message')` |
| Check state | `user.isLoading`, `user.hasData`, etc. |
| Get data | `user.dataOrNull` |
| Build UI | `user.build((state) => switch (state) { ... })` |
