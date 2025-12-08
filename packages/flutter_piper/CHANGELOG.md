# Changelog

## 0.0.1

- Initial release
- `ViewModelScope` — provides ViewModels to widget tree
- `StateBuilder` — rebuilds on state changes
- `StateListener` — side effects without rebuilding
- `StateEffect` — post-frame side effects with conditions
- Extension methods: `.build()`, `.listen()` on StateHolder/AsyncStateHolder
- `context.vm<T>()` and `context.maybeVm<T>()` extensions
