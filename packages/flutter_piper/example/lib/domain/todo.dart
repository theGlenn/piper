class Todo {
  final String id;
  final String title;
  final String description;
  final bool completed;

  const Todo({
    required this.id,
    required this.title,
    this.description = '',
    this.completed = false,
  });

  Todo copyWith({
    String? title,
    String? description,
    bool? completed,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
    );
  }
}
