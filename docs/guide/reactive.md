# Watch & Computed

Read state, get subscribed. `Watch` rebuilds from whatever state you read inside it, and `computed` derives new state that recomputes when its dependencies change — no manual dependency lists.

```dart
Watch((context) => Text('${vm.count.value}'))
```

## Watch

`Watch` tracks every `state.value` read inside its builder and rebuilds when any of them changes. It subscribes to exactly what you touched — nothing more.

```dart
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.vm<CounterViewModel>();
    return Watch((context) => Text('${vm.count.value}'));
  }
}
```

### Multiple values

Reading several values in one `Watch` replaces `StateBuilder2`/`StateBuilder3` and nested builders:

```dart
Watch((context) => vm.loading.value
    ? const CircularProgressIndicator()
    : Text(vm.name.value))
```

### Conditional dependencies

Dependencies are re-tracked on every build, so branches only subscribe to what they actually read:

```dart
Watch((context) {
  if (vm.useMetric.value) return Text('${vm.celsius.value}°C');
  return Text('${vm.fahrenheit.value}°F'); // celsius is not a dependency here
})
```

### Watch vs. build()

`.build()` stays the shorthand for a single leaf value — it's shorter and states its dependency explicitly:

```dart
vm.count.build((count) => Text('$count'))   // one value
```

Reach for `Watch` when a widget reads **two or more** values or has **conditional** dependencies. Prefer one `Watch` around a meaningful subtree over many tiny nested ones.

## computed()

`computed` derives a value from other state. It recomputes when a dependency changes and notifies only when the result actually differs.

```dart
late final fullName = computed(() => '${vm.first.value} ${vm.last.value}');
```

Inside a `ViewModel`, use the `computed()` helper so the derived state is disposed automatically:

```dart
class TodosViewModel extends ViewModel {
  late final todos = bindAsync<List<Todo>>(repo.todosStream);

  late final pending = computed(
    () => todos.value.dataOrNull?.where((t) => !t.completed).toList() ?? const [],
    equals: (a, b) => listEquals(a, b),
  );
}
```

A `Watch` reading `vm.pending.value` rebuilds whenever the derived list changes.

### Equality

By default a computed compares results with `==`. When the derivation allocates a new instance every run (a filtered `.toList()`, a mapped record), pass `equals` so an unchanged result doesn't notify:

```dart
final evens = computed(
  () => numbers.value.where((n) => n.isEven).toList(),
  equals: (a, b) => listEquals(a, b),
);
```

### Composition

Computeds can read other computeds. Cycles are detected and throw a `StateError`:

```dart
final doubled = computed(() => count.value * 2);
final label = computed(() => 'value: ${doubled.value}');
```

## Rules

- **Reads are tracked, writes are not.** Writing state inside a `Watch` builder or a `computed` function throws — move the write to an event handler.
- **One `Watch` per subtree.** Wrap the meaningful build body, not every `Text`.
- **`computed` for derived state.** A plain getter is not reactive and is recomputed on every access; `computed` is both.

## API Summary

| API | Returns | Use |
|-----|---------|-----|
| `Watch((context) => …)` | `Widget` | Rebuild from state read in the builder |
| `computed(() => …, {equals})` | `Computed<T>` | Derived, auto-recomputing state |
| `state.build((v) => …)` | `Widget` | Shorthand for a single leaf value |
