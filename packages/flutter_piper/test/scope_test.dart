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

  group('Scoped', () {
    testWidgets('provides ViewModel to builder', (tester) async {
      late CounterViewModel capturedVm;
      late CounterViewModel builderVm;

      await tester.pumpWidget(
        Scoped<CounterViewModel>(
          create: () => CounterViewModel(),
          builder: (context, vm) {
            builderVm = vm;
            capturedVm = context.vm<CounterViewModel>();
            return const SizedBox();
          },
        ),
      );

      expect(builderVm, same(capturedVm));
      expect(capturedVm.count.value, 0);
      capturedVm.increment();
      expect(capturedVm.count.value, 1);
    });

    testWidgets('provides ViewModel to descendants via context.vm()',
        (tester) async {
      late CounterViewModel capturedVm;

      await tester.pumpWidget(
        Scoped<CounterViewModel>(
          create: () => CounterViewModel(),
          builder: (context, vm) {
            return Builder(
              builder: (innerContext) {
                capturedVm = innerContext.vm<CounterViewModel>();
                return const SizedBox();
              },
            );
          },
        ),
      );

      expect(capturedVm.count.value, 0);
    });

    testWidgets('context.scoped() alias works', (tester) async {
      late CounterViewModel capturedVm;

      await tester.pumpWidget(
        Scoped<CounterViewModel>(
          create: () => CounterViewModel(),
          builder: (context, vm) {
            capturedVm = context.scoped<CounterViewModel>();
            return const SizedBox();
          },
        ),
      );

      expect(capturedVm.count.value, 0);
    });

    testWidgets('disposes ViewModel when removed', (tester) async {
      late CounterViewModel capturedVm;
      final completer = Completer<int>();

      await tester.pumpWidget(
        Scoped<CounterViewModel>(
          create: () => CounterViewModel(),
          builder: (context, vm) {
            capturedVm = vm;
            return const SizedBox();
          },
        ),
      );

      // Launch a task to verify disposal
      final task = capturedVm.testLaunch(() => completer.future);

      // Remove the scope
      await tester.pumpWidget(const SizedBox());

      expect(task.isCancelled, true);
    });

    testWidgets('shadowing - inner Scoped wins', (tester) async {
      late CounterViewModel outerVm;
      late CounterViewModel innerVm;

      await tester.pumpWidget(
        Scoped<CounterViewModel>(
          create: () => CounterViewModel(),
          builder: (context, vm) {
            outerVm = vm;
            return Scoped<CounterViewModel>(
              create: () => CounterViewModel(),
              builder: (innerContext, innerViewModel) {
                innerVm = innerContext.vm<CounterViewModel>();
                return const SizedBox();
              },
            );
          },
        ),
      );

      // They should be different instances
      outerVm.count.value = 10;
      innerVm.count.value = 20;

      expect(outerVm.count.value, 10);
      expect(innerVm.count.value, 20);
    });

    testWidgets('can mix Scoped and ViewModelScope', (tester) async {
      late CounterViewModel counterVm;
      late NameViewModel nameVm;

      await tester.pumpWidget(
        ViewModelScope(
          create: [() => NameViewModel()],
          child: Scoped<CounterViewModel>(
            create: () => CounterViewModel(),
            builder: (context, vm) {
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

    testWidgets('Scoped shadows ViewModelScope of same type', (tester) async {
      late CounterViewModel outerVm;
      late CounterViewModel innerVm;

      await tester.pumpWidget(
        ViewModelScope(
          create: [() => CounterViewModel()],
          child: Builder(
            builder: (context) {
              outerVm = context.vm<CounterViewModel>();
              return Scoped<CounterViewModel>(
                create: () => CounterViewModel(),
                builder: (innerContext, vm) {
                  innerVm = innerContext.vm<CounterViewModel>();
                  return const SizedBox();
                },
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

    testWidgets('throws when ViewModel not found', (tester) async {
      await tester.pumpWidget(
        Scoped<CounterViewModel>(
          create: () => CounterViewModel(),
          builder: (context, vm) {
            expect(
              () => context.vm<NameViewModel>(),
              throwsA(isA<FlutterError>()),
            );
            return const SizedBox();
          },
        ),
      );
    });

    testWidgets('maybeVm returns null when not found', (tester) async {
      await tester.pumpWidget(
        Scoped<CounterViewModel>(
          create: () => CounterViewModel(),
          builder: (context, vm) {
            expect(context.maybeVm<NameViewModel>(), isNull);
            return const SizedBox();
          },
        ),
      );
    });
  });

  group('Named Scopes', () {
    testWidgets('provides ViewModel via named scope', (tester) async {
      late CounterViewModel capturedVm;

      await tester.pumpWidget(
        ViewModelScope(
          name: 'checkout',
          create: [() => CounterViewModel()],
          child: Builder(
            builder: (context) {
              capturedVm = context.vm<CounterViewModel>(scope: 'checkout');
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedVm.count.value, 0);
      capturedVm.increment();
      expect(capturedVm.count.value, 1);
    });

    testWidgets('named scope can be accessed without scope parameter',
        (tester) async {
      late CounterViewModel capturedVm;

      await tester.pumpWidget(
        ViewModelScope(
          name: 'checkout',
          create: [() => CounterViewModel()],
          child: Builder(
            builder: (context) {
              // Can access without scope parameter (nearest ancestor wins)
              capturedVm = context.vm<CounterViewModel>();
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedVm.count.value, 0);
    });

    testWidgets('throws when named scope not found', (tester) async {
      await tester.pumpWidget(
        ViewModelScope(
          name: 'checkout',
          create: [() => CounterViewModel()],
          child: Builder(
            builder: (context) {
              expect(
                () => context.vm<CounterViewModel>(scope: 'other'),
                throwsA(isA<FlutterError>()),
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('maybeVm returns null when named scope not found',
        (tester) async {
      await tester.pumpWidget(
        ViewModelScope(
          name: 'checkout',
          create: [() => CounterViewModel()],
          child: Builder(
            builder: (context) {
              expect(
                context.maybeVm<CounterViewModel>(scope: 'other'),
                isNull,
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('named scope skips unnamed scopes when searching',
        (tester) async {
      late CounterViewModel namedVm;
      late CounterViewModel unnamedVm;

      await tester.pumpWidget(
        ViewModelScope(
          name: 'checkout',
          create: [() => CounterViewModel()],
          child: Builder(
            builder: (context) {
              namedVm = context.vm<CounterViewModel>(scope: 'checkout');
              return ViewModelScope(
                create: [() => CounterViewModel()],
                child: Builder(
                  builder: (innerContext) {
                    // Without scope param, gets the nearest (unnamed)
                    unnamedVm = innerContext.vm<CounterViewModel>();
                    // With scope param, skips unnamed and gets named
                    final fromNamed =
                        innerContext.vm<CounterViewModel>(scope: 'checkout');
                    expect(fromNamed, same(namedVm));
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );

      // Verify they're different instances
      namedVm.count.value = 10;
      unnamedVm.count.value = 20;

      expect(namedVm.count.value, 10);
      expect(unnamedVm.count.value, 20);
    });

    testWidgets('named scope skips Scoped widgets when searching',
        (tester) async {
      late CounterViewModel namedVm;
      late CounterViewModel scopedVm;

      await tester.pumpWidget(
        ViewModelScope(
          name: 'checkout',
          create: [() => CounterViewModel()],
          child: Builder(
            builder: (context) {
              namedVm = context.vm<CounterViewModel>(scope: 'checkout');
              return Scoped<CounterViewModel>(
                create: () => CounterViewModel(),
                builder: (innerContext, vm) {
                  scopedVm = vm;
                  // With scope param, skips Scoped and gets named
                  final fromNamed =
                      innerContext.vm<CounterViewModel>(scope: 'checkout');
                  expect(fromNamed, same(namedVm));
                  return const SizedBox();
                },
              );
            },
          ),
        ),
      );

      // Verify they're different instances
      namedVm.count.value = 10;
      scopedVm.count.value = 20;

      expect(namedVm.count.value, 10);
      expect(scopedVm.count.value, 20);
    });

    testWidgets('multiple named scopes can coexist', (tester) async {
      late CounterViewModel checkoutVm;
      late NameViewModel cartVm;

      await tester.pumpWidget(
        ViewModelScope(
          name: 'checkout',
          create: [() => CounterViewModel()],
          child: ViewModelScope(
            name: 'cart',
            create: [() => NameViewModel()],
            child: Builder(
              builder: (context) {
                checkoutVm = context.vm<CounterViewModel>(scope: 'checkout');
                cartVm = context.vm<NameViewModel>(scope: 'cart');
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(checkoutVm, isA<CounterViewModel>());
      expect(cartVm, isA<NameViewModel>());
    });

    testWidgets('disposes ViewModels when named scope removed', (tester) async {
      late CounterViewModel capturedVm;
      final completer = Completer<int>();

      await tester.pumpWidget(
        ViewModelScope(
          name: 'checkout',
          create: [() => CounterViewModel()],
          child: Builder(
            builder: (context) {
              capturedVm = context.vm<CounterViewModel>(scope: 'checkout');
              return const SizedBox();
            },
          ),
        ),
      );

      final task = capturedVm.testLaunch(() => completer.future);

      await tester.pumpWidget(const SizedBox());

      expect(task.isCancelled, true);
    });

    testWidgets('same name shadows outer scope', (tester) async {
      late CounterViewModel outerVm;
      late CounterViewModel innerVm;

      await tester.pumpWidget(
        ViewModelScope(
          name: 'checkout',
          create: [() => CounterViewModel()],
          child: Builder(
            builder: (context) {
              outerVm = context.vm<CounterViewModel>(scope: 'checkout');
              return ViewModelScope(
                name: 'checkout',
                create: [() => CounterViewModel()],
                child: Builder(
                  builder: (innerContext) {
                    innerVm =
                        innerContext.vm<CounterViewModel>(scope: 'checkout');
                    return const SizedBox();
                  },
                ),
              );
            },
          ),
        ),
      );

      // They should be different instances (inner shadows outer)
      outerVm.count.value = 10;
      innerVm.count.value = 20;

      expect(outerVm.count.value, 10);
      expect(innerVm.count.value, 20);
    });
  });
}
