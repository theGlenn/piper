# Piper Example App

A complete Flutter app demonstrating Piper state management patterns.

## Features

- **Authentication** — Login flow with form validation and error handling
- **Todo List** — CRUD operations with real-time updates
- **Todo Detail** — Page with task cancellation support

## Patterns Demonstrated

### State Management
- `state()` — Simple synchronous state
- `asyncState()` — Async state with loading/error/data
- `bind()` — Stream binding to StateHolder
- `bindAsync()` — Stream binding to AsyncStateHolder

### Async Operations
- `load()` — Load data into AsyncStateHolder
- `launchWith()` — Async with success/error callbacks
- `Task` — Cancellable async work

### UI Widgets
- `ViewModelScope` — Provide ViewModels to widget tree
- `StateBuilder` — Rebuild on state changes
- `.listen()` — Side effects (snackbars) without rebuild
- `.build()` — Extension method for reactive UI

### Architecture
- Constructor injection for dependencies
- Computed getters for derived state
- Composition root in `main.dart`

## Running

```bash
flutter run
```

Default credentials: `user@example.com` / `password`
