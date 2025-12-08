# Todos

CRUD operations with stream binding.

## ViewModel

```dart
class TodosViewModel extends ViewModel {
  final TodoRepository _todoRepo;

  TodosViewModel(this._todoRepo);

  late final todos = bindAsync(_todoRepo.todosStream);

  List<Todo> get pending => todos.dataOrNull?.where((t) => !t.completed).toList() ?? [];
  List<Todo> get completed => todos.dataOrNull?.where((t) => t.completed).toList() ?? [];

  void loadTodos() {
    load(todos, () => _todoRepo.fetchTodos());
  }

  void addTodo(String title, String description) {
    launchWith(
      () => _todoRepo.addTodo(title, description),
      onSuccess: (_) {},
      onError: (e) => todos.setError('Failed to add todo', error: e),
    );
  }

  void toggleTodo(String id) {
    launchWith(
      () => _todoRepo.toggleTodo(id),
      onSuccess: (_) {},
      onError: (e) => todos.setError('Failed to update todo', error: e),
    );
  }

  void deleteTodo(String id) {
    launchWith(
      () => _todoRepo.deleteTodo(id),
      onSuccess: (_) {},
      onError: (e) => todos.setError('Failed to delete todo', error: e),
    );
  }
}
```

## Widget

```dart
class TodoListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.vm<TodosViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text('Todos')),
      body: vm.todos.build(
        (state) => switch (state) {
          AsyncEmpty() => Center(child: Text('No todos yet')),
          AsyncLoading() => Center(child: CircularProgressIndicator()),
          AsyncError(:final message) => Center(child: Text('Error: $message')),
          AsyncData(:final data) => ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, i) {
              final todo = data[i];
              return ListTile(
                leading: Checkbox(
                  value: todo.completed,
                  onChanged: (_) => vm.toggleTodo(todo.id),
                ),
                title: Text(todo.title),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => vm.deleteTodo(todo.id),
                ),
              );
            },
          ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, vm),
        child: Icon(Icons.add),
      ),
    );
  }
}
```

## What's happening

1. **`bindAsync`** — binds stream with automatic loading/error state
2. **Computed getters** — `pending` and `completed` derived from state
3. **`launchWith`** — async operations with error handling
