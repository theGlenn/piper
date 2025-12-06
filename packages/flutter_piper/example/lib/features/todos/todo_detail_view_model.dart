import 'package:example/domain/todo.dart';
import 'package:piper/piper.dart';

import '../../data/todo_repository.dart';

class TodoDetailViewModel extends ViewModel {
  final TodoRepository _todoRepo;
  final String todoId;

  TodoDetailViewModel(this._todoRepo, this.todoId) {
    _loadTodo();
  }

  late final todo = state<Todo?>(null);
  late final isLoading = state(true);
  late final isSaving = state(false);
  late final error = state<String?>(null);
  late final isDeleted = state(false);

  void _loadTodo() {
    isLoading.value = true;

    launchWith(
      () => _todoRepo.getTodoById(todoId),
      onSuccess: (loadedTodo) {
        todo.value = loadedTodo;
        isLoading.value = false;
      },
      onError: (e) {
        error.value = 'Failed to load todo';
        isLoading.value = false;
      },
    );
  }

  void updateTitle(String title) {
    final current = todo.value;
    if (current == null) return;

    todo.value = current.copyWith(title: title);
  }

  void updateDescription(String description) {
    final current = todo.value;
    if (current == null) return;

    todo.value = current.copyWith(description: description);
  }

  void toggleCompleted() {
    final current = todo.value;
    if (current == null) return;

    todo.value = current.copyWith(completed: !current.completed);
  }

  void save() {
    final current = todo.value;
    if (current == null) return;

    isSaving.value = true;
    error.value = null;

    launchWith(
      () => _todoRepo.updateTodo(current),
      onSuccess: (_) {
        isSaving.value = false;
      },
      onError: (e) {
        isSaving.value = false;
        error.value = 'Failed to save changes';
      },
    );
  }

  void delete() {
    isSaving.value = true;

    launchWith(
      () => _todoRepo.deleteTodo(todoId),
      onSuccess: (_) {
        isSaving.value = false;
        isDeleted.value = true;
      },
      onError: (e) {
        isSaving.value = false;
        error.value = 'Failed to delete todo';
      },
    );
  }
}
