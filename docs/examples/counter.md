# Counter

The classic example. Simple state management with increment and decrement.

## ViewModel

```dart
import 'package:piper/piper.dart';

class CounterViewModel extends ViewModel {
  late final count = state(0);

  void increment() => count.update((c) => c + 1);
  void decrement() => count.update((c) => c - 1);
  void reset() => count.value = 0;
}
```

## Widget

```dart
import 'package:flutter/material.dart';
import 'package:flutter_piper/flutter_piper.dart';

class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.vm<CounterViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Counter'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: vm.reset,
          ),
        ],
      ),
      body: Center(
        child: vm.count.build(
          (count) => Text(
            '$count',
            style: Theme.of(context).textTheme.displayLarge,
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'increment',
            onPressed: vm.increment,
            child: Icon(Icons.add),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'decrement',
            onPressed: vm.decrement,
            child: Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
```

## Setup

```dart
import 'package:flutter/material.dart';
import 'package:flutter_piper/flutter_piper.dart';

void main() {
  runApp(
    ViewModelScope(
      create: [() => CounterViewModel()],
      child: MaterialApp(home: CounterPage()),
    ),
  );
}
```

## What's Happening

1. **`state(0)`** — Creates a `StateHolder<int>` with initial value `0`
2. **`update()`** — Transforms the current value
3. **`.build()`** — Rebuilds the `Text` widget when count changes
4. **Lifecycle** — StateHolder is disposed when ViewModel disposes
