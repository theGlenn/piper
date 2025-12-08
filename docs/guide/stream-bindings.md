# Stream Bindings

Bind streams to state holders with automatic subscription management.

```dart
late final user = bind(repo.userStream, initial: null);
// Subscription auto-cancels on ViewModel dispose
```

## bind()

Bind a stream directly to a `StateHolder`:

```dart
class AuthViewModel extends ViewModel {
  late final user = bind(repo.userStream, initial: null);
}
```

When the stream emits, `user.value` updates automatically.

### With Transform

```dart
late final user = bind(
  repo.userStream,
  initial: null,
  transform: (u) => u?.copyWith(name: u.name.toUpperCase()),
);
```

## stateFrom()

Bind with type transformation:

```dart
late final isLoggedIn = stateFrom<User?, bool>(
  repo.userStream,
  initial: false,
  transform: (user) => user != null,
);
```

Creates `StateHolder<bool>` from `Stream<User?>`.

## bindAsync()

Bind to `AsyncStateHolder` with loading/error handling:

```dart
late final todos = bindAsync(repo.watchAll());
```

- Starts in `AsyncLoading`
- Transitions to `AsyncData` on emit
- Transitions to `AsyncError` on error

## subscribe()

For custom handling:

```dart
class ChatViewModel extends ViewModel {
  late final messages = state<List<Message>>([]);
  late final unreadCount = state(0);

  ChatViewModel(ChatRepository repo) {
    subscribe(
      repo.messagesStream,
      (msgs) {
        messages.value = msgs;
        unreadCount.value = msgs.where((m) => !m.read).length;
      },
      onError: (e) => error.value = e.toString(),
    );
  }
}
```

## API Summary

| Method | Output | Use Case |
|--------|--------|----------|
| `bind()` | `StateHolder<T>` | Direct binding |
| `stateFrom()` | `StateHolder<R>` | Type transform |
| `bindAsync()` | `AsyncStateHolder<T>` | With loading/error |
| `subscribe()` | void | Custom handling |
