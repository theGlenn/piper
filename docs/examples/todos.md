# Todo List

CRUD operations with stream binding and async state.

## Model

```dart
class Todo {
  final String id;
  final String title;
  final String description;
  final bool completed;

  Todo({
    required this.id,
    required this.title,
    this.description = '',
    this.completed = false,
  });

  Todo copyWith({String? title, String? description, bool? completed}) {
    return Todo(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
    );
  }
}
```

## Repository

```dart
class TodoRepository {
  final _todosController = StreamController<List<Todo>>.broadcast();
  final List<Todo> _todos = [];

  Stream<List<Todo>> get todosStream => _todosController.stream;

  Future<List<Todo>> fetchTodos() async {
    await Future.delayed(Duration(seconds: 1));
    _todosController.add(_todos);
    return _todos;
  }

  Future<void> addTodo(String title, String description) async {
    await Future.delayed(Duration(milliseconds: 300));
    final todo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
    );
    _todos.add(todo);
    _todosController.add(List.from(_todos));
  }

  Future<void> toggleTodo(String id) async {
    await Future.delayed(Duration(milliseconds: 200));
    final index = _todos.indexWhere((t) => t.id == id);
    if (index != -1) {
      _todos[index] = _todos[index].copyWith(completed: !_todos[index].completed);
      _todosController.add(List.from(_todos));
    }
  }

  Future<void> deleteTodo(String id) async {
    await Future.delayed(Duration(milliseconds: 200));
    _todos.removeWhere((t) => t.id == id);
    _todosController.add(List.from(_todos));
  }

  void dispose() => _todosController.close();
}
```

## ViewModel

```dart
import 'package:piper/piper.dart';

class TodosViewModel extends ViewModel {
  final TodoRepository _repo;

  TodosViewModel(this._repo);

  // Bind stream with async state management
  late final todos = bindAsync(_repo.todosStream);

  // Computed properties
  List<Todo> get pending =>
      todos.dataOrNull?.where((t) => !t.completed).toList() ?? [];

  List<Todo> get completed =>
      todos.dataOrNull?.where((t) => t.completed).toList() ?? [];

  void loadTodos() {
    load(todos, () => _repo.fetchTodos());
  }

  void addTodo(String title, String description) {
    launchWith(
      () => _repo.addTodo(title, description),
      onSuccess: (_) {},
      onError: (e) => todos.setError('Failed to add todo', error: e),
    );
  }

  void toggleTodo(String id) {
    launchWith(
      () => _repo.toggleTodo(id),
      onSuccess: (_) {},
      onError: (e) => todos.setError('Failed to update todo', error: e),
    );
  }

  void deleteTodo(String id) {
    launchWith(
      () => _repo.deleteTodo(id),
      onSuccess: (_) {},
      onError: (e) => todos.setError('Failed to delete todo', error: e),
    );
  }
}
```

## Todo List Page

```dart
class TodoListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = context.vm<TodosViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Todos'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: vm.loadTodos,
          ),
        ],
      ),
      body: vm.todos.build(
        (state) => switch (state) {
          AsyncEmpty() => _EmptyState(onLoad: vm.loadTodos),
          AsyncLoading() => Center(child: CircularProgressIndicator()),
          AsyncError(:final message) => _ErrorState(
            message: message,
            onRetry: vm.loadTodos,
          ),
          AsyncData(:final data) => data.isEmpty
            ? _EmptyTodos()
            : _TodoList(todos: data, vm: vm),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, vm),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context, TodosViewModel vm) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Todo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              vm.addTodo(titleController.text, descController.text);
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _TodoList extends StatelessWidget {
  final List<Todo> todos;
  final TodosViewModel vm;

  const _TodoList({required this.todos, required this.vm});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: todos.length,
      itemBuilder: (context, index) {
        final todo = todos[index];
        return ListTile(
          leading: Checkbox(
            value: todo.completed,
            onChanged: (_) => vm.toggleTodo(todo.id),
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.completed ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: todo.description.isNotEmpty ? Text(todo.description) : null,
          trailing: IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => vm.deleteTodo(todo.id),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onLoad;

  const _EmptyState({required this.onLoad});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onLoad,
        child: Text('Load Todos'),
      ),
    );
  }
}

class _EmptyTodos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('No todos yet. Add one!'));
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Error: $message'),
          SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: Text('Retry')),
        ],
      ),
    );
  }
}
```

## Setup

```dart
void main() {
  final todoRepo = TodoRepository();

  runApp(
    ViewModelScope(
      create: [() => TodosViewModel(todoRepo)],
      child: MaterialApp(home: TodoListPage()),
    ),
  );
}
```

## What's Happening

1. **`bindAsync()`** — Binds stream with automatic loading/error states
2. **Computed getters** — `pending` and `completed` derive from state
3. **`launchWith()`** — Async operations with error handling
4. **Pattern matching** — Clean handling of all async states
