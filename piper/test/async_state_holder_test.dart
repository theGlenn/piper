import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:piper/piper.dart';

void main() {
  group('AsyncStateHolder', () {
    group('construction', () {
      test('starts in empty state by default', () {
        final holder = AsyncStateHolder<int>();
        expect(holder.isEmpty, true);
        expect(holder.isLoading, false);
        expect(holder.hasData, false);
        expect(holder.hasError, false);
      });

      test('.loading() starts in loading state', () {
        final holder = AsyncStateHolder<int>.loading();
        expect(holder.isLoading, true);
        expect(holder.isEmpty, false);
      });

      test('.data() starts with data', () {
        final holder = AsyncStateHolder<int>.data(42);
        expect(holder.hasData, true);
        expect(holder.dataOrNull, 42);
      });
    });

    group('state transitions', () {
      test('setLoading transitions to loading', () {
        final holder = AsyncStateHolder<int>();
        holder.setLoading();
        expect(holder.isLoading, true);
        expect(holder.isEmpty, false);
      });

      test('setData transitions to data state', () {
        final holder = AsyncStateHolder<int>();
        holder.setData(42);
        expect(holder.hasData, true);
        expect(holder.dataOrNull, 42);
      });

      test('setError transitions to error state', () {
        final holder = AsyncStateHolder<String>();
        holder.setError('Something went wrong', error: Exception('test'));
        expect(holder.hasError, true);
        expect(holder.errorOrNull, 'Something went wrong');
      });

      test('setEmpty transitions to empty state', () {
        final holder = AsyncStateHolder<int>.data(42);
        holder.setEmpty();
        expect(holder.isEmpty, true);
        expect(holder.hasData, false);
      });
    });

    group('convenience getters', () {
      test('dataOrNull returns null when not in data state', () {
        final holder = AsyncStateHolder<int>();
        expect(holder.dataOrNull, null);

        holder.setLoading();
        expect(holder.dataOrNull, null);

        holder.setError('error');
        expect(holder.dataOrNull, null);
      });

      test('dataOrNull returns data when in data state', () {
        final holder = AsyncStateHolder<int>.data(100);
        expect(holder.dataOrNull, 100);
      });

      test('errorOrNull returns null when not in error state', () {
        final holder = AsyncStateHolder<int>();
        expect(holder.errorOrNull, null);

        holder.setLoading();
        expect(holder.errorOrNull, null);

        holder.setData(42);
        expect(holder.errorOrNull, null);
      });

      test('errorOrNull returns message when in error state', () {
        final holder = AsyncStateHolder<int>();
        holder.setError('Failed to load');
        expect(holder.errorOrNull, 'Failed to load');
      });
    });

    group('notifications', () {
      test('notifies listeners on state change', () {
        final holder = AsyncStateHolder<int>();
        var notificationCount = 0;

        holder.listenable.addListener(() => notificationCount++);

        holder.setLoading();
        expect(notificationCount, 1);

        holder.setData(42);
        expect(notificationCount, 2);

        holder.setError('error');
        expect(notificationCount, 3);

        holder.setEmpty();
        expect(notificationCount, 4);
      });

      test('does not notify when setting same loading state', () {
        final holder = AsyncStateHolder<int>.loading();
        var notificationCount = 0;

        holder.listenable.addListener(() => notificationCount++);

        holder.setLoading();
        // AsyncLoading is a const, so same instance comparison should work
        expect(notificationCount, 0);
      });
    });

    group('dispose', () {
      test('dispose prevents further updates', () {
        final holder = AsyncStateHolder<int>();
        holder.dispose();

        // After dispose, setting value should throw
        expect(() => holder.setData(42), throwsFlutterError);
      });
    });
  });

  group('AsyncState', () {
    group('when', () {
      test('calls correct branch for empty', () {
        const state = AsyncState<int>.empty();
        final result = state.when(
          empty: () => 'empty',
          loading: () => 'loading',
          error: (msg) => 'error: $msg',
          data: (d) => 'data: $d',
        );
        expect(result, 'empty');
      });

      test('calls correct branch for loading', () {
        const state = AsyncState<int>.loading();
        final result = state.when(
          empty: () => 'empty',
          loading: () => 'loading',
          error: (msg) => 'error: $msg',
          data: (d) => 'data: $d',
        );
        expect(result, 'loading');
      });

      test('calls correct branch for error', () {
        final state = AsyncState<int>.error('failed');
        final result = state.when(
          empty: () => 'empty',
          loading: () => 'loading',
          error: (msg) => 'error: $msg',
          data: (d) => 'data: $d',
        );
        expect(result, 'error: failed');
      });

      test('calls correct branch for data', () {
        const state = AsyncState<int>.data(42);
        final result = state.when(
          empty: () => 'empty',
          loading: () => 'loading',
          error: (msg) => 'error: $msg',
          data: (d) => 'data: $d',
        );
        expect(result, 'data: 42');
      });
    });

    group('maybeWhen', () {
      test('uses orElse when no matching handler', () {
        const state = AsyncState<int>.loading();
        final result = state.maybeWhen(
          data: (d) => 'data: $d',
          orElse: () => 'fallback',
        );
        expect(result, 'fallback');
      });

      test('uses handler when provided', () {
        const state = AsyncState<int>.data(42);
        final result = state.maybeWhen(
          data: (d) => 'data: $d',
          orElse: () => 'fallback',
        );
        expect(result, 'data: 42');
      });
    });

    group('map', () {
      test('transforms data state', () {
        const state = AsyncState<int>.data(10);
        final mapped = state.map((d) => d * 2);
        expect(mapped, isA<AsyncData<int>>());
        expect((mapped as AsyncData<int>).data, 20);
      });

      test('preserves loading state', () {
        const state = AsyncState<int>.loading();
        final mapped = state.map((d) => d * 2);
        expect(mapped, isA<AsyncLoading<int>>());
      });

      test('preserves error state', () {
        final state = AsyncState<int>.error('failed');
        final mapped = state.map((d) => d * 2);
        expect(mapped, isA<AsyncError<int>>());
        expect((mapped as AsyncError<int>).message, 'failed');
      });

      test('preserves empty state', () {
        const state = AsyncState<int>.empty();
        final mapped = state.map((d) => d * 2);
        expect(mapped, isA<AsyncEmpty<int>>());
      });
    });

    group('error with underlying error object', () {
      test('stores underlying error', () {
        final exception = Exception('underlying');
        final state = AsyncState<int>.error('message', error: exception);
        expect(state, isA<AsyncError<int>>());
        expect((state as AsyncError<int>).error, exception);
      });
    });
  });

  group('AsyncStateHolder.listenAsync', () {
    testWidgets('calls onData when transitioning to data state', (tester) async {
      final holder = AsyncStateHolder<int>();
      int? receivedData;

      await tester.pumpWidget(
        MaterialApp(
          home: holder.listenAsync(
            onData: (data) => receivedData = data,
            child: const Text('test'),
          ),
        ),
      );

      holder.setData(42);
      await tester.pump();

      expect(receivedData, 42);
    });

    testWidgets('calls onError when transitioning to error state', (tester) async {
      final holder = AsyncStateHolder<int>();
      String? receivedError;

      await tester.pumpWidget(
        MaterialApp(
          home: holder.listenAsync(
            onError: (msg) => receivedError = msg,
            child: const Text('test'),
          ),
        ),
      );

      holder.setError('Something went wrong');
      await tester.pump();

      expect(receivedError, 'Something went wrong');
    });

    testWidgets('calls onLoading when transitioning to loading state', (tester) async {
      final holder = AsyncStateHolder<int>.data(0);
      var loadingCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: holder.listenAsync(
            onLoading: () => loadingCalled = true,
            child: const Text('test'),
          ),
        ),
      );

      holder.setLoading();
      await tester.pump();

      expect(loadingCalled, true);
    });

    testWidgets('does not rebuild child on state change', (tester) async {
      final holder = AsyncStateHolder<int>();
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: holder.listenAsync(
            onData: (_) {},
            child: Builder(
              builder: (context) {
                buildCount++;
                return const Text('test');
              },
            ),
          ),
        ),
      );

      expect(buildCount, 1);

      holder.setData(42);
      await tester.pump();

      // Child should not rebuild
      expect(buildCount, 1);
    });

    testWidgets('only calls relevant callback for state type', (tester) async {
      final holder = AsyncStateHolder<int>();
      var dataCalled = false;
      var errorCalled = false;
      var loadingCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: holder.listenAsync(
            onData: (_) => dataCalled = true,
            onError: (_) => errorCalled = true,
            onLoading: () => loadingCalled = true,
            child: const Text('test'),
          ),
        ),
      );

      // Transition to data
      holder.setData(42);
      await tester.pump();

      expect(dataCalled, true);
      expect(errorCalled, false);
      expect(loadingCalled, false);
    });
  });
}
