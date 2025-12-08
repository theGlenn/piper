# What is Piper?

Piper is a state management library for Flutter that prioritizes simplicity and explicit design.

## The Problem

Flutter's ecosystem offers powerful state management solutions, but they often come with trade-offs:

- **Riverpod** requires learning provider types, modifiers, and scoping rules
- **Bloc** demands event classes, state classes, and significant boilerplate
- **Provider** can lead to implicit dependency graphs that are hard to trace

These are excellent tools, but sometimes you just want something simpler.

## The Piper Approach

Piper takes a different path:

```dart
class AuthViewModel extends ViewModel {
  final AuthRepository _auth;

  AuthViewModel(this._auth);

  late final user = bind(_auth.userStream, initial: null);

  void logout() => load(logoutState, () => _auth.logout());
}
```

**What you see:**
- A plain Dart class
- Constructor injection (explicit dependencies)
- Stream binding in one line
- Async operations with automatic state management

**What happens automatically:**
- Stream subscription cancels when ViewModel disposes
- Async tasks cancel when ViewModel disposes
- State holders dispose when ViewModel disposes
- No "mounted" checks needed

## Core Principles

### Explicit over Magic

Dependencies are constructor parameters, not resolved through a provider graph. You can understand the code by reading it.

```dart
// Clear: AuthViewModel needs an AuthRepository
final vm = AuthViewModel(authRepository);
```

### Lifecycle-Aware

Everything is tied to the ViewModel lifecycle. When it disposes, everything cleans up.

```dart
class SearchViewModel extends ViewModel {
  late final results = asyncState<List<Result>>();

  Task<void>? _searchTask;

  void search(String query) {
    _searchTask?.cancel();  // Cancel previous search
    _searchTask = launch(() async {
      await Future.delayed(Duration(milliseconds: 300));  // Debounce
      final data = await _repo.search(query);
      results.setData(data);  // Won't run if disposed
    });
  }
}
```

### Plain Dart

ViewModels are just Dart classes. Test them without Flutter:

```dart
test('search returns results', () async {
  final vm = SearchViewModel(mockRepo);
  vm.search('flutter');
  await Future.delayed(Duration(milliseconds: 300));
  expect(vm.results.hasData, isTrue);
});
```

## When to Use Piper

Piper is a good fit if you:

- Prefer explicit constructor injection
- Want lifecycle management without ceremony
- Are coming from Android/iOS and want familiar ViewModel patterns
- Want to test business logic without framework utilities
- Are adopting incrementally alongside existing solutions

## Next Steps

- [Getting Started](/guide/getting-started) — Install and create your first ViewModel
- [Core Concepts](/guide/state-holder) — Learn about StateHolder, AsyncState, and more
- [Examples](/examples/counter) — See complete examples
