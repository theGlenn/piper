import 'package:flutter/material.dart';
import 'package:flutter_piper/flutter_piper.dart';

import '../../domain/todo.dart';
import '../auth/auth_view_model.dart';
import 'todo_detail_page.dart';
import 'todos_view_model.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  @override
  void initState() {
    super.initState();
    // Load todos when page is first shown
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.vm<TodosViewModel>().loadTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.vm<AuthViewModel>();
    final todosVm = context.vm<TodosViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Todos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authVm.logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: StateBuilder<AsyncState<List<Todo>>>(
        listenable: todosVm.todos.flutterListenable,
        builder: (context, state, _) {
          return state.when(
            empty: () => const Center(child: CircularProgressIndicator()),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (message) => _ErrorView(
              error: message,
              onRetry: todosVm.loadTodos,
            ),
            data: (todos) => _TodoList(todosVm: todosVm),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTodoDialog(context, todosVm),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTodoDialog(BuildContext context, TodosViewModel todosVm) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Todo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                todosVm.addTodo(titleController.text, descController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _TodoList extends StatelessWidget {
  final TodosViewModel todosVm;

  const _TodoList({required this.todosVm});

  @override
  Widget build(BuildContext context) {
    final pending = todosVm.pendingTodos;
    final completed = todosVm.completedTodos;

    if (pending.isEmpty && completed.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No todos yet', style: TextStyle(color: Colors.grey)),
            Text('Tap + to add one', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => todosVm.refresh(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 80),
        children: [
          if (pending.isNotEmpty) ...[
            const _SectionHeader(title: 'To Do'),
            ...pending.map(
              (todo) => _TodoTile(
                todo: todo,
                onToggle: () => todosVm.toggleTodo(todo.id),
                onTap: () => _navigateToDetail(context, todo),
                onDelete: () => todosVm.deleteTodo(todo.id),
              ),
            ),
          ],
          if (completed.isNotEmpty) ...[
            const _SectionHeader(title: 'Completed'),
            ...completed.map(
              (todo) => _TodoTile(
                todo: todo,
                onToggle: () => todosVm.toggleTodo(todo.id),
                onTap: () => _navigateToDetail(context, todo),
                onDelete: () => todosVm.deleteTodo(todo.id),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Todo todo) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TodoDetailPage(todoId: todo.id)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TodoTile({
    required this.todo,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: Checkbox(
          value: todo.completed,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.completed ? TextDecoration.lineThrough : null,
            color: todo.completed ? Colors.grey : null,
          ),
        ),
        subtitle: todo.description.isNotEmpty
            ? Text(
                todo.description,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
