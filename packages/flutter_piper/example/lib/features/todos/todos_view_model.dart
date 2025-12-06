import 'package:example/data/todo_repository.dart';
import 'package:example/domain/todo.dart';
import 'package:piper/flutter_piper.dart';

class TodosViewModel extends ViewModel {
  final TodoRepository _todoRepo;

  TodosViewModel(this._todoRepo);

  late final todos = streamToAsync<List<Todo>>(_todoRepo.todosStream);

  List<Todo> get pendingTodos =>
      todos.dataOrNull?.where((t) => !t.completed).toList() ?? [];
  List<Todo> get completedTodos =>
      todos.dataOrNull?.where((t) => t.completed).toList() ?? [];

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
