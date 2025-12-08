# Authentication

Stream binding with login/logout operations.

## Repository

```dart
class AuthRepository {
  final _userController = StreamController<User?>.broadcast();

  Stream<User?> get userStream => _userController.stream;

  Future<void> login(String email, String password) async {
    await Future.delayed(Duration(seconds: 1)); // Simulate network
    if (email == 'test@test.com' && password == 'password') {
      _userController.add(User(id: '1', email: email, name: 'Test User'));
    } else {
      throw Exception('Invalid credentials');
    }
  }

  Future<void> logout() async {
    await Future.delayed(Duration(milliseconds: 500));
    _userController.add(null);
  }

  void dispose() => _userController.close();
}
```

## ViewModel

```dart
import 'package:piper/piper.dart';

class AuthViewModel extends ViewModel {
  final AuthRepository _auth;

  AuthViewModel(this._auth);

  // Bind user stream — updates automatically
  late final user = bind(_auth.userStream, initial: null);

  // Async state for login operation
  late final loginState = asyncState<void>();

  bool get isLoggedIn => user.value != null;

  void login(String email, String password) {
    load(loginState, () => _auth.login(email, password));
  }

  void logout() {
    load(loginState, () => _auth.logout());
  }

  void clearError() {
    loginState.setEmpty();
  }
}
```

## Auth Gate Widget

```dart
class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.vm<AuthViewModel>();

    return vm.user.build((user) {
      if (user == null) {
        return LoginPage();
      }
      return HomePage(user: user);
    });
  }
}
```

## Login Page

```dart
class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.vm<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 24),
            vm.loginState.build(
              (state) => switch (state) {
                AsyncLoading() => CircularProgressIndicator(),
                AsyncError(:final message) => Column(
                  children: [
                    Text(message, style: TextStyle(color: Colors.red)),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => vm.login(
                        _emailController.text,
                        _passwordController.text,
                      ),
                      child: Text('Try Again'),
                    ),
                  ],
                ),
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

## Home Page

```dart
class HomePage extends StatelessWidget {
  final User user;

  const HomePage({required this.user});

  @override
  Widget build(BuildContext context) {
    final vm = context.vm<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: vm.logout,
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome, ${user.name}!'),
      ),
    );
  }
}
```

## Setup

```dart
void main() {
  final authRepo = AuthRepository();

  runApp(
    ViewModelScope(
      create: [() => AuthViewModel(authRepo)],
      child: MaterialApp(home: AuthGate()),
    ),
  );
}
```

## What's Happening

1. **`bind()`** — Binds the user stream to a StateHolder
2. **`asyncState<void>()`** — Tracks login operation state (loading/error)
3. **`load()`** — Manages the async operation lifecycle
4. **Reactive UI** — AuthGate rebuilds when user changes
5. **Auto cleanup** — Stream subscription cancels on ViewModel dispose
