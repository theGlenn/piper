# ViewModelScope

`ViewModelScope` provides ViewModels to the widget tree and manages their lifecycle.

## Basic Usage

Wrap your app or a subtree:

```dart
ViewModelScope(
  create: [
    () => AuthViewModel(authRepo),
    () => SettingsViewModel(settingsRepo),
  ],
  child: MyApp(),
)
```

## Accessing ViewModels

Use `context.vm<T>()` to retrieve a ViewModel:

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

## Page-Level Scoping

For page-specific ViewModels:

```dart
class TodoDetailPage extends StatelessWidget {
  final String todoId;

  const TodoDetailPage({required this.todoId});

  @override
  Widget build(BuildContext context) {
    final todoRepo = context.vm<TodosViewModel>().repository;

    return ViewModelScope(
      create: [() => TodoDetailViewModel(todoRepo, todoId)],
      child: TodoDetailContent(),
    );
  }
}
```

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
