# Building UI

Piper provides several ways to connect state to your Flutter widgets.

## The build() Method

The primary way to bind state to UI:

```dart
vm.count.build((count) => Text('$count'))
```

This creates a widget that rebuilds whenever `count` changes.

## Pattern Matching with AsyncState

For async state, use Dart's pattern matching:

```dart
vm.user.build(
  (state) => switch (state) {
    AsyncEmpty() => Text('No user loaded'),
    AsyncLoading() => CircularProgressIndicator(),
    AsyncError(:final message) => Text('Error: $message'),
    AsyncData(:final data) => Text('Hello, ${data.name}'),
  },
)
```

## displayWhen Helper

For common patterns with sensible defaults:

```dart
vm.user.displayWhen(
  data: (user) => UserProfile(user),
  // loading: defaults to CircularProgressIndicator
  // error: defaults to red error text
  // empty: defaults to SizedBox.shrink()
)
```

Override specific states:

```dart
vm.user.displayWhen(
  data: (user) => UserProfile(user),
  loading: () => Shimmer(),
  error: (msg) => ErrorWidget(msg, onRetry: vm.loadUser),
)
```

## buildWithChild

Optimize with a static child:

```dart
vm.isLoading.buildWithChild(
  builder: (isLoading, child) => Stack(
    children: [
      child!,
      if (isLoading) LoadingOverlay(),
    ],
  ),
  child: ExpensiveWidget(),  // Not rebuilt
)
```

## Listening for Side Effects

Use `.listen()` for side effects without rebuilding:

```dart
vm.isDeleted.listen(
  onChange: (previous, current) {
    if (current) Navigator.of(context).pop();
  },
  child: DeleteButton(onPressed: vm.delete),
)
```

For async state side effects:

```dart
vm.saveResult.listenAsync(
  onData: (_) => Navigator.of(context).pop(),
  onError: (msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg)),
  ),
  child: SaveButton(onPressed: vm.save),
)
```

## Multiple State Sources

### StateBuilder Widget

For multiple state holders:

```dart
StateBuilder2(
  stateHolder1: vm.user,
  stateHolder2: vm.settings,
  builder: (context, user, settings) => // ...
)
```

### Nested Builders

Build widgets from multiple states:

```dart
vm.user.build((user) =>
  vm.posts.build((postsState) =>
    postsState.when(
      data: (posts) => UserWithPosts(user, posts),
      loading: () => UserWithPostsSkeleton(user),
      error: (msg) => UserWithError(user, msg),
      empty: () => UserWithNoPosts(user),
    ),
  ),
)
```

## Complete Example

```dart
class TodoListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.vm<TodosViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Todos'),
        actions: [
          vm.isSyncing.build(
            (syncing) => syncing
              ? Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.sync),
                  onPressed: vm.sync,
                ),
          ),
        ],
      ),
      body: vm.todos.build(
        (state) => switch (state) {
          AsyncEmpty() => Center(child: Text('No todos yet')),
          AsyncLoading() => Center(child: CircularProgressIndicator()),
          AsyncError(:final message) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error: $message'),
                ElevatedButton(
                  onPressed: vm.loadTodos,
                  child: Text('Retry'),
                ),
              ],
            ),
          ),
          AsyncData(:final data) => ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) => TodoTile(
              todo: data[i],
              onToggle: () => vm.toggle(data[i].id),
            ),
          ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, vm),
        child: Icon(Icons.add),
      ),
    );
  }
}
```
