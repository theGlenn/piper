# What is Piper?

Lifecycle-aware ViewModels for Flutter with automatic cleanup.

```dart
class SearchViewModel extends ViewModel {
  final SearchRepository _repo;

  SearchViewModel(this._repo);

  late final results = asyncState<List<Result>>();
  Task<void>? _task;

  void search(String query) {
    _task?.cancel();
    _task = launch(() async {
      await Future.delayed(Duration(milliseconds: 300));
      results.setData(await _repo.search(query));  // Won't run if disposed
    });
  }
}
```

No "mounted" checks. No stream subscriptions to manage. No manual disposal.

## Why Piper?

- **Explicit dependencies** — Constructor injection
- **Automatic lifecycle** — Subscriptions cancel, tasks stop, state disposes
- **Plain Dart** — Testable without Flutter
- **Incremental** — Works alongside existing solutions

## Core Principles

### Explicit over Magic

Dependencies are constructor parameters:

```dart
final vm = AuthViewModel(authRepository);
```

### Lifecycle-Aware

When the ViewModel disposes, everything cleans up:

```dart
class AuthViewModel extends ViewModel {
  late final user = bind(repo.userStream, initial: null);
  void logout() => load(logoutState, () => repo.logout());
}
```

### Plain Dart

Test without Flutter:

```dart
test('search', () async {
  final vm = SearchViewModel(mockRepo);
  vm.search('flutter');
  await Future.delayed(Duration(milliseconds: 300));
  expect(vm.results.hasData, isTrue);
});
```

## Good Fit If You:

- Prefer constructor injection
- Want lifecycle management without ceremony
- Come from Android/iOS (familiar ViewModel patterns)
- Want testable business logic
- Are adopting incrementally

## Next Steps

- [Getting Started](/guide/getting-started) — Install and create your first ViewModel
- [Core Concepts](/guide/state-holder) — StateHolder, AsyncState, and more
- [Examples](/examples/counter) — Complete examples
