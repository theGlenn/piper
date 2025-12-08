# Authentication

Stream binding with async operations.

## ViewModel

```dart
class AuthViewModel extends ViewModel {
  final AuthRepository _authRepo;

  AuthViewModel(this._authRepo);

  // Stream bound to state — updates when user changes
  late final user = streamTo<User?>(_authRepo.userStream, initial: null);
  late final authState = asyncState<void>();

  bool get isLoggedIn => user.value != null;

  void login(String email, String password) {
    load(authState, () => _authRepo.login(email, password));
  }

  void logout() {
    load(authState, () => _authRepo.logout());
  }
}
```

## Widget

```dart
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.vm<AuthViewModel>();

    return vm.user.build((user) {
      if (user == null) {
        return LoginPage();
      }
      return HomePage();
    });
  }
}

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.vm<AuthViewModel>();

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _emailController),
            TextField(controller: _passwordController, obscureText: true),
            vm.authState.build(
              (state) => switch (state) {
                AsyncLoading() => CircularProgressIndicator(),
                AsyncError(:final message) => Text(message, style: TextStyle(color: Colors.red)),
                _ => ElevatedButton(
                  onPressed: () => vm.login(
                    _emailController.text,
                    _passwordController.text,
                  ),
                  child: Text('Login'),
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

1. **`streamTo`** — binds the user stream to a StateHolder, auto-cancels on dispose
2. **`load`** — handles loading/error states automatically
3. **Reactive UI** — `AuthGate` rebuilds when user changes
