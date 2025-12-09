# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.3] - 2025-12-09

### Changed

- Updated SDK constraint to ^3.6.0
- Updated piper_state dependency to ^0.0.3
- Added explicit platform support for all Flutter platforms

## [0.0.2] - 2025-12-08

### Added

- `Scoped<T>` — new widget for single ViewModel scoping with builder pattern
- `Scoped.withContext` — variant with BuildContext access for dependency injection
- `ViewModelScope.withContext` — added BuildContext variant for dependency injection
- Named scopes via `name` parameter on `ViewModelScope` and `Scoped`
- `context.scoped<T>()` extension for accessing scoped ViewModels

## [0.0.1] - 2025-12-08

### Added

- `ViewModelScope` — provides ViewModels to widget tree
- `StateBuilder` — rebuilds on state changes
- `StateBuilder2` — rebuilds when either of two listenables change
- `StateBuilder3` — rebuilds when any of three listenables change
- `StateListener` — side effects without rebuilding
- `StateEffect` — post-frame side effects with conditions
- Extension methods: `.build()`, `.buildWithChild()`, `.listen()` on StateHolder
- Extension methods: `.displayWhen()`, `.displayWhenData()`, `.listenAsync()` on AsyncStateHolder
- `context.vm<T>()` and `context.maybeVm<T>()` extensions for accessing ViewModels
