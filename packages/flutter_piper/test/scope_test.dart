import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_piper/flutter_piper.dart';

class CounterViewModel extends ViewModel {
  late final count = state(0);
  void increment() => count.update((c) => c + 1);

  // Expose launch for testing
  Task<T> testLaunch<T>(Future<T> Function() work) => launch(work);
}

class NameViewModel extends ViewModel {
  late final name = state('');
}

void main() {
  group('ViewModelScope', () {
    testWidgets('provides ViewModel to descendants', (tester) async {
      late CounterViewModel capturedVm;

      await tester.pumpWidget(
        ViewModelScope(
          create: [() => CounterViewModel()],
          child: Builder(
            builder: (context) {
              capturedVm = context.vm<CounterViewModel>();
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedVm.count.value, 0);
      capturedVm.increment();
      expect(capturedVm.count.value, 1);
    });

    testWidgets('provides multiple ViewModels', (tester) async {
      late CounterViewModel counterVm;
      late NameViewModel nameVm;

      await tester.pumpWidget(
        ViewModelScope(
          create: [
            () => CounterViewModel(),
            () => NameViewModel(),
          ],
          child: Builder(
            builder: (context) {
              counterVm = context.vm<CounterViewModel>();
              nameVm = context.vm<NameViewModel>();
              return const SizedBox();
            },
          ),
        ),
      );

      expect(counterVm, isA<CounterViewModel>());
      expect(nameVm, isA<NameViewModel>());
    });

    testWidgets('throws when ViewModel not found', (tester) async {
      await tester.pumpWidget(
        ViewModelScope(
          create: [() => CounterViewModel()],
          child: Builder(
            builder: (context) {
              expect(
                () => context.vm<NameViewModel>(),
                throwsA(isA<FlutterError>()),
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('maybeVm returns null when not found', (tester) async {
      await tester.pumpWidget(
        ViewModelScope(
          create: [() => CounterViewModel()],
          child: Builder(
            builder: (context) {
              expect(context.maybeVm<NameViewModel>(), isNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('disposes ViewModels when removed', (tester) async {
      late CounterViewModel capturedVm;
      final completer = Completer<int>();

      await tester.pumpWidget(
        ViewModelScope(
          create: [() => CounterViewModel()],
          child: Builder(
            builder: (context) {
              capturedVm = context.vm<CounterViewModel>();
              return const SizedBox();
            },
          ),
        ),
      );

      // Launch a task to verify disposal (uses Completer instead of Future.delayed)
      final task = capturedVm.testLaunch(() => completer.future);

      // Remove the scope
      await tester.pumpWidget(const SizedBox());

      expect(task.isCancelled, true);
    });

    testWidgets('shadowing - inner scope wins', (tester) async {
      late CounterViewModel outerVm;
      late CounterViewModel innerVm;

      await tester.pumpWidget(
        ViewModelScope(
          create: [() => CounterViewModel()],
          child: Builder(
            builder: (context) {
              outerVm = context.vm<CounterViewModel>();
              return ViewModelScope(
                create: [() => CounterViewModel()],
                child: Builder(
                  builder: (innerContext) {
                    innerVm = innerContext.vm<CounterViewModel>();
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );

      // They should be different instances
      outerVm.count.value = 10;
      innerVm.count.value = 20;

      expect(outerVm.count.value, 10);
      expect(innerVm.count.value, 20);
    });
  });
}
