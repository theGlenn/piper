import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_piper/flutter_piper.dart';

void main() {
  group('StateListener', () {
    testWidgets('calls onChange when value changes', (tester) async {
      final notifier = ValueNotifier(0);
      final changes = <(int, int)>[];

      await tester.pumpWidget(
        MaterialApp(
          home: StateListener<int>(
            listenable: notifier,
            onChange: (previous, current) {
              changes.add((previous, current));
            },
            child: const Text('test'),
          ),
        ),
      );

      notifier.value = 1;
      await tester.pump();

      expect(changes, [(0, 1)]);

      notifier.value = 5;
      await tester.pump();

      expect(changes, [(0, 1), (1, 5)]);
    });

    testWidgets('does not rebuild child on value change', (tester) async {
      final notifier = ValueNotifier(0);
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StateListener<int>(
            listenable: notifier,
            onChange: (_, __) {},
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

      notifier.value = 1;
      await tester.pump();

      // Child should not rebuild
      expect(buildCount, 1);
    });

    testWidgets('tracks previous value correctly', (tester) async {
      final notifier = ValueNotifier(10);
      final previousValues = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: StateListener<int>(
            listenable: notifier,
            onChange: (previous, _) {
              previousValues.add(previous);
            },
            child: const Text('test'),
          ),
        ),
      );

      notifier.value = 20;
      await tester.pump();

      notifier.value = 30;
      await tester.pump();

      notifier.value = 40;
      await tester.pump();

      expect(previousValues, [10, 20, 30]);
    });

    testWidgets('handles listenable change', (tester) async {
      final notifier1 = ValueNotifier(0);
      final notifier2 = ValueNotifier(100);
      final changes = <(int, int)>[];

      await tester.pumpWidget(
        MaterialApp(
          home: StateListener<int>(
            listenable: notifier1,
            onChange: (previous, current) {
              changes.add((previous, current));
            },
            child: const Text('test'),
          ),
        ),
      );

      notifier1.value = 1;
      await tester.pump();
      expect(changes, [(0, 1)]);

      // Switch to notifier2
      await tester.pumpWidget(
        MaterialApp(
          home: StateListener<int>(
            listenable: notifier2,
            onChange: (previous, current) {
              changes.add((previous, current));
            },
            child: const Text('test'),
          ),
        ),
      );

      // Old notifier should not trigger onChange
      notifier1.value = 2;
      await tester.pump();
      expect(changes, [(0, 1)]); // No new change

      // New notifier should trigger onChange
      notifier2.value = 200;
      await tester.pump();
      expect(changes, [(0, 1), (100, 200)]);
    });

    testWidgets('removes listener on dispose', (tester) async {
      final notifier = ValueNotifier(0);
      var callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StateListener<int>(
            listenable: notifier,
            onChange: (_, __) => callCount++,
            child: const Text('test'),
          ),
        ),
      );

      notifier.value = 1;
      await tester.pump();
      expect(callCount, 1);

      // Remove the widget
      await tester.pumpWidget(const MaterialApp(home: Text('empty')));

      // Changes should not trigger callback
      notifier.value = 2;
      await tester.pump();
      expect(callCount, 1); // Still 1
    });

    testWidgets('works with StateHolder.listen()', (tester) async {
      final holder = StateHolder(false);
      var navigated = false;

      await tester.pumpWidget(
        MaterialApp(
          home: holder.listen(
            onChange: (previous, current) {
              if (!previous && current) {
                navigated = true;
              }
            },
            child: const Text('test'),
          ),
        ),
      );

      expect(navigated, false);

      holder.value = true;
      await tester.pump();

      expect(navigated, true);
    });
  });
}
