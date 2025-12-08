# Testing

Test ViewModels as plain Dart classes, without Flutter.

```dart
final scope = TestScope();
final vm = scope.create(() => CounterViewModel());

vm.increment();
expect(vm.count.value, 1);

scope.dispose();
```

## TestScope

```dart
late TestScope scope;

setUp(() => scope = TestScope());
tearDown(() => scope.dispose());

test('counter increments', () {
  final vm = scope.create(() => CounterViewModel());
  expect(vm.count.value, 0);
  vm.increment();
  expect(vm.count.value, 1);
});
```

## Mocking Dependencies

```dart
class MockUserRepo extends Mock implements UserRepository {}

late MockUserRepo repo;
late UserViewModel vm;

setUp(() {
  scope = TestScope();
  repo = MockUserRepo();
  vm = scope.create(() => UserViewModel(repo));
});

test('loads user', () async {
  when(() => repo.getUser('1')).thenAnswer((_) async => user);

  vm.loadUser('1');
  await Future.delayed(Duration.zero);

  expect(vm.user.hasData, isTrue);
  expect(vm.user.dataOrNull, user);
});
```

## Async State Transitions

```dart
test('loading then data', () async {
  when(() => repo.getData()).thenAnswer((_) async => data);

  expect(vm.items.isEmpty, isTrue);
  vm.loadItems();
  expect(vm.items.isLoading, isTrue);
  await Future.delayed(Duration.zero);
  expect(vm.items.hasData, isTrue);
});

test('error on failure', () async {
  when(() => repo.getData()).thenThrow(Exception('Network'));

  vm.loadItems();
  await Future.delayed(Duration.zero);

  expect(vm.items.hasError, isTrue);
});
```

## Stream Bindings

```dart
test('updates on emit', () async {
  final controller = StreamController<User>();
  when(() => repo.userStream).thenAnswer((_) => controller.stream);

  final vm = scope.create(() => AuthViewModel(repo));
  expect(vm.user.value, isNull);

  controller.add(User(name: 'Alice'));
  await Future.delayed(Duration.zero);

  expect(vm.user.value?.name, 'Alice');
  controller.close();
});
```

## Task Cancellation

```dart
test('cancels previous search', () async {
  var calls = 0;
  when(() => repo.search(any())).thenAnswer((_) async {
    calls++;
    await Future.delayed(Duration(milliseconds: 100));
    return ['result'];
  });

  vm.search('a');
  vm.search('ab');   // Cancels first
  vm.search('abc');  // Cancels second

  await Future.delayed(Duration(milliseconds: 150));

  expect(vm.results.dataOrNull, ['result']);
  expect(calls, 3);  // All called, only last updates state
});
```

## Widget Tests

```dart
testWidgets('shows user name', (tester) async {
  final repo = MockUserRepo();
  when(() => repo.userStream).thenAnswer((_) => Stream.value(User(name: 'Alice')));

  await tester.pumpWidget(
    ViewModelScope(
      create: [() => AuthViewModel(repo)],
      child: MaterialApp(home: ProfilePage()),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('Alice'), findsOneWidget);
});
```

## Tips

| Tip | Why |
|-----|-----|
| Use `TestScope` | Ensures disposal in `tearDown` |
| Mock repositories | Not ViewModels |
| `Future.delayed(Duration.zero)` | Lets async complete |
| Test state, not implementation | Check `hasData`, not internals |
