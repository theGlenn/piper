// ignore_for_file: avoid_print
import 'package:piper_state/piper_state.dart';

/// A simple counter ViewModel demonstrating basic state management.
class CounterViewModel extends ViewModel {
  /// The current count state.
  late final count = state(0);

  /// Increments the counter by 1.
  void increment() => count.update((c) => c + 1);

  /// Decrements the counter by 1.
  void decrement() => count.update((c) => c - 1);
}

/// A ViewModel demonstrating async state management.
class UserViewModel extends ViewModel {
  /// The user profile async state.
  late final profile = asyncState<String>();

  /// Loads the user profile.
  void loadProfile() {
    load(profile, () async {
      // Simulate network delay
      await Future<void>.delayed(const Duration(milliseconds: 100));
      return 'John Doe';
    });
  }
}

void main() {
  // Basic state example
  final counterVm = CounterViewModel();

  print('=== Counter Example ===');
  print('Initial count: ${counterVm.count.value}');

  counterVm.increment();
  print('After increment: ${counterVm.count.value}');

  counterVm.increment();
  counterVm.increment();
  print('After two more increments: ${counterVm.count.value}');

  counterVm.decrement();
  print('After decrement: ${counterVm.count.value}');

  // Listen to changes
  counterVm.count.addListener(() {
    print('Count changed to: ${counterVm.count.value}');
  });

  counterVm.increment();

  // Clean up
  counterVm.dispose();

  // Async state example
  print('\n=== Async State Example ===');
  final userVm = UserViewModel();

  // Check initial state
  userVm.profile.value.when(
    empty: () => print('Profile: empty'),
    loading: () => print('Profile: loading...'),
    error: (msg) => print('Profile error: $msg'),
    data: (name) => print('Profile: $name'),
  );

  // Load profile
  userVm.loadProfile();

  // Check loading state
  userVm.profile.value.when(
    empty: () => print('Profile: empty'),
    loading: () => print('Profile: loading...'),
    error: (msg) => print('Profile error: $msg'),
    data: (name) => print('Profile: $name'),
  );

  // Wait for async operation to complete
  Future<void>.delayed(const Duration(milliseconds: 150), () {
    userVm.profile.value.when(
      empty: () => print('Profile: empty'),
      loading: () => print('Profile: loading...'),
      error: (msg) => print('Profile error: $msg'),
      data: (name) => print('Profile loaded: $name'),
    );

    // Clean up
    userVm.dispose();
    print('\nAll ViewModels disposed.');
  });
}
