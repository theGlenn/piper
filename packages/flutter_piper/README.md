<p align="center">
  <img src="https://raw.githubusercontent.com/theGlenn/piper/main/docs/public/logo.png" alt="Piper State" width="100" />
</p>

# Flutter Piper

[![pub package](https://img.shields.io/pub/v/flutter_piper.svg)](https://pub.dev/packages/flutter_piper)
[![likes](https://img.shields.io/pub/likes/flutter_piper)](https://pub.dev/packages/flutter_piper/score)
[![popularity](https://img.shields.io/pub/popularity/flutter_piper)](https://pub.dev/packages/flutter_piper/score)
[![pub points](https://img.shields.io/pub/points/flutter_piper)](https://pub.dev/packages/flutter_piper/score)
[![CI](https://github.com/theGlenn/piper/actions/workflows/ci.yml/badge.svg)](https://github.com/theGlenn/piper/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/theGlenn/piper/branch/main/graph/badge.svg)](https://codecov.io/gh/theGlenn/piper)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter)](https://flutter.dev)
[![style: flutter lints](https://img.shields.io/badge/style-flutter__lints-4BC0F5.svg)](https://pub.dev/packages/flutter_lints)

**Lifecycle-aware Flutter widgets for [Piper State](https://pub.dev/packages/piper_state).**

Use plain Dart ViewModels in Flutter with auto-tracked rebuilds and cleanup
owned by the widget scope.

## Installation

`flutter_piper` re-exports the complete `piper_state` API, so Flutter apps only
need one direct dependency:

```yaml
dependencies:
  flutter_piper: ^0.1.0
```

## Quick Example
```dart
// Provide ViewModels
ViewModelScope(
  create: [() => CounterViewModel()],
  child: MyApp(),
)

// Access and build UI
final vm = context.vm<CounterViewModel>();
vm.count.build((count) => Text('$count'));
```

## Widgets

### ViewModelScope

Provides ViewModels to the widget tree:
```dart
ViewModelScope(
  create: [
    () => AuthViewModel(authRepo),
    () => TodosViewModel(todoRepo),
  ],
  child: MyApp(),
)
```

### Scoped\<T\>

Single typed ViewModel with builder:
```dart
Scoped<DetailViewModel>(
  create: () => DetailViewModel(id),
  builder: (context, vm) => DetailPage(),
)
```

### Named Scopes

Share ViewModels across routes:
```dart
ViewModelScope.named(
  name: 'checkout',
  create: [() => CheckoutViewModel()],
  child: CheckoutFlow(),
)

// Access by name
context.vm<CheckoutViewModel>(scope: 'checkout');
```

### Building UI
```dart
// Rebuild on change
vm.count.build((count) => Text('$count'))

// Side effects
vm.isDeleted.listen(
  onChange: (prev, curr) {
    if (curr) Navigator.of(context).pop();
  },
  child: MyWidget(),
)
```

## Documentation

📖 **[Full docs](https://glennso.dev/piper/)** · [GitHub](https://github.com/theGlenn/piper) · [piper_state](https://pub.dev/packages/piper_state)

Want to watch lifecycle cancellation happen? Try the
[live Piper Search Race demo](https://glennso.dev/piper/demo/)
([source](https://github.com/theGlenn/piper/tree/main/packages/flutter_piper/example)):
the deliberately slow `f` task is cancelled before it can overwrite the
faster `flutter` result — and you can toggle the protection off to see the bug.

## License

MIT
