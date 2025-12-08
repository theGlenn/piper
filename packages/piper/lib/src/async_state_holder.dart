import 'async_state.dart';
import 'state_holder.dart';

/// Extended [StateHolder] for async operations with built-in state management.
///
/// Wraps [AsyncState] and provides convenient methods for state transitions.
///
/// Example:
/// ```dart
/// class UserViewModel extends ViewModel {
///   late final user = asyncState<User>();
///
///   void loadUser() => load(user, () => _repo.getUser());
/// }
/// ```
class AsyncStateHolder<T> extends StateHolder<AsyncState<T>> {
  /// Creates an [AsyncStateHolder] in the empty state.
  AsyncStateHolder() : super(const AsyncEmpty());

  /// Creates an [AsyncStateHolder] in the loading state.
  AsyncStateHolder.loading() : super(const AsyncLoading());

  /// Creates an [AsyncStateHolder] with initial data.
  AsyncStateHolder.data(T data) : super(AsyncData(data));

  // Convenience getters

  /// Whether the current state is loading.
  bool get isLoading => value.isLoading;

  /// Whether the current state has an error.
  bool get hasError => value.hasError;

  /// Whether the current state has data.
  bool get hasData => value.hasData;

  /// Whether the current state is empty.
  bool get isEmpty => value.isEmpty;

  /// Returns the data if available, otherwise null.
  T? get dataOrNull => value.dataOrNull;

  /// Returns the error message if available, otherwise null.
  String? get errorOrNull => value.errorOrNull;

  // State transitions

  /// Transitions to the loading state.
  void setLoading() => value = const AsyncLoading();

  /// Transitions to the data state with the given data.
  void setData(T data) => value = AsyncData(data);

  /// Transitions to the error state with a message and optional error object.
  void setError(String message, {Object? error}) =>
      value = AsyncError(message, error: error);

  /// Transitions to the empty state.
  void setEmpty() => value = const AsyncEmpty();
}
