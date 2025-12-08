# Comparison

## vs. Riverpod

| Aspect | Riverpod | Piper |
|--------|----------|-------|
| Dependencies | `ref.watch`, `ref.read` | Constructor injection |
| Learning curve | Provider types, modifiers, scoping | Plain Dart classes |
| State declaration | Providers with annotations | `state()` in ViewModel |
| Async state | `AsyncValue`, `.when()` | `AsyncState`, `.when()` |
| Testing | `ProviderContainer` | Plain unit tests |

## vs. Bloc

| Aspect | Bloc | Piper |
|--------|------|-------|
| State changes | Events → Bloc → States | Methods → State |
| Boilerplate | Event classes, State classes | Just methods |
| Async handling | `emit()` with streams | `launch()`, `load()` |
| Testing | `blocTest()` | Plain unit tests |

## When to use Piper

- You prefer explicit constructor injection over implicit dependency resolution
- You want lifecycle management without ceremony
- You're coming from Android/iOS and want familiar ViewModel patterns
- You want to test business logic without framework utilities
- You're adopting incrementally alongside existing state solutions
