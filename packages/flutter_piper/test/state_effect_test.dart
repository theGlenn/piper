import 'package:flutter/foundation.dart' as flutter;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_piper/flutter_piper.dart';

void main() {
  group('StateEffect', () {
    testWidgets('fires effect on value change', (tester) async {
      final notifier = flutter.ValueNotifier(0);
      final effects = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          home: StateEffect<int>(
            listenable: notifier,
            effect: (value, _) => effects.add(value),
            child: const Text('test'),
          ),
        ),
      );

      notifier.value = 1;
      await tester.pump();

      expect(effects, [1]);
    });

    testWidgets('effect runs in post-frame callback (not immediately)',
        (tester) async {
      final notifier = flutter.ValueNotifier(false);
      var effectFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StateEffect<bool>(
            listenable: notifier,
            effect: (_, __) => effectFired = true,
            child: const Text('test'),
          ),
        ),
      );

      notifier.value = true;
      // Before pump, effect should NOT have fired
      expect(effectFired, false);

      await tester.pump();
      expect(effectFired, true);
    });

    testWidgets('when condition receives previous and current values',
        (tester) async {
      final notifier = flutter.ValueNotifier(0);
      final whenCalls = <(int, int)>[];

      await tester.pumpWidget(
        MaterialApp(
          home: StateEffect<int>(
            listenable: notifier,
            when: (previous, current) {
              whenCalls.add((previous, current));
              return false;
            },
            effect: (_, __) {},
            child: const Text('test'),
          ),
        ),
      );

      notifier.value = 1;
      expect(whenCalls, [(0, 1)]);

      notifier.value = 5;
      expect(whenCalls, [(0, 1), (1, 5)]);
    });

    testWidgets('when condition can prevent effect from firing', (tester) async {
      final notifier = flutter.ValueNotifier(0);
      var effectFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StateEffect<int>(
            listenable: notifier,
            when: (previous, current) => false, // never fire
            effect: (_, __) => effectFired = true,
            child: const Text('test'),
          ),
        ),
      );

      notifier.value = 100;
      await tester.pump();

      expect(effectFired, false);
    });

    testWidgets('does not rebuild child on value change', (tester) async {
      final notifier = flutter.ValueNotifier(0);
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StateEffect<int>(
            listenable: notifier,
            effect: (_, __) {},
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

      // Child should NOT rebuild
      expect(buildCount, 1);
    });

    testWidgets('removes listener on dispose', (tester) async {
      final notifier = flutter.ValueNotifier(0);
      var effectCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StateEffect<int>(
            listenable: notifier,
            effect: (_, __) => effectCount++,
            child: const Text('test'),
          ),
        ),
      );

      notifier.value = 1;
      await tester.pump();
      expect(effectCount, 1);

      // Dispose by removing widget
      await tester.pumpWidget(const MaterialApp(home: Text('empty')));

      // Should not fire after dispose
      notifier.value = 2;
      await tester.pump();
      expect(effectCount, 1);
    });

    testWidgets('does not fire if unmounted before post-frame', (tester) async {
      final notifier = flutter.ValueNotifier(false);
      var effectFired = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StateEffect<bool>(
            listenable: notifier,
            effect: (_, __) => effectFired = true,
            child: const Text('test'),
          ),
        ),
      );

      notifier.value = true;
      // Remove widget immediately (before pump processes post-frame)
      await tester.pumpWidget(const MaterialApp(home: Text('empty')));
      await tester.pump();

      expect(effectFired, false);
    });

    testWidgets('effect receives valid context', (tester) async {
      final notifier = flutter.ValueNotifier(false);
      BuildContext? capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: StateEffect<bool>(
            listenable: notifier,
            effect: (_, ctx) => capturedContext = ctx,
            child: const Text('test'),
          ),
        ),
      );

      notifier.value = true;
      await tester.pump();

      expect(capturedContext, isNotNull);
    });

    testWidgets('tracks previous value for when condition', (tester) async {
      final holder = StateHolder(0);
      (int, int)? lastWhenCall;

      await tester.pumpWidget(
        MaterialApp(
          home: StateEffect<int>(
            listenable: holder.flutterListenable,
            when: (prev, curr) {
              lastWhenCall = (prev, curr);
              return true;
            },
            effect: (_, __) {},
            child: const Text('test'),
          ),
        ),
      );

      holder.value = 10;
      expect(lastWhenCall, (0, 10));

      holder.value = 20;
      expect(lastWhenCall, (10, 20));

      holder.value = 30;
      expect(lastWhenCall, (20, 30));
    });
  });
}
