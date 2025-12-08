# Core Concepts

Quick reference for Piper's main components.

| Concept | Purpose | Guide |
|---------|---------|-------|
| [StateHolder](/guide/state-holder) | Synchronous state container | `state(0)` |
| [AsyncStateHolder](/guide/async-state-holder) | Async operations (loading/error/data) | `asyncState<User>()` |
| [Stream Bindings](/guide/stream-bindings) | Bind streams to state | `bind(stream, initial: null)` |
| [ViewModel](/guide/view-model) | Lifecycle-aware business logic | `extends ViewModel` |
| [ViewModelScope](/guide/view-model-scope) | Provide VMs to widget tree | `context.vm<T>()` |
| [Task](/guide/task) | Cancellable async work | `launch(() async { ... })` |
| [Building UI](/guide/building-ui) | Connect state to widgets | `.build()`, `.displayWhen()` |
| [Testing](/guide/testing) | Test VMs without Flutter | `TestScope` |

## At a Glance

```dart
class SearchViewModel extends ViewModel {
  final SearchRepository _repo;

  SearchViewModel(this._repo);

  // Sync state
  late final query = state('');

  // Async state
  late final results = asyncState<List<Result>>();

  // Stream binding
  late final user = bind(_auth.userStream, initial: null);

  // Cancellable async work
  Task<void>? _searchTask;

  void search(String q) {
    query.value = q;
    _searchTask?.cancel();
    _searchTask = launch(() async {
      await Future.delayed(Duration(milliseconds: 300));
      final data = await _repo.search(q);
      results.setData(data);
    });
  }
}
```

When the ViewModel disposes:
- State holders dispose
- Stream subscriptions cancel
- Tasks cancel (callbacks don't run)
