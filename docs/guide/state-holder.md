# StateHolder

Synchronous state container with change notification. Pure Dart, no Flutter dependency.

```dart
late final count = state(0);

count.value = 10;               // Set
count.update((c) => c + 1);     // Transform
count.build((v) => Text('$v'))  // Rebuild on change
```

## Creating State

```dart
class CounterViewModel extends ViewModel {
  late final count = state(0);
  late final name = state('');
  late final items = state<List<String>>([]);
}
```

Automatically disposed when the ViewModel disposes.

## Reading and Writing

```dart
// Read
int current = vm.count.value;

// Write directly
vm.count.value = 10;

// Transform current value
vm.count.update((c) => c + 1);
vm.items.update((list) => [...list, 'new']);
```

## Building UI

```dart
vm.count.build((count) => Text('$count'))
```

See [Building UI](/guide/building-ui) for `buildWithChild()` and other patterns.

## Side Effects

For navigation, snackbars, or other effects without rebuilding:

```dart
vm.isDeleted.listen(
  onChange: (prev, curr) {
    if (curr) Navigator.of(context).pop();
  },
  child: DeleteButton(),
)
```

## Standalone Usage

Outside ViewModels, manage disposal manually:

```dart
final counter = StateHolder(0);
// ...
counter.dispose();
```

## API Summary

| Operation | Code |
|-----------|------|
| Create | `late final count = state(0)` |
| Read | `count.value` |
| Write | `count.value = 10` |
| Update | `count.update((c) => c + 1)` |
| Build UI | `count.build((v) => Text('$v'))` |
| Listen | `count.listen(onChange: ..., child: ...)` |
