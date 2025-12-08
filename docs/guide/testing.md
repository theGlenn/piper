# Testing

ViewModels are plain Dart classes, making them easy to test without Flutter.

## TestScope

Use `TestScope` to create and manage ViewModels in tests:

```dart
import 'package:piper/piper.dart';
import 'package:test/test.dart';

void main() {
  late TestScope scope;

  setUp(() {
    scope = TestScope();
  });

  tearDown(() {
    scope.dispose();
  });

  test('counter increments', () {
    final vm = scope.create(() => CounterViewModel());

    expect(vm.count.value, 0);
    vm.increment();
    expect(vm.count.value, 1);
  });
}
```

## Mocking Dependencies

Pass mock dependencies through constructors:

```dart
import 'package:mocktail/mocktail.dart';

class MockUserRepo extends Mock implements UserRepository {}

void main() {
  late TestScope scope;
  late MockUserRepo mockRepo;
  late UserViewModel vm;

  setUp(() {
    scope = TestScope();
    mockRepo = MockUserRepo();
    vm = scope.create(() => UserViewModel(mockRepo));
  });

  tearDown(() => scope.dispose());

  test('loads user from repository', () async {
    final user = User(id: '1', name: 'Alice');
    when(() => mockRepo.getUser('1')).thenAnswer((_) async => user);

    vm.loadUser('1');

    // Wait for async operation
    await Future.delayed(Duration.zero);

    expect(vm.user.hasData, isTrue);
    expect(vm.user.dataOrNull, user);
  });
}
```

## Testing Async State

Check state transitions:

```dart
test('shows loading then data', () async {
  when(() => mockRepo.getData()).thenAnswer((_) async => data);

  expect(vm.items.isEmpty, isTrue);  // Initial state

  vm.loadItems();

  expect(vm.items.isLoading, isTrue);  // Loading state

  await Future.delayed(Duration.zero);

  expect(vm.items.hasData, isTrue);  // Data state
  expect(vm.items.dataOrNull, data);
});

test('shows error on failure', () async {
  when(() => mockRepo.getData()).thenThrow(Exception('Network error'));

  vm.loadItems();
  await Future.delayed(Duration.zero);

  expect(vm.items.hasError, isTrue);
  expect(vm.items.errorOrNull, contains('Network error'));
});
```

## Testing Streams

Test stream bindings with StreamControllers:

```dart
test('updates when stream emits', () async {
  final controller = StreamController<User>();
  when(() => mockRepo.userStream).thenAnswer((_) => controller.stream);

  final vm = scope.create(() => AuthViewModel(mockRepo));

  expect(vm.user.value, isNull);

  controller.add(User(id: '1', name: 'Alice'));
  await Future.delayed(Duration.zero);

  expect(vm.user.value?.name, 'Alice');

  controller.close();
});
```

## Testing Task Cancellation

Verify cancellation behavior:

```dart
test('cancels previous search', () async {
  var callCount = 0;
  when(() => mockRepo.search(any())).thenAnswer((_) async {
    callCount++;
    await Future.delayed(Duration(milliseconds: 100));
    return ['result'];
  });

  vm.search('a');
  vm.search('ab');  // Should cancel first
  vm.search('abc');  // Should cancel second

  await Future.delayed(Duration(milliseconds: 150));

  // Only the last search should complete
  expect(vm.results.dataOrNull, ['result']);
  expect(callCount, 3);  // All called, but only last updates state
});
```

## Widget Testing

For widget tests, provide ViewModels via ViewModelScope:

```dart
testWidgets('shows user name', (tester) async {
  final mockRepo = MockUserRepo();
  when(() => mockRepo.userStream).thenAnswer(
    (_) => Stream.value(User(name: 'Alice')),
  );

  await tester.pumpWidget(
    ViewModelScope(
      create: [() => AuthViewModel(mockRepo)],
      child: MaterialApp(home: ProfilePage()),
    ),
  );

  await tester.pumpAndSettle();

  expect(find.text('Alice'), findsOneWidget);
});
```

## Tips

1. **Use TestScope** — It ensures proper disposal in `tearDown`
2. **Mock at the boundary** — Mock repositories, not ViewModels
3. **Use `Future.delayed(Duration.zero)`** — Lets async operations complete
4. **Test state, not implementation** — Check `hasData`, not internal details
