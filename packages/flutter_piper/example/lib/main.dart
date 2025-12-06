import 'package:flutter/material.dart';
import 'package:piper/flutter_piper.dart';

import 'data/auth_repository.dart';
import 'data/todo_repository.dart';
import 'di/app_dependencies.dart';
import 'features/auth/auth_view_model.dart';
import 'features/auth/login_page.dart';
import 'features/todos/todo_list_page.dart';
import 'features/todos/todos_view_model.dart';

void main() {
  // Create dependencies at the composition root
  final authRepo = AuthRepository();
  final todoRepo = TodoRepository();

  runApp(
    // Provide dependencies to the entire app
    AppDependencies(
      authRepo: authRepo,
      todoRepo: todoRepo,
      // ViewModelScope provides ViewModels to descendants
      child: ViewModelScope(
        create: [
          () => AuthViewModel(authRepo),
          () => TodosViewModel(todoRepo),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rivolo Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.vm<AuthViewModel>();

    // Rebuild when user changes (logged in/out)
    return StateBuilder(
      listenable: authVm.user.listenable,
      builder: (context, user, __) {
        if (user != null) {
          return const TodoListPage();
        }
        return const LoginPage();
      },
    );
  }
}
