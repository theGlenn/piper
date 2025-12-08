# AsyncStateHolder

State container for async operations with loading, error, and data states.

```dart
late final user = asyncState<User>();

load(user, () => repo.getUser(id));  // Sets loading → data or error
user.hasData      // Check state
user.dataOrNull   // Access data
```

## Creating Async State

```dart
class UserViewModel extends ViewModel {
  late final user = asyncState<User>();
  late final posts = asyncState<List<Post>>();
}
```

## The Four States

```dart
sealed class AsyncState<T> {
  AsyncEmpty()
  AsyncLoading()
  AsyncError(String message, {Object? error})
  AsyncData(T data)
}
```

## Loading Data

The `load()` helper manages the full lifecycle:

```dart
void loadUser(String id) {
  load(user, () => repo.getUser(id));
}
```

1. Sets `AsyncLoading`
2. Runs async work
3. Sets `AsyncData` on success, `AsyncError` on failure
4. Cancels if ViewModel disposes

## Manual State Control

```dart
user.setLoading();
user.setData(fetchedUser);
user.setError('Failed to load');
user.setEmpty();
```

## Checking State

```dart
user.isLoading   // true if AsyncLoading
user.hasData     // true if AsyncData
user.hasError    // true if AsyncError
user.isEmpty     // true if AsyncEmpty

user.dataOrNull  // T?
user.errorOrNull // String?
```

## Building UI

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

See [Building UI](/guide/building-ui) for `displayWhen()` and `listenAsync()`.

## API Summary

| Operation | Code |
|-----------|------|
| Create | `late final user = asyncState<User>()` |
| Load | `load(user, () => repo.getUser(id))` |
| Set loading | `user.setLoading()` |
| Set data | `user.setData(data)` |
| Set error | `user.setError('message')` |
| Check | `user.isLoading`, `user.hasData` |
| Get data | `user.dataOrNull` |
| Build UI | `user.build((state) => ...)` |
