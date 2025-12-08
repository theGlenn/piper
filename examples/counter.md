# Counter

The simplest example.

## ViewModel

```dart
class CounterViewModel extends ViewModel {
  late final count = state(0);

  void increment() => count.update((c) => c + 1);
  void decrement() => count.update((c) => c - 1);
}
```

## Widget

```dart
class CounterPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.vm<CounterViewModel>();

    return Scaffold(
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
            onPressed: vm.increment,
            child: Icon(Icons.add),
          ),
          SizedBox(height: 8),
          FloatingActionButton(
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
void main() {
  runApp(
    ViewModelScope(
      create: [() => CounterViewModel()],
      child: MaterialApp(home: CounterPage()),
    ),
  );
}
```
