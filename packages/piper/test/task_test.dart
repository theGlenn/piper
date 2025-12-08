import 'package:test/test.dart';
import 'package:piper/piper.dart';

void main() {
  group('Task', () {
    test('completes with value', () async {
      final scope = TaskScope();
      final task = scope.launch(() async => 42);

      expect(task.isActive, true);
      expect(await task.result, 42);
      expect(task.isCompleted, true);

      scope.dispose();
    });

    test('returns null when cancelled', () async {
      final scope = TaskScope();
      final task = scope.launch(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return 42;
      });

      task.cancel();

      expect(task.isCancelled, true);
      expect(await task.result, null);

      scope.dispose();
    });

    test('suppresses error when cancelled', () async {
      final scope = TaskScope();
      final task = scope.launch(() async {
        await Future.delayed(const Duration(milliseconds: 10));
        throw Exception('test error');
      });

      task.cancel();

      // Should not throw
      expect(await task.result, null);

      scope.dispose();
    });

    test('rethrows error when not cancelled', () async {
      final scope = TaskScope();
      final task = scope.launch(() async {
        throw Exception('test error');
      });

      await expectLater(task.result, throwsException);

      scope.dispose();
    });
  });

  group('TaskScope', () {
    test('launches tasks', () async {
      final scope = TaskScope();
      final task1 = scope.launch(() async => 1);
      final task2 = scope.launch(() async => 2);

      expect(await task1.result, 1);
      expect(await task2.result, 2);

      scope.dispose();
    });

    test('cancelAll cancels all tasks', () async {
      final scope = TaskScope();
      final task1 = scope.launch(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return 1;
      });
      final task2 = scope.launch(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return 2;
      });

      scope.cancelAll();

      expect(task1.isCancelled, true);
      expect(task2.isCancelled, true);

      scope.dispose();
    });

    test('throws when launching on disposed scope', () {
      final scope = TaskScope();
      scope.dispose();

      expect(
        () => scope.launch(() async => 42),
        throwsStateError,
      );
    });

    test('launchWith calls onSuccess', () async {
      final scope = TaskScope();
      int? result;

      scope.launchWith(
        () async => 42,
        onSuccess: (value) => result = value,
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(result, 42);

      scope.dispose();
    });

    test('launchWith calls onError', () async {
      final scope = TaskScope();
      Object? error;

      scope.launchWith(
        () async => throw Exception('test'),
        onSuccess: (_) {},
        onError: (e) => error = e,
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(error, isA<Exception>());

      scope.dispose();
    });

    test('launchWith does not call callbacks when cancelled', () async {
      final scope = TaskScope();
      bool successCalled = false;
      bool errorCalled = false;

      scope.launchWith(
        () async {
          await Future.delayed(const Duration(milliseconds: 100));
          return 42;
        },
        onSuccess: (_) => successCalled = true,
        onError: (_) => errorCalled = true,
      );

      scope.dispose();
      await Future.delayed(const Duration(milliseconds: 150));

      expect(successCalled, false);
      expect(errorCalled, false);
    });
  });
}
