import 'dart:async';

import 'package:test/test.dart';
import 'package:piper_state/piper_state.dart';

void main() {
  group('Task', () {
    test('cancellation stops work after a cancellation-aware wait', () async {
      final scope = TaskScope();
      final delayed = Completer<void>();
      var sideEffectRan = false;
      final task = scope.launch((cancellation) async {
        await cancellation.wait(delayed.future);
        sideEffectRan = true;
      });

      task.cancel();

      expect(await task.result, isNull);
      expect(task.isCancelled, isTrue);
      expect(sideEffectRan, isFalse);

      delayed.complete();
      await Future<void>.delayed(Duration.zero);
      expect(sideEffectRan, isFalse);

      scope.dispose();
    });

    test('cancellation invokes an underlying operation abort hook once',
        () async {
      final scope = TaskScope();
      var abortCount = 0;
      final task = scope.launch((cancellation) async {
        cancellation.onCancel(() => abortCount++);
        await cancellation.wait(Completer<void>().future);
      });

      task.cancel();
      task.cancel();

      expect(await task.result, isNull);
      expect(abortCount, 1);

      scope.dispose();
    });

    test('completes with value', () async {
      final scope = TaskScope();
      final task = scope.launch((_) async => 42);

      expect(task.isActive, true);
      expect(await task.result, 42);
      expect(task.isCompleted, true);

      scope.dispose();
    });

    test('returns null when cancelled', () async {
      final scope = TaskScope();
      final task = scope.launch((_) async {
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
      final task = scope.launch((_) async {
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
      final task = scope.launch((_) async {
        throw Exception('test error');
      });

      await expectLater(task.result, throwsException);

      scope.dispose();
    });
  });

  group('TaskScope', () {
    test('launches tasks', () async {
      final scope = TaskScope();
      final task1 = scope.launch((_) async => 1);
      final task2 = scope.launch((_) async => 2);

      expect(await task1.result, 1);
      expect(await task2.result, 2);

      scope.dispose();
    });

    test('cancelAll cancels all tasks', () async {
      final scope = TaskScope();
      final task1 = scope.launch((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return 1;
      });
      final task2 = scope.launch((_) async {
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
        () => scope.launch((_) async => 42),
        throwsStateError,
      );
    });

    test('launchWith calls onSuccess', () async {
      final scope = TaskScope();
      int? result;

      scope.launchWith(
        (_) async => 42,
        onSuccess: (value) => result = value,
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(result, 42);

      scope.dispose();
    });

    test('launchWith calls onSuccess for a void/null future', () async {
      final scope = TaskScope();
      var called = false;

      // Regression: a Future<void> must still fire onSuccess. Previously the
      // null result was treated as "cancelled" and onSuccess was dropped.
      scope.launchWith<void>(
        (_) async {},
        onSuccess: (_) => called = true,
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(called, true);

      scope.dispose();
    });

    test('launchWith calls onError', () async {
      final scope = TaskScope();
      Object? error;

      scope.launchWith(
        (_) async => throw Exception('test'),
        onSuccess: (_) {},
        onError: (e) => error = e,
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(error, isA<Exception>());

      scope.dispose();
    });

    test('launchWith does not call callbacks when cancelled', () async {
      final scope = TaskScope();
      final pending = Completer<int>();
      bool successCalled = false;
      bool errorCalled = false;

      final task = scope.launchWith(
        (cancellation) => cancellation.wait(pending.future),
        onSuccess: (_) => successCalled = true,
        onError: (_) => errorCalled = true,
      );

      task.cancel();
      expect(await task.result, isNull);

      expect(successCalled, false);
      expect(errorCalled, false);

      pending.complete(42);
      await Future<void>.delayed(Duration.zero);
      expect(successCalled, false);
      expect(errorCalled, false);

      scope.dispose();
    });
  });
}
