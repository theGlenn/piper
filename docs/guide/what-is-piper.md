# What is Piper?

Piper is Flutter state management that cleans up after itself.

State, derived values, streams, and async tasks live in plain Dart ViewModels.
When a ViewModel disposes, Piper cleans up the work it owns.

```dart
class SearchViewModel extends ViewModel {
  final SearchRepository _repo;

  SearchViewModel(this._repo);

  late final results = asyncState<List<Result>>();
  Task<void>? _task;

  void search(String query) {
    _task?.cancel();
    _task = launch((cancellation) async {
      await cancellation.wait(
        Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      final data = await cancellation.wait(_repo.search(query));
      results.setData(data); // Won't run if cancelled or disposed
    });
  }
}
```

Cancel the search or leave the screen: the task body cannot write a stale
result. No `mounted` checks, request sequence numbers, or subscriptions to
dispose by hand.

## Why Piper?

- **Ownership is explicit** — ViewModel lifecycle owns state and async work
- **Dependencies stay visible** — Constructor injection, readable in code
- **Reactivity is automatic** — Tracked reads replace dependency lists
- **Business logic stays plain Dart** — Test without Flutter or generated files
- **Adoption is incremental** — Use Piper alongside existing solutions

## Core Principles

### State Has an Owner

When the ViewModel disposes, everything it owns cleans up:

```dart
class AuthViewModel extends ViewModel {
  late final user = bind(repo.userStream, initial: null);
  void logout() => load(logoutState, () => repo.logout());
}
```

### Dependencies Stay Visible

Dependencies are constructor parameters:

```dart
final vm = AuthViewModel(authRepository);
```

### Business Logic Stays Plain Dart

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

- Want the screen or flow to own its state and async work
- Prefer constructor injection over a global provider graph
- Like the ViewModel pattern from Android, iOS, or desktop UI
- Want business logic tests that instantiate ordinary Dart objects
- Need to adopt a state library one feature at a time

## Next Steps

- [Getting Started](/guide/getting-started) — Install and create your first ViewModel
- [Core Concepts](/guide/state-holder) — StateHolder, AsyncState, and more
- [Examples](/examples/counter) — Complete examples
