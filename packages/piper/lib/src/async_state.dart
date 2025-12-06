/// Sealed class representing all possible states of an async operation.
///
/// Use pattern matching or the [when]/[maybeWhen] methods to handle each state.
///
/// Example:
/// ```dart
/// final state = AsyncData<User>(user);
/// state.when(
///   empty: () => Text('No data'),
///   loading: () => CircularProgressIndicator(),
///   error: (msg) => Text('Error: $msg'),
///   data: (user) => Text('Hello, ${user.name}'),
/// );
/// ```
sealed class AsyncState<T> {
  const AsyncState();

  // Factory constructors for easy state creation
  const factory AsyncState.empty() = AsyncEmpty<T>;

  const factory AsyncState.loading() = AsyncLoading<T>;

  factory AsyncState.error(String message, {Object? error}) = AsyncError<T>;

  const factory AsyncState.data(T data) = AsyncData<T>;

  /// Whether this state is loading.
  bool get isLoading => this is AsyncLoading<T>;

  /// Whether this state has an error.
  bool get hasError => this is AsyncError<T>;

  /// Whether this state has data.
  bool get hasData => this is AsyncData<T>;

  /// Whether this state is empty.
  bool get isEmpty => this is AsyncEmpty<T>;

  /// Returns the data if available, otherwise null.
  T? get dataOrNull => switch (this) {
    AsyncData(data: var d) => d,
    _ => null,
  };

  /// Returns the error message if available, otherwise null.
  String? get errorOrNull => switch (this) {
    AsyncError(message: var m) => m,
    _ => null,
  };

  /// Transform data if present.
  ///
  /// Returns a new [AsyncState] with the transformed data, or the same
  /// state type (empty/loading/error) if there's no data.
  AsyncState<R> map<R>(R Function(T data) transform) => switch (this) {
    AsyncEmpty() => AsyncEmpty<R>(),
    AsyncLoading() => AsyncLoading<R>(),
    AsyncError(message: var m, error: var e) => AsyncError<R>(m, error: e),
    AsyncData(data: var d) => AsyncData(transform(d)),
  };

  /// Handle all cases exhaustively.
  ///
  /// All callbacks are required, ensuring you handle every state.
  R when<R>({
    required R Function() empty,
    required R Function() loading,
    required R Function(String message) error,
    required R Function(T data) data,
  }) => switch (this) {
    AsyncEmpty() => empty(),
    AsyncLoading() => loading(),
    AsyncError(message: var m) => error(m),
    AsyncData(data: var d) => data(d),
  };

  R lift<R>({
    required R Function() empty,
    required R Function() loading,
    required R Function(String message) error,
    required R Function(T data) data,
  }) => switch (this) {
    AsyncEmpty() => empty(),
    AsyncLoading() => loading(),
    AsyncError(message: var m) => error(m),
    AsyncData(data: var d) => data(d),
  };

  /// Handle cases with optional callbacks and a required fallback.
  ///
  /// If a callback is not provided, [orElse] is called instead.
  R maybeWhen<R>({
    R Function()? empty,
    R Function()? loading,
    R Function(String message)? error,
    R Function(T data)? data,
    required R Function() orElse,
  }) => switch (this) {
    AsyncEmpty() => empty?.call() ?? orElse(),
    AsyncLoading() => loading?.call() ?? orElse(),
    AsyncError(message: var m) => error?.call(m) ?? orElse(),
    AsyncData(data: var d) => data?.call(d) ?? orElse(),
  };
}

/// Represents an empty state before any data has been loaded.
class AsyncEmpty<T> extends AsyncState<T> {
  const AsyncEmpty();
}

/// Represents a loading state while data is being fetched.
class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();
}

/// Represents an error state with a message and optional error object.
class AsyncError<T> extends AsyncState<T> {
  /// A human-readable error message.
  final String message;

  /// The original error object, if available.
  final Object? error;

  /// The stack trace associated with the error, if available.
  final StackTrace? stackTrace;

  const AsyncError(this.message, {this.error, this.stackTrace});
}

/// Represents a successful state with data.
class AsyncData<T> extends AsyncState<T> {
  /// The loaded data.
  final T data;

  const AsyncData(this.data);
}
