# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] - 2026-07-29

### Changed

- Refined the package description, README, and pub.dev topics around Piper's
  lifecycle-owned cleanup, automatic rebuilds, visible dependencies, and plain
  Dart ViewModels.

## [0.1.0] - 2026-07-23

### Added

- `computed()` / `Computed<T>` — derived state that recomputes automatically
  when its dependencies change, with configurable `equals` and cycle detection.
- Automatic dependency tracking (`PiperTracker`, `Trackable`): reading
  `StateHolder.value` inside a tracked scope subscribes the reader.
- Configurable `equals` on `StateHolder`, `state()`, and `computed()`.
- `AsyncError.from()` and `AsyncStateHolder.setErrorFrom()` — preserve the
  original error object and stack trace instead of collapsing to a string.
- `TaskCancellationToken` with `wait()`, `onCancel()`, and `throwIfCancelled()`
  for cooperative task cancellation.

### Changed

- `launch()` and `launchWith()` now receive a `TaskCancellationToken`. This is
  a breaking callback-signature change.
- `launchWith()` and `load()` now return their `Task` handles.
- Cancelled task results settle immediately instead of waiting for the
  underlying Future to finish.
- Notifications are batched so derived state settles before listeners fire
  (glitch-free updates across diamond dependency graphs).

### Removed

- `reload()` — use `load()`.
- `AsyncState.lift()` — use `when()`.

## [0.0.3] - 2025-12-09

### Changed

- Updated SDK constraint to ^3.6.0
- Updated meta dependency to ^1.11.0

## [0.0.2] - 2025-12-08

### Changed

- Version bump for flutter_piper compatibility

## [0.0.1] - 2025-12-08

### Added

- `StateHolder<T>` — synchronous state with change notification
- `AsyncStateHolder<T>` — async state with loading/error/data handling
- `AsyncState<T>` — sealed class for representing async operation states
- `ViewModel` — lifecycle-aware base class with automatic cleanup
- `Task` — cancellable async operations
- `TaskScope` — manages multiple tasks with collective cancellation
- Stream bindings: `bind()`, `stateFrom()`, `bindAsync()`
- `load()` and `launchWith()` helpers for async operations
- `TestScope` for testing ViewModels without Flutter
