import 'package:flutter/widgets.dart';

import '../data/auth_repository.dart';
import '../data/todo_repository.dart';

class AppDependencies extends InheritedWidget {
  final AuthRepository authRepo;
  final TodoRepository todoRepo;

  const AppDependencies({
    super.key,
    required this.authRepo,
    required this.todoRepo,
    required super.child,
  });

  static AppDependencies of(BuildContext context) {
    final result = context.dependOnInheritedWidgetOfExactType<AppDependencies>();
    assert(result != null, 'No AppDependencies found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AppDependencies oldWidget) => false;
}
