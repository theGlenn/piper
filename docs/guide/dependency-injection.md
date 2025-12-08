# Dependency Injection

Wire dependencies to ViewModels however you prefer. Piper doesn't impose a DI solution.

```dart
ViewModelScope(
  create: [() => AuthViewModel(getIt<AuthRepository>())],
  child: MyApp(),
)
```

## Quick Reference

| Approach | Context | ViewModelScope |
|----------|---------|----------------|
| InheritedWidget | Yes | `.withContext` |
| get_it | No | Regular |
| injectable | No | Regular |
| Provider | Yes | `.withContext` |

## InheritedWidget

No external packages:

```dart
class AppDependencies extends InheritedWidget {
  final AuthRepository authRepo;
  final TodoRepository todoRepo;

  const AppDependencies({
    required this.authRepo,
    required this.todoRepo,
    required super.child,
  });

  static AppDependencies of(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<AppDependencies>()!;

  @override
  bool updateShouldNotify(AppDependencies old) => false;
}
```

```dart
runApp(
  AppDependencies(
    authRepo: AuthRepository(ApiClient()),
    todoRepo: TodoRepository(Database()),
    child: ViewModelScope.withContext(
      create: [(context) => AuthViewModel(AppDependencies.of(context).authRepo)],
      child: MyApp(),
    ),
  ),
);
```

## get_it

Service locator without context:

```dart
final getIt = GetIt.instance;

void setup() {
  getIt.registerSingleton<AuthRepository>(AuthRepository(ApiClient()));
  getIt.registerSingleton<TodoRepository>(TodoRepository(Database()));
}

void main() {
  setup();
  runApp(
    ViewModelScope(
      create: [
        () => AuthViewModel(getIt<AuthRepository>()),
        () => TodosViewModel(getIt<TodoRepository>()),
      ],
      child: MyApp(),
    ),
  );
}
```

### With injectable

```dart
@singleton
class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;
}

// dart run build_runner build
@InjectableInit()
void configureDependencies() => getIt.init();
```

## Provider

Widget tree integration:

```dart
runApp(
  MultiProvider(
    providers: [
      Provider(create: (_) => AuthRepository(ApiClient())),
      Provider(create: (_) => TodoRepository(Database())),
    ],
    child: ViewModelScope.withContext(
      create: [(context) => AuthViewModel(context.read<AuthRepository>())],
      child: MyApp(),
    ),
  ),
);
```

## Comparison

| Approach | Pros | Cons |
|----------|------|------|
| InheritedWidget | No deps, built-in | Boilerplate |
| get_it | Simple, no context | Global state |
| injectable | Auto-registration | Build step |
| Provider | Widget tree integration | Requires context |

**Recommendations:**
- Small apps → InheritedWidget
- Medium apps → Provider
- Large apps → injectable + get_it

## Testing

Constructor injection makes testing simple:

```dart
test('login', () async {
  final repo = MockAuthRepository();
  final scope = TestScope();
  final vm = scope.create(() => AuthViewModel(repo));

  when(() => repo.login(any(), any())).thenAnswer((_) async => user);
  vm.login('test@example.com', 'password');
  await Future.delayed(Duration.zero);

  expect(vm.loginState.hasData, isTrue);
  scope.dispose();
});
```
