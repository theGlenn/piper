# StateHolder

`StateHolder<T>` is a synchronous state container that wraps Flutter's `ValueNotifier` with a cleaner API.

## Creating State

Inside a ViewModel, use `state()` to create a managed StateHolder:

```dart
class CounterViewModel extends ViewModel {
  late final count = state(0);
  late final name = state('');
  late final items = state<List<String>>([]);
}
```

The StateHolder is automatically disposed when the ViewModel disposes.

## Reading State

Access the current value with `.value`:

```dart
int currentCount = vm.count.value;
String currentName = vm.name.value;
```

## Writing State

Set a new value directly:

```dart
vm.count.value = 10;
vm.name.value = 'Alice';
```

Or update based on the current value:

```dart
vm.count.update((current) => current + 1);
vm.items.update((list) => [...list, 'new item']);
```

## Building UI

Use `.build()` to create a widget that rebuilds on state changes:

```dart
vm.count.build((count) => Text('Count: $count'))
```

This is equivalent to:

```dart
ValueListenableBuilder<int>(
  valueListenable: vm.count.listenable,
  builder: (_, count, __) => Text('Count: $count'),
)
```

## Listening Without Rebuilding

For side effects (navigation, snackbars), use `.listen()`:

```dart
vm.isDeleted.listen(
  onChange: (previous, current) {
    if (current) Navigator.of(context).pop();
  },
  child: // rest of UI
)
```

## Accessing the Listenable

If you need the underlying `ValueListenable` (for `AnimatedBuilder`, etc.):

```dart
ValueListenable<int> listenable = vm.count.listenable;
```

## Outside ViewModels

You can create standalone StateHolders, but you're responsible for disposal:

```dart
final counter = StateHolder(0);
// ... use it ...
counter.dispose();
```

Inside ViewModels, always use `state()` for automatic lifecycle management.

## Summary

| Operation | Code |
|-----------|------|
| Create | `late final count = state(0);` |
| Read | `count.value` |
| Write | `count.value = 10` |
| Update | `count.update((c) => c + 1)` |
| Build UI | `count.build((v) => Text('$v'))` |
| Listen | `count.listen(onChange: ..., child: ...)` |
