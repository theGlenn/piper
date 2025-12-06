import 'dart:async';

import 'package:example/domain/todo.dart';


class TodoRepository {
  final _todosController = StreamController<List<Todo>>.broadcast();
  final List<Todo> _todos = [
    const Todo(
      id: '1',
      title: 'Learn Rivolo',
      description: 'Understand the ViewModel pattern and state management',
    ),
    const Todo(
      id: '2',
      title: 'Build an app',
      description: 'Create a todo app using Rivolo',
    ),
    const Todo(
      id: '3',
      title: 'Write tests',
      description: 'Add unit tests for ViewModels',
      completed: true,
    ),
  ];

  int _nextId = 4;

  Stream<List<Todo>> get todosStream => _todosController.stream;

  Future<List<Todo>> fetchTodos() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    _todosController.add(List.unmodifiable(_todos));
    return _todos;
  }

  Future<Todo?> getTodoById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _todos.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Todo> addTodo(String title, String description) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final todo = Todo(
      id: '${_nextId++}',
      title: title,
      description: description,
    );

    _todos.add(todo);
    _todosController.add(List.unmodifiable(_todos));

    return todo;
  }

  Future<void> updateTodo(Todo todo) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _todos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      _todos[index] = todo;
      _todosController.add(List.unmodifiable(_todos));
    }
  }

  Future<void> toggleTodo(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      final todo = _todos[index];
      _todos[index] = todo.copyWith(completed: !todo.completed);
      _todosController.add(List.unmodifiable(_todos));
    }
  }

  Future<void> deleteTodo(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));

    _todos.removeWhere((t) => t.id == id);
    _todosController.add(List.unmodifiable(_todos));
  }

  void dispose() {
    _todosController.close();
  }
}
