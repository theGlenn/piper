import 'dart:async';

/// Thrown inside task work when its [TaskCancellationToken] is cancelled.
final class TaskCancelledException implements Exception {
  const TaskCancelledException();

  @override
  String toString() => 'TaskCancelledException: The task was cancelled';
}

/// Cooperative cancellation passed to work launched by a [TaskScope].
///
/// Await asynchronous operations through [wait] so cancellation interrupts the
/// task body. Use [onCancel] when the underlying operation also exposes an
/// abort API.
final class TaskCancellationToken {
  final Completer<void> _whenCancelled = Completer<void>();
  final List<void Function()> _callbacks = [];
  bool _isCancelled = false;

  TaskCancellationToken._();

  /// Whether cancellation has been requested.
  bool get isCancelled => _isCancelled;

  /// Completes when cancellation is requested.
  Future<void> get whenCancelled => _whenCancelled.future;

  /// Throws [TaskCancelledException] if cancellation has been requested.
  void throwIfCancelled() {
    if (_isCancelled) throw const TaskCancelledException();
  }

  /// Awaits [future] until it completes or cancellation is requested.
  ///
  /// Cancellation stops execution after this await. It cannot abort the
  /// underlying operation unless that operation exposes an abort API; register
  /// that API with [onCancel].
  Future<R> wait<R>(Future<R> future) async {
    throwIfCancelled();
    final value = await Future.any<R>([
      future,
      whenCancelled.then<R>((_) => throw const TaskCancelledException()),
    ]);
    throwIfCancelled();
    return value;
  }

  /// Registers a synchronous callback that aborts underlying work.
  ///
  /// Returns a function that removes the callback. If cancellation has already
  /// happened, [callback] runs immediately.
  void Function() onCancel(void Function() callback) {
    if (_isCancelled) {
      callback();
      return _doNothing;
    }

    _callbacks.add(callback);
    var isRegistered = true;
    return () {
      if (!isRegistered) return;
      isRegistered = false;
      _callbacks.remove(callback);
    };
  }

  void _cancel() {
    if (_isCancelled) return;
    _isCancelled = true;

    Object? firstError;
    StackTrace? firstStackTrace;
    final callbacks = List<void Function()>.of(_callbacks);
    _callbacks.clear();
    for (final callback in callbacks) {
      try {
        callback();
      } catch (error, stackTrace) {
        firstError ??= error;
        firstStackTrace ??= stackTrace;
      }
    }
    _whenCancelled.complete();

    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStackTrace!);
    }
  }

  void _finish() => _callbacks.clear();

  static void _doNothing() {}
}

/// Handle to cancellable async work.
///
/// Cancellation settles [result] with `null` and interrupts the task at any
/// [TaskCancellationToken.wait] or [TaskCancellationToken.throwIfCancelled]
/// boundary.
///
/// Example:
/// ```dart
/// final task = taskScope.launch((cancellation) async {
///   final data = await cancellation.wait(fetchData());
///   updateState(data);
/// });
/// task.cancel();
/// ```
final class Task<T> {
  final TaskCancellationToken _cancellation;
  late final Future<T> _completion;
  bool _completed = false;

  Task._(Future<T> future, this._cancellation) {
    _completion = _cancellation.wait(future);
    _completion.then(
      (_) => _finish(),
      onError: (_, __) => _finish(),
    );
  }

  void _finish() {
    _completed = true;
    _cancellation._finish();
  }

  /// Whether this task has been cancelled.
  bool get isCancelled => _cancellation.isCancelled;

  /// Whether this task has completed or cancellation has settled it.
  bool get isCompleted => _completed;

  /// Whether the task is still running and not cancelled.
  bool get isActive => !isCancelled && !_completed;

  /// Requests cancellation.
  ///
  /// Calling this more than once has no effect.
  void cancel() {
    if (_completed) return;
    _cancellation._cancel();
  }

  /// Awaits the result, returning `null` if cancelled.
  ///
  /// Rethrows non-cancellation errors with their original stack trace.
  Future<T?> get result async {
    try {
      return await _completion;
    } on TaskCancelledException {
      return null;
    }
  }
}

/// Manages multiple [Task]s with collective cancellation.
///
/// Tasks launched through a [TaskScope] are automatically tracked and removed
/// when settled. Disposing the scope cancels all active tasks.
final class TaskScope {
  final List<Task<dynamic>> _tasks = [];
  bool _disposed = false;

  /// Whether this scope has been disposed.
  bool get isDisposed => _disposed;

  /// Launches async work and returns a [Task] handle.
  ///
  /// Use the supplied [TaskCancellationToken] for cancellation-aware awaits.
  /// Throws [StateError] if the scope has been disposed.
  Task<T> launch<T>(
    Future<T> Function(TaskCancellationToken cancellation) work,
  ) {
    if (_disposed) {
      throw StateError('Cannot launch task on disposed TaskScope');
    }

    final cancellation = TaskCancellationToken._();
    final future = Future<T>.sync(() => work(cancellation));
    final task = Task<T>._(future, cancellation);
    _tasks.add(task);
    task._completion.then(
      (_) => _tasks.remove(task),
      onError: (_, __) => _tasks.remove(task),
    );
    return task;
  }

  /// Launches async work with inline result handling.
  ///
  /// [onSuccess] receives the result if the task completes. [onError] receives
  /// non-cancellation errors. Neither callback runs after cancellation.
  Task<T> launchWith<T>(
    Future<T> Function(TaskCancellationToken cancellation) work, {
    required void Function(T) onSuccess,
    void Function(Object error)? onError,
  }) {
    final task = launch(work);
    task._completion.then(
      onSuccess,
      onError: (Object error, StackTrace _) {
        if (error is TaskCancelledException) return;
        onError?.call(error);
      },
    );
    return task;
  }

  /// Cancels all active tasks without disposing the scope.
  void cancelAll() {
    final activeTasks = List<Task<dynamic>>.of(_tasks);
    _tasks.clear();
    for (final task in activeTasks) {
      task.cancel();
    }
  }

  /// Disposes the scope and cancels all active tasks.
  ///
  /// After disposal, no new tasks can be launched.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    cancelAll();
  }
}
