---
layout: home
title: Piper State
titleTemplate: false
description: Flutter state management that cleans up after itself. Plain Dart ViewModels with automatic rebuilds, stream cleanup, and cooperative task cancellation.

hero:
  image:
    src: /logo.png
    alt: Piper State
  name: Piper State
  text: State management that cleans up after itself.
  tagline: Plain Dart ViewModels with automatic rebuilds, stream cleanup, and cooperative task cancellation.
  actions:
    - theme: brand
      text: Get Started
      link: /guide/getting-started
    - theme: alt
      text: Live Demo
      link: https://glennso.dev/piper/demo/
    - theme: alt
      text: View on GitHub
      link: https://github.com/theGlenn/piper
    - theme: alt
      text: Examples
      link: /examples/counter

features:
  - title: Automatic Rebuilds
    details: Watch subscribes to the state it reads. computed() derives values without dependency lists.
  - title: Cleanup Follows Ownership
    details: Streams, derived state, and cooperative tasks stop when their ViewModel disposes.
  - title: Plain Dart ViewModels
    details: Test business logic without Flutter, generated files, or framework test containers.
  - title: Dependencies Stay Visible
    details: Constructor parameters make the dependency graph readable from the code that creates it.
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
