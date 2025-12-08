# Changelog

## 0.0.2

- Version bump for flutter_piper compatibility

## 0.0.1

- Initial release
- `StateHolder<T>` — synchronous state with change notification
- `AsyncStateHolder<T>` — async state with loading/error/data handling
- `ViewModel` — lifecycle-aware base class with automatic cleanup
- `Task` — cancellable async operations
- Stream bindings: `bind()`, `stateFrom()`, `bindAsync()`
- `load()` and `launchWith()` helpers for async operations
- `TestScope` for testing ViewModels without Flutter
