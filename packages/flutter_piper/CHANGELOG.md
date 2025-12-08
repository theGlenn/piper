# Changelog

## 0.0.2

- `Scoped<T>` — new widget for single ViewModel scoping with builder pattern
- `Scoped.withContext` — variant with BuildContext access for dependency injection
- `ViewModelScope.withContext` — added BuildContext variant for dependency injection
- Named scopes via `name` parameter on `ViewModelScope` and `Scoped`
- `context.scoped<T>()` extension for accessing scoped ViewModels

## 0.0.1

- Initial release
- `ViewModelScope` — provides ViewModels to widget tree
- `StateBuilder` — rebuilds on state changes
- `StateListener` — side effects without rebuilding
- `StateEffect` — post-frame side effects with conditions
- Extension methods: `.build()`, `.listen()` on StateHolder/AsyncStateHolder
- `context.vm<T>()` and `context.maybeVm<T>()` extensions
