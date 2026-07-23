# Form Validation

Reactive forms with computed validation state.

## ViewModel

```dart
class SignUpViewModel extends ViewModel {
  late final email = state('');
  late final password = state('');
  late final confirmPassword = state('');
  late final signUpState = asyncState<void>();

  // Derived validation — each recomputes automatically when the fields it
  // reads change, so a `Watch` reading it rebuilds reactively.
  late final emailError = computed(() {
    if (email.value.isEmpty) return null;
    if (!email.value.contains('@')) return 'Invalid email';
    return null;
  });

  late final passwordError = computed(() {
    if (password.value.isEmpty) return null;
    if (password.value.length < 8) return 'At least 8 characters';
    return null;
  });

  // Depends on both fields — updates when either password changes.
  late final confirmError = computed(() {
    if (confirmPassword.value.isEmpty) return null;
    if (confirmPassword.value != password.value) return 'Passwords don\'t match';
    return null;
  });

  // Computed-of-computed.
  late final isValid = computed(() =>
      email.value.isNotEmpty &&
      password.value.isNotEmpty &&
      emailError.value == null &&
      passwordError.value == null &&
      confirmError.value == null);

  void signUp() {
    if (!isValid.value) return;
    load(signUpState, () => _authRepo.signUp(email.value, password.value));
  }
}
```

## Widget

```dart
class SignUpPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.vm<SignUpViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Email field — rebuilds when its derived error changes
            Watch((context) => TextField(
              onChanged: (v) => vm.email.value = v,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: vm.emailError.value,
              ),
            )),

            SizedBox(height: 16),

            // Password field
            Watch((context) => TextField(
              onChanged: (v) => vm.password.value = v,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: vm.passwordError.value,
              ),
            )),

            SizedBox(height: 16),

            // Confirm password — reacts to changes in either password field
            Watch((context) => TextField(
              onChanged: (v) => vm.confirmPassword.value = v,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                errorText: vm.confirmError.value,
              ),
            )),

            SizedBox(height: 24),

            // Submit button — re-enables as isValid changes, spinner while saving
            Watch((context) {
              if (vm.signUpState.value.isLoading) {
                return const CircularProgressIndicator();
              }
              return ElevatedButton(
                onPressed: vm.isValid.value ? vm.signUp : null,
                child: const Text('Sign Up'),
              );
            }),
          ],
        ),
      ),
    );
  }
}
```

## What's happening

1. **Derived validation** — each error is a `computed()` that recomputes when
   the fields it reads change
2. **Cross-field validation** — `confirmError` reacts to *both* password fields,
   not just the one being edited
3. **Reactive submit** — `Watch` re-enables the button as `isValid` flips
4. **No controller boilerplate** — state lives in ViewModel
