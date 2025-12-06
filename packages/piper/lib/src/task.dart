/// Handle to async work that can be cancelled (ignore-on-cancel pattern).
///
/// The underlying [Future] runs to completion, but results are discarded
/// if [cancel] was called.
///
/// Example:
/// ```dart
/// final task = taskScope.launch(() => fetchData());
/// task.cancel(); // Results will be ignored
/// ```
class Task<T> {
  final Future<T> _future;
  bool _cancelled = false;
  bool _completed = false;

  Task._(this._future) {
    _future.then((_) => _completed = true, onError: (_) => _completed = true);
  }

  /// Whether this task has been cancelled.
  bool get isCancelled => _cancelled;

  /// Whether the underlying future has completed.
  bool get isCompleted => _completed;

  /// Whether the task is still running and not cancelled.
  bool get isActive => !_cancelled && !_completed;

  /// Cancels this task. Results will be ignored.
  void cancel() => _cancelled = true;

  /// Awaits the result, returning null if cancelled.
  ///
  /// Rethrows errors unless cancelled.
  Future<T?> get result async {
    try {
      final value = await _future;
      return _cancelled ? null : value;
    } catch (e) {
      if (_cancelled) return null;
      rethrow;
    }
  }
}

/// Manages multiple [Task]s with collective cancellation.
///
/// Tasks launched through a [TaskScope] are automatically tracked
/// and can be cancelled together when the scope is disposed.
///
/// Example:
/// ```dart
/// final scope = TaskScope();
/// scope.launch(() => fetchUsers());
/// scope.launch(() => fetchPosts());
/// scope.dispose(); // Cancels all tasks
/// ```
class TaskScope {
  final List<Task<dynamic>> _tasks = [];
  bool _disposed = false;

  /// Whether this scope has been disposed.
  bool get isDisposed => _disposed;

  /// Launches async work and returns a [Task] handle.
  ///
  /// Throws [StateError] if the scope has been disposed.
  Task<T> launch<T>(Future<T> Function() work) {
    if (_disposed) {
      throw StateError('Cannot launch task on disposed TaskScope');
    }
    final task = Task._(work());
    _tasks.add(task);
    return task;
  }

  /// Launches async work with inline result handling.
  ///
  /// [onSuccess] is called with the result if the task completes
  /// without being cancelled.
  ///
  /// [onError] is called if an error occurs and the task wasn't cancelled.
  void launchWith<T>(
    Future<T> Function() work, {
    required void Function(T) onSuccess,
    void Function(Object error)? onError,
  }) {
    final task = launch(work);
    task.result.then(
      (value) {
        if (value != null && !task.isCancelled) {
          onSuccess(value);
        }
      },
      onError: (e) {
        if (!task.isCancelled) {
          onError?.call(e);
        }
      },
    );
  }

  /// Cancels all active tasks without disposing the scope.
  void cancelAll() {
    for (final task in _tasks) {
      task.cancel();
    }
    _tasks.clear();
  }

  /// Disposes the scope and cancels all tasks.
  ///
  /// After disposal, no new tasks can be launched.
  void dispose() {
    _disposed = true;
    cancelAll();
  }
}
