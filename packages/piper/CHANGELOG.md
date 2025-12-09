# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
