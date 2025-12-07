# Stream Bindings

Piper provides several ways to bind streams to state holders with automatic subscription management.

## bind()

Bind a stream directly to a `StateHolder`:

```dart
class AuthViewModel extends ViewModel {
  AuthViewModel(AuthRepository auth);

  late final user = bind(_auth.userStream, initial: null);
}
```

When the stream emits, `user.value` updates automatically. The subscription cancels when the ViewModel disposes.

### With Transformation

Apply a transform to incoming values:

```dart
late final user = bind(
  _auth.userStream,
  initial: null,
  transform: (u) => u?.copyWith(name: u.name.toUpperCase()),
);
```

## stateFrom()

Bind a stream with a type transformation:

```dart
late final userName = stateFrom<User?, String>(
  _auth.userStream,
  initial: 'Guest',
  transform: (user) => user?.name ?? 'Guest',
);
```

This creates a `StateHolder<String>` from a `Stream<User?>`.

## bindAsync()

Bind a stream to an `AsyncStateHolder` with automatic loading/error handling:

```dart
late final todos = bindAsync(_todoRepo.watchAll());
```

This:
- Starts in `AsyncLoading` state
- Transitions to `AsyncData` when stream emits
- Transitions to `AsyncError` if stream errors

## subscribe()

For more control, subscribe manually:

```dart
class ChatViewModel extends ViewModel {
  ChatViewModel(ChatRepository repo) {
    subscribe(
      repo.messagesStream,
      (messages) {
        this.messages.value = messages;
        unreadCount.value = messages.where((m) => !m.read).length;
      },
      onError: (e) => error.value = e.toString(),
    );
  }

  late final messages = state<List<Message>>([]);
  late final unreadCount = state(0);
  late final error = state<String?>(null);
}
```

## Comparison

| Method | Input | Output | Use Case |
|--------|-------|--------|----------|
| `bind()` | `Stream<T>` | `StateHolder<T>` | Direct binding |
| `stateFrom()` | `Stream<T>` | `StateHolder<R>` | Transform type |
| `bindAsync()` | `Stream<T>` | `AsyncStateHolder<T>` | With loading/error |
| `subscribe()` | `Stream<T>` | void | Custom handling |

## Example: User Authentication

```dart
class AuthViewModel extends ViewModel {
  final AuthRepository _auth;

  AuthViewModel(this._auth);

  // Bind user stream directly
  late final user = bind(_auth.userStream, initial: null);

  // Derive a simple boolean
  late final isLoggedIn = stateFrom<User?, bool>(
    _auth.userStream,
    initial: false,
    transform: (user) => user != null,
  );

  // Async state for login operation
  late final loginState = asyncState<void>();

  void login(String email, String password) {
    load(loginState, () => _auth.login(email, password));
  }
}
```
