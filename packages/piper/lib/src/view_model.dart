import 'dart:async';

import 'package:flutter/foundation.dart';

import 'async_state_holder.dart';
import 'state_holder.dart';
import 'task.dart';

/// Optional base class providing lifecycle management conveniences.
///
/// Automatically manages:
/// - [StateHolder] disposal
/// - [StreamSubscription] cancellation
/// - [Task] cancellation via [TaskScope]
///
/// Example:
/// ```dart
/// class CounterViewModel extends ViewModel {
///   late final count = state(0);
///
///   void increment() => count.update((c) => c + 1);
/// }
/// ```
abstract class ViewModel {
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  final List<StateHolder<dynamic>> _holders = [];
  final TaskScope _taskScope = TaskScope();

  TaskScope get taskScope => _taskScope;

  /// Creates a [StateHolder] registered for automatic disposal.
  ///
  /// Use this instead of creating [StateHolder] instances directly
  /// to ensure proper cleanup when the ViewModel is disposed.
  @protected
  StateHolder<T> state<T>(T initial) {
    final holder = StateHolder(initial);
    _holders.add(holder);
    return holder;
  }

  /// Creates an [AsyncStateHolder] registered for automatic disposal.
  ///
  /// Use for managing async operation states (loading/error/data).
  ///
  /// Example:
  /// ```dart
  /// late final user = asyncState<User>();
  /// ```
  @protected
  AsyncStateHolder<T> asyncState<T>() {
    final holder = AsyncStateHolder<T>();
    _holders.add(holder);
    return holder;
  }

  /// Bind a stream directly to a [StateHolder].
  ///
  /// The stream will update the state holder whenever it emits.
  /// Subscription is automatically cancelled on ViewModel disposal.
  ///
  /// Example:
  /// ```dart
  /// late final user = streamTo(_authRepo.userStream, initial: null);
  /// ```
  @protected
  StateHolder<T> streamTo<T>(
    Stream<T> stream, {
    required T initial,
    T Function(T)? transform,
  }) {
    final holder = state<T>(initial);
    subscribe(stream, (data) => holder.value = transform?.call(data) ?? data);
    return holder;
  }

  /// Binds a stream to a [StateHolder] with transformation.
  ///
  /// Creates a [StateHolder] with [initial] value that updates
  /// whenever [stream] emits, applying [transform] to each value.
  ///
  /// Example:
  /// ```dart
  /// late final userName = stateFrom<User, String>(
  ///   authRepo.userStream,
  ///   initial: '',
  ///   transform: (user) => user.name,
  /// );
  /// ```
  @protected
  StateHolder<R> stateFrom<T, R>(
    Stream<T> stream, {
    required R initial,
    required R Function(T) transform,
  }) {
    final holder = state<R>(initial);
    subscribe(stream, (data) => holder.value = transform(data));
    return holder;
  }

  /// Bind a stream to an [AsyncStateHolder] with automatic state management.
  ///
  /// - Starts in loading state
  /// - Transitions to data state on emission
  /// - Transitions to error state on stream error
  ///
  /// Subscription is automatically cancelled on ViewModel disposal.
  ///
  /// Example:
  /// ```dart
  /// late final todos = streamToAsync(_todoRepo.watchAll());
  /// ```
  @protected
  AsyncStateHolder<T> streamToAsync<T>(
    Stream<T> stream, {
    T Function(T)? transform,
  }) {
    final holder = asyncState<T>();
    holder.setLoading();
    subscribe(
      stream,
      (data) => holder.setData(transform?.call(data) ?? data),
      onError: (e) => holder.setError(e.toString(), error: e),
    );
    return holder;
  }

  /// Subscribes to a stream with automatic cancellation on dispose.
  ///
  /// Use this instead of calling [Stream.listen] directly to ensure
  /// the subscription is cancelled when the ViewModel is disposed.
  @protected
  void subscribe<T>(
    Stream<T> stream,
    void Function(T) onData, {
    void Function(Object error)? onError,
  }) {
    _subscriptions.add(
      stream.listen(
        onData,
        onError: onError != null ? (e, _) => onError(e) : null,
      ),
    );
  }

  /// Launches async work tied to ViewModel lifecycle.
  ///
  /// Returns a [Task] handle that can be used to check status
  /// or await results. The task is automatically cancelled
  /// when the ViewModel is disposed.
  @protected
  Task<T> launch<T>(Future<T> Function() work) => _taskScope.launch(work);

  /// Launches async work with inline result handling.
  ///
  /// [onSuccess] is called with the result if the task completes
  /// before the ViewModel is disposed.
  ///
  /// [onError] is called if an error occurs and the ViewModel
  /// hasn't been disposed.
  ///
  /// Example:
  /// ```dart
  /// void save() {
  ///   launchWith(
  ///     () => repository.save(data),
  ///     onSuccess: (_) => saved.value = true,
  ///     onError: (e) => error.value = e.toString(),
  ///   );
  /// }
  /// ```
  @protected
  void launchWith<T>(
    Future<T> Function() work, {
    required void Function(T) onSuccess,
    void Function(Object error)? onError,
  }) {
    _taskScope.launchWith(work, onSuccess: onSuccess, onError: onError);
  }

  /// Executes async work with automatic [AsyncStateHolder] management.
  ///
  /// Sets [holder] to loading, then to data on success or error on failure.
  ///
  /// Example:
  /// ```dart
  /// void loadUser() => load(user, () => _repo.getUser());
  /// ```
  @protected
  void load<T>(AsyncStateHolder<T> holder, Future<T> Function() work) {
    holder.setLoading();
    launchWith(
      work,
      onSuccess: (data) => holder.setData(data),
      onError: (e) => holder.setError(e.toString(), error: e),
    );
  }

  /// Reloads async state (convenience for retry patterns).
  ///
  /// Identical to [load], provided for semantic clarity.
  @protected
  void reload<T>(AsyncStateHolder<T> holder, Future<T> Function() work) =>
      load(holder, work);

  /// Disposes all managed resources.
  ///
  /// Subclasses overriding this method should call `super.dispose()`.
  @mustCallSuper
  void dispose() {
    _taskScope.dispose();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    for (final holder in _holders) {
      holder.dispose();
    }
  }
}
