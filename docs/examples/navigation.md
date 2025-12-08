# Navigation & Side Effects

Trigger navigation and other side effects from state changes.

## ViewModel

```dart
class CheckoutViewModel extends ViewModel {
  final OrderRepository _orderRepo;

  CheckoutViewModel(this._orderRepo);

  late final orderState = asyncState<Order>();
  late final isOrderComplete = state(false);

  void placeOrder(Cart cart) {
    load(orderState, () async {
      final order = await _orderRepo.placeOrder(cart);
      isOrderComplete.value = true;
      return order;
    });
  }
}
```

## Widget with StateEffect

```dart
class CheckoutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.vm<CheckoutViewModel>();

    // Navigate when order completes
    return StateEffect<bool>(
      listenable: vm.isOrderComplete.listenable,
      when: (prev, curr) => !prev && curr,  // false -> true
      effect: (_, ctx) {
        Navigator.of(ctx).pushReplacement(
          MaterialPageRoute(builder: (_) => OrderConfirmationPage()),
        );
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Checkout')),
        body: vm.orderState.build(
          (state) => switch (state) {
            AsyncLoading() => Center(child: CircularProgressIndicator()),
            AsyncError(:final message) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Error: $message'),
                  ElevatedButton(
                    onPressed: () => vm.placeOrder(cart),
                    child: Text('Retry'),
                  ),
                ],
              ),
            ),
            _ => CheckoutForm(onSubmit: () => vm.placeOrder(cart)),
          },
        ),
      ),
    );
  }
}
```

## Alternative: StateListener for Snackbars

```dart
vm.orderState.listen(
  onChange: (prev, curr) {
    if (curr is AsyncError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(curr.message)),
      );
    }
  },
  child: // your UI
)
```

## What's happening

1. **`StateEffect`** — triggers side effect (navigation) when state changes
2. **`when`** — condition prevents effect on every change, only fires once
3. **Post-frame callback** — effect runs after build, safe for navigation
4. **`listen()`** — extension method for inline StateListener
