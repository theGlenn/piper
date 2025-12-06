import 'package:flutter/material.dart';
import 'package:piper/piper.dart';

import '../../di/app_dependencies.dart';
import '../../domain/todo.dart';
import 'todo_detail_view_model.dart';

class TodoDetailPage extends StatelessWidget {
  final String todoId;

  const TodoDetailPage({super.key, required this.todoId});

  @override
  Widget build(BuildContext context) {
    final deps = AppDependencies.of(context);

    // Nested ViewModelScope for this detail page
    return ViewModelScope(
      create: [
        () => TodoDetailViewModel(deps.todoRepo, todoId),
      ],
      child: const _TodoDetailContent(),
    );
  }
}

class _TodoDetailContent extends StatefulWidget {
  const _TodoDetailContent();

  @override
  State<_TodoDetailContent> createState() => _TodoDetailContentState();
}

class _TodoDetailContentState extends State<_TodoDetailContent> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  bool _initialized = false;

  @override
  void dispose() {
    if (_initialized) {
      _titleController.dispose();
      _descController.dispose();
    }
    super.dispose();
  }

  void _initControllers(Todo todo) {
    if (!_initialized) {
      _titleController = TextEditingController(text: todo.title);
      _descController = TextEditingController(text: todo.description);
      _initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.vm<TodoDetailViewModel>();

    // Listen for deletion and pop
    return vm.isDeleted.listen(
      onChange: (previous, current) {
        if (current) Navigator.of(context).pop();
      },
      child: StateBuilder<bool>(
          listenable: vm.isLoading.listenable,
          builder: (context, isLoading, _) {
            if (isLoading) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Todo Details'),
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                ),
                body: const Center(child: CircularProgressIndicator()),
              );
            }

            return StateBuilder<Todo?>(
              listenable: vm.todo.listenable,
              builder: (context, todo, _) {
                if (todo == null) {
                  return Scaffold(
                    appBar: AppBar(
                      title: const Text('Todo Details'),
                      backgroundColor:
                          Theme.of(context).colorScheme.inversePrimary,
                    ),
                    body: const Center(child: Text('Todo not found')),
                  );
                }

                _initControllers(todo);

                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Todo Details'),
                    backgroundColor:
                        Theme.of(context).colorScheme.inversePrimary,
                    actions: [
                      StateBuilder<bool>(
                        listenable: vm.isSaving.listenable,
                        builder: (context, isSaving, _) {
                          return IconButton(
                            icon: isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.save),
                            onPressed: isSaving ? null : () => vm.save(),
                            tooltip: 'Save',
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(context, vm),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error message
                        StateBuilder<String?>(
                          listenable: vm.error.listenable,
                          builder: (context, error, _) {
                            if (error == null) return const SizedBox.shrink();
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                error,
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          },
                        ),

                        // Completed toggle
                        Card(
                          child: ListTile(
                            leading: Checkbox(
                              value: todo.completed,
                              onChanged: (_) => vm.toggleCompleted(),
                            ),
                            title: Text(
                              todo.completed ? 'Completed' : 'Not completed',
                            ),
                            subtitle: const Text('Tap checkbox to toggle'),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Title field
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: vm.updateTitle,
                        ),

                        const SizedBox(height: 16),

                        // Description field
                        TextField(
                          controller: _descController,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 5,
                          onChanged: vm.updateDescription,
                        ),

                        const SizedBox(height: 24),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          child: StateBuilder<bool>(
                            listenable: vm.isSaving.listenable,
                            builder: (context, isSaving, _) {
                              return FilledButton.icon(
                                onPressed: isSaving ? null : () => vm.save(),
                                icon: isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: const Text('Save Changes'),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
    );
  }

  void _confirmDelete(BuildContext context, TodoDetailViewModel vm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
        content: const Text('Are you sure you want to delete this todo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              vm.delete();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
