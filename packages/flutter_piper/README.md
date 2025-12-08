# flutter_piper

Flutter widgets for [Piper](https://pub.dev/packages/piper) state management.

## Installation

```yaml
dependencies:
  piper: ^0.0.1
  flutter_piper: ^0.0.1
```

## Widgets

### ViewModelScope

Provides ViewModels to the widget tree:

```dart
ViewModelScope(
  create: [
    () => AuthViewModel(authRepo),
    () => TodosViewModel(todoRepo),
  ],
  child: MyApp(),
)

// Access anywhere below:
final vm = context.vm<AuthViewModel>();
```

### StateBuilder

Rebuilds when state changes:

```dart
vm.count.build((count) => Text('$count'))
```

### StateListener

Side effects without rebuilding:

```dart
vm.isDeleted.listen(
  onChange: (prev, curr) {
    if (curr) Navigator.of(context).pop();
  },
  child: // your UI
)
```

### StateEffect

Post-frame side effects with conditions:

```dart
StateEffect<bool>(
  listenable: vm.isLoggedIn.listenable,
  when: (prev, curr) => !prev && curr,
  effect: (_, ctx) => Navigator.of(ctx).pushReplacement(...),
  child: // your UI
)
```

## Learn More

- [Piper Documentation](https://github.com/glennsonna/piper)
- [Examples](https://github.com/glennsonna/piper/tree/main/examples)
