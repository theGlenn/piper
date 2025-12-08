# ViewModelScope & Scoped

Provide ViewModels to the widget tree with automatic lifecycle management.

```dart
ViewModelScope(
  create: [() => AuthViewModel(repo)],
  child: MyApp(),
)

// Access anywhere below
final vm = context.vm<AuthViewModel>();
```

Two options:
- **`ViewModelScope`** — Multiple ViewModels, app/feature level
- **`Scoped<T>`** — Single ViewModel with builder, page level

## ViewModelScope

```dart
ViewModelScope(
  create: [
    () => AuthViewModel(authRepo),
    () => SettingsViewModel(settingsRepo),
  ],
  child: MyApp(),
)
```

### With BuildContext

```dart
ViewModelScope.withContext(
  create: [
    (context) => AuthViewModel(context.read<AuthRepository>()),
  ],
  child: MyApp(),
)
```

## Scoped&lt;T&gt;

Single ViewModel with type-safe builder:

```dart
Scoped<DetailViewModel>(
  create: () => DetailViewModel(id),
  builder: (context, vm) => DetailPage(),
)
```

### With BuildContext

```dart
Scoped<DetailViewModel>.withContext(
  create: (context) => DetailViewModel(context.read<Repository>()),
  builder: (context, vm) => DetailPage(),
)
```

## Accessing ViewModels

```dart
final vm = context.vm<AuthViewModel>();
final vm = context.maybeVm<AuthViewModel>();  // nullable
final vm = context.scoped<DetailViewModel>(); // alias for vm<T>()
```

## Lifecycle

- Created once when scope builds
- Disposed when scope leaves tree

## Nested Scopes

```dart
ViewModelScope(
  create: [() => AuthViewModel(repo)],
  child: MaterialApp(
    home: ViewModelScope(
      create: [() => TodosViewModel(repo)],
      child: TodoListPage(),
    ),
  ),
)
```

## Shadowing

Same type in nested scope shadows parent:

```dart
ViewModelScope(
  create: [() => ThemeViewModel(light)],
  child: ViewModelScope(
    create: [() => ThemeViewModel(dark)],  // Shadows
    child: DarkSection(),
  ),
)
```

`context.vm<ThemeViewModel>()` returns nearest ancestor.

## Named Scopes

Share ViewModels across routes in multi-step flows:

```dart
ViewModelScope(
  name: 'checkout',
  create: [() => CheckoutViewModel()],
  child: CheckoutFlow(),
)

// Access by name
final vm = context.vm<CheckoutViewModel>(scope: 'checkout');
```

Use cases:
- Multi-step flows (checkout, onboarding)
- Nested navigators
- Explicit scope targeting when shadowing

## Manual Creation

Without scope, manage disposal yourself:

```dart
class _MyPageState extends State<MyPage> {
  late final _vm = MyViewModel(repo);

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }
}
```

## API Summary

### ViewModelScope

| Constructor | Use |
|-------------|-----|
| `ViewModelScope(create: [...])` | Without context |
| `ViewModelScope.withContext(create: [...])` | With context |

Both support optional `name` parameter.

### Scoped&lt;T&gt;

| Constructor | Use |
|-------------|-----|
| `Scoped<T>(create: ...)` | Without context |
| `Scoped<T>.withContext(create: ...)` | With context |

### Context Extensions

| Method | Returns |
|--------|---------|
| `context.vm<T>()` | T (throws if not found) |
| `context.vm<T>(scope: 'name')` | T from named scope |
| `context.maybeVm<T>()` | T? (null if not found) |
| `context.scoped<T>()` | Alias for `vm<T>()` |

::: tip
For dependency wiring patterns (InheritedWidget, get_it, Provider), see [Dependency Injection](/guide/dependency-injection).
:::
