import 'package:flutter/material.dart';
import 'package:flutter_piper/flutter_piper.dart';
import 'package:flutter_test/flutter_test.dart';

class _CounterViewModel extends ViewModel {
  late final count = state(0);
  late final isEven = computed(() => count.value.isEven);

  void increment() => count.update((c) => c + 1);
}

void main() {
  testWidgets('Watch rebuilds when a read state changes', (tester) async {
    final vm = _CounterViewModel();
    addTearDown(vm.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Watch((_) => Text('${vm.count.value}', textDirection: TextDirection.ltr)),
      ),
    );

    expect(find.text('0'), findsOneWidget);

    vm.increment();
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('Watch reacts to a computed derived from state', (tester) async {
    final vm = _CounterViewModel();
    addTearDown(vm.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Watch(
          (_) => Text(vm.isEven.value ? 'even' : 'odd',
              textDirection: TextDirection.ltr),
        ),
      ),
    );

    expect(find.text('even'), findsOneWidget);

    vm.increment(); // 1 -> odd
    await tester.pump();
    expect(find.text('odd'), findsOneWidget);

    vm.increment(); // 2 -> even
    await tester.pump();
    expect(find.text('even'), findsOneWidget);
  });

  testWidgets('Watch only rebuilds for state it actually reads', (tester) async {
    final vm = _CounterViewModel();
    addTearDown(vm.dispose);
    final other = StateHolder(0);
    var builds = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Watch((_) {
          builds++;
          return Text('${vm.count.value}', textDirection: TextDirection.ltr);
        }),
      ),
    );
    expect(builds, 1);

    // `other` is never read inside the Watch — changing it must not rebuild.
    other.value = 99;
    await tester.pump();
    expect(builds, 1);

    vm.increment();
    await tester.pump();
    expect(builds, 2);
  });
}
