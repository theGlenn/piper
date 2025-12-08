# Form Validation

Reactive forms with computed validation state.

## ViewModel

```dart
class SignUpViewModel extends ViewModel {
  late final email = state('');
  late final password = state('');
  late final confirmPassword = state('');
  late final signUpState = asyncState<void>();

  // Computed validations
  String? get emailError {
    if (email.value.isEmpty) return null;
    if (!email.value.contains('@')) return 'Invalid email';
    return null;
  }

  String? get passwordError {
    if (password.value.isEmpty) return null;
    if (password.value.length < 8) return 'At least 8 characters';
    return null;
  }

  String? get confirmError {
    if (confirmPassword.value.isEmpty) return null;
    if (confirmPassword.value != password.value) return 'Passwords don\'t match';
    return null;
  }

  bool get isValid =>
      email.value.isNotEmpty &&
      password.value.isNotEmpty &&
      emailError == null &&
      passwordError == null &&
      confirmError == null;

  void signUp() {
    if (!isValid) return;
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
            // Email field with error
            vm.email.build((email) => TextField(
              onChanged: (v) => vm.email.value = v,
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: vm.emailError,
              ),
            )),

            SizedBox(height: 16),

            // Password field with error
            vm.password.build((password) => TextField(
              onChanged: (v) => vm.password.value = v,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: vm.passwordError,
              ),
            )),

            SizedBox(height: 16),

            // Confirm password with error
            vm.confirmPassword.build((_) => TextField(
              onChanged: (v) => vm.confirmPassword.value = v,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                errorText: vm.confirmError,
              ),
            )),

            SizedBox(height: 24),

            // Submit button
            vm.signUpState.build(
              (state) => switch (state) {
                AsyncLoading() => CircularProgressIndicator(),
                _ => ElevatedButton(
                  onPressed: vm.isValid ? vm.signUp : null,
                  child: Text('Sign Up'),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

## What's happening

1. **Computed getters** — validation logic as pure functions
2. **Reactive fields** — each field rebuilds only when it changes
3. **Derived state** — `isValid` computed from multiple fields
4. **No controller boilerplate** — state lives in ViewModel
