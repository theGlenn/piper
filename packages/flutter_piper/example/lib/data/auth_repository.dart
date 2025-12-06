import 'dart:async';

import '../domain/user.dart';

class AuthRepository {
  final _userController = StreamController<User?>.broadcast();
  User? _currentUser;

  Stream<User?> get userStream => _userController.stream;
  User? get currentUser => _currentUser;

  Future<void> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Simulate validation
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }

    if (password.length < 4) {
      throw Exception('Password must be at least 4 characters');
    }

    // Simulate successful login
    _currentUser = User(
      id: '1',
      name: email.split('@').first,
      email: email,
    );
    _userController.add(_currentUser);
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
    _userController.add(null);
  }

  void dispose() {
    _userController.close();
  }
}
