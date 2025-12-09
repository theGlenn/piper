# flutter_piper

Flutter widgets for [Piper State](https://pub.dev/packages/piper_state) state management.

## Installation

```yaml
dependencies:
  piper_state: ^0.0.2
  flutter_piper: ^0.0.2
```

## Widgets

### ViewModelScope

Provides multiple ViewModels to the widget tree:

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

### Scoped&lt;T&gt;

Scopes a single typed ViewModel with a builder pattern:

```dart
Scoped<DetailViewModel>(
  create: () => DetailViewModel(id),
  builder: (context, vm) => DetailPage(),
)

// Access via context:
final vm = context.vm<DetailViewModel>();
// Or use the semantic alias:
final vm = context.scoped<DetailViewModel>();
```

### Named Scopes

Share ViewModels across multiple routes with named scopes:

```dart
ViewModelScope.named(
  name: 'checkout',
  create: [() => CheckoutViewModel()],
  child: CheckoutFlow(),
)

// Access by name from any descendant:
final vm = context.vm<CheckoutViewModel>(scope: 'checkout');
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
