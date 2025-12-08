# Building UI

Connect state to widgets with `.build()`, `.displayWhen()`, and `.listen()`.

```dart
vm.count.build((count) => Text('$count'))
```

## build()

Rebuild widget when state changes:

```dart
vm.count.build((count) => Text('$count'))
```

## Pattern Matching (AsyncState)

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

## displayWhen()

Handle async states with sensible defaults:

```dart
vm.user.displayWhen(
  data: (user) => UserProfile(user),
  // loading: CircularProgressIndicator (default)
  // error: red error text (default)
  // empty: SizedBox.shrink() (default)
)
```

Override specific states:

```dart
vm.user.displayWhen(
  data: (user) => UserProfile(user),
  loading: () => Shimmer(),
  error: (msg) => RetryButton(msg, onRetry: vm.load),
)
```

## buildWithChild()

Optimize with static child:

```dart
vm.isLoading.buildWithChild(
  builder: (loading, child) => Stack(
    children: [child!, if (loading) LoadingOverlay()],
  ),
  child: ExpensiveWidget(),  // Not rebuilt
)
```

## listen()

Side effects without rebuilding:

```dart
vm.isDeleted.listen(
  onChange: (prev, curr) {
    if (curr) Navigator.of(context).pop();
  },
  child: DeleteButton(),
)
```

## listenAsync()

Side effects for async state:

```dart
vm.saveResult.listenAsync(
  onData: (_) => Navigator.of(context).pop(),
  onError: (msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg)),
  ),
  child: SaveButton(),
)
```

## Multiple States

### StateBuilder2/3/4

```dart
StateBuilder2(
  stateHolder1: vm.user,
  stateHolder2: vm.settings,
  builder: (context, user, settings) => ...,
)
```

### Nested Builders

```dart
vm.user.build((user) =>
  vm.posts.build((state) => state.when(
    data: (posts) => UserWithPosts(user, posts),
    loading: () => Skeleton(user),
    error: (msg) => Error(msg),
    empty: () => Empty(),
  )),
)
```

## API Summary

| Method | Purpose |
|--------|---------|
| `build()` | Rebuild on change |
| `displayWhen()` | Async state with defaults |
| `buildWithChild()` | Static child optimization |
| `listen()` | Side effects (sync) |
| `listenAsync()` | Side effects (async) |
| `StateBuilder2/3/4` | Multiple state sources |
