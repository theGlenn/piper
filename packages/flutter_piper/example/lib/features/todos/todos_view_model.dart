import 'package:example/data/todo_repository.dart';
import 'package:example/domain/todo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_piper/flutter_piper.dart';

class TodosViewModel extends ViewModel {
  final TodoRepository _todoRepo;

  TodosViewModel(this._todoRepo);

  late final todos = bindAsync<List<Todo>>(_todoRepo.todosStream);

  // Derived state: recomputes when `todos` changes, and — because each run
  // allocates a fresh list — `listEquals` stops it notifying when the filtered
  // result is unchanged. A `Watch` reading these rebuilds reactively.
  late final pendingTodos = computed(
    () => todos.value.dataOrNull?.where((t) => !t.completed).toList() ?? const [],
    equals: (a, b) => listEquals(a, b),
  );
  late final completedTodos = computed(
    () => todos.value.dataOrNull?.where((t) => t.completed).toList() ?? const [],
    equals: (a, b) => listEquals(a, b),
  );

  void loadTodos() {
    load(todos, () => _todoRepo.fetchTodos());
  }

  void refresh() {
    loadTodos();
  }

  void toggleTodo(String id) {
    launchWith(
      () => _todoRepo.toggleTodo(id),
      onSuccess: (_) {},
      onError: (e) {
        todos.setError('Failed to update todo', error: e);
      },
    );
  }

  void addTodo(String title, String description) {
    launchWith(
      () => _todoRepo.addTodo(title, description),
      onSuccess: (_) {},
      onError: (e) {
        todos.setError('Failed to add todo', error: e);
      },
    );
  }

  void deleteTodo(String id) {
    launchWith(
      () => _todoRepo.deleteTodo(id),
      onSuccess: (_) {},
      onError: (e) {
        todos.setError('Failed to delete todo', error: e);
      },
    );
  }
}
