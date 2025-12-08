# ViewModelScope & Scoped

Piper provides two ways to scope ViewModels in the widget tree:

- **`ViewModelScope`** — Holds multiple ViewModels, ideal for app-level or feature-level scoping
- **`Scoped<T>`** — Holds a single typed ViewModel with a builder pattern, ideal for page-level scoping

Both manage ViewModel lifecycle automatically and work with `context.vm<T>()`.

## ViewModelScope

Wrap your app or a subtree with multiple ViewModels:

```dart
ViewModelScope(
  create: [
    () => AuthViewModel(authRepo),
    () => SettingsViewModel(settingsRepo),
  ],
  child: MyApp(), // All descendants can access both VMs
)
```

## Scoped&lt;T&gt;

Scope a single ViewModel with type safety and a builder:

```dart
Scoped<DetailViewModel>(
  create: () => DetailViewModel(id),
  builder: (context, vm) => DetailPage(), // All descendants can access
)

// Any descendant
final vm = context.vm<DetailViewModel>();
```

The builder receives the ViewModel directly, so you don't need to call `context.vm<T>()` in the immediate child.

## Accessing ViewModels

Use `context.vm<T>()` to retrieve a ViewModel from either scope type:

```dart
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authVm = context.vm<AuthViewModel>();
    final settingsVm = context.vm<SettingsViewModel>();

    return // ...
  }
}
```

For `Scoped<T>`, you can also use `context.scoped<T>()` as a semantic alias:

```dart
final vm = context.scoped<DetailViewModel>();
```

## Lifecycle

ViewModels are:
- **Created eagerly** in `initState` of the ViewModelScope
- **Disposed automatically** when ViewModelScope is removed from the tree

## Nested Scopes

You can nest ViewModelScopes for feature-specific ViewModels:

```dart
// App-level
ViewModelScope(
  create: [() => AuthViewModel(authRepo)],
  child: MaterialApp(
    home: // Feature-level
      ViewModelScope(
        create: [() => TodosViewModel(todoRepo)],
        child: TodoListPage(),
      ),
  ),
)
```

## Shadowing

The same ViewModel type in a nested scope shadows the parent:

```dart
// Parent scope
ViewModelScope(
  create: [() => ThemeViewModel(lightTheme)],
  child: // Child scope
    ViewModelScope(
      create: [() => ThemeViewModel(darkTheme)],  // Shadows parent
      child: DarkThemedSection(),
    ),
)
```

`context.vm<ThemeViewModel>()` returns the nearest ancestor.

## Dependency Injection Pattern

Create dependencies at app startup and pass to ViewModels:

```dart
void main() {
  // Create dependencies
  final authRepo = AuthRepository(apiClient);
  final todoRepo = TodoRepository(database);

  runApp(
    ViewModelScope(
      create: [
        () => AuthViewModel(authRepo),
        () => TodosViewModel(todoRepo),
      ],
      child: MyApp(),
    ),
  );
}
```

## Page-Level Scoping with Scoped&lt;T&gt;

`Scoped<T>` is ideal for page-specific ViewModels:

```dart
class TodoDetailPage extends StatelessWidget {
  final String todoId;

  const TodoDetailPage({required this.todoId});

  @override
  Widget build(BuildContext context) {
    final todoRepo = context.vm<TodosViewModel>().repository;

    return Scoped<TodoDetailViewModel>(
      create: () => TodoDetailViewModel(todoRepo, todoId),
      builder: (context, vm) => TodoDetailContent(),
    );
  }
}
```

Benefits of `Scoped<T>`:
- Type is explicit in the widget declaration
- Builder receives the ViewModel directly
- Clear single-responsibility: one widget, one ViewModel

## Without ViewModelScope

You can create ViewModels manually, but you're responsible for disposal:

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

ViewModelScope handles this automatically.
