---
layout: home

hero:
  image:
    src: /logo.png
    alt: Piper
  name: Piper
  text: State management simplified
  tagline: Lifecycle-aware ViewModels for Flutter.
  actions:
    - theme: brand
      text: Get Started
      link: /guide/getting-started
    - theme: alt
      text: View on GitHub
      link: https://github.com/theGlenn/piper
    - theme: alt
      text: Examples
      link: /examples/counter

features:
  - title: Automatic Lifecycle
    details: No more "if (mounted)" checks. Subscriptions cancel, tasks stop, state disposes — all tied to widget lifecycle.
  - title: Plain Dart
    details: ViewModels are just Dart classes. Test without Flutter, mock without framework internals.
  - title: No Magic
    details: Constructor injection, explicit dependencies. Trace your entire dependency graph by reading the code.
---

<div class="code-showcase">

# See it in action

::: code-group

```dart [ViewModel]
class CounterViewModel extends ViewModel {
  late final count = state(0);

  void increment() => count.update((n) => n + 1);
}
```

```dart [Widget]
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.vm<CounterViewModel>();

    return vm.count.build(
      (count) => Text('$count'),
    );
  }
}
```

:::

</div>
