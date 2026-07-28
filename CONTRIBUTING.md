# Contributing to Piper

Thanks for helping make Piper clearer, safer, and easier to use.

## Before opening an issue

- Search existing issues and documentation first.
- Include a minimal reproduction for bugs when possible.
- Describe the outcome you expected and what happened instead.
- For API ideas, explain the Flutter use case before proposing a shape.

## Local setup

Piper uses a Dart workspace with Flutter integration tests.

```sh
flutter pub get
just ci
```

To work on the documentation:

```sh
cd docs
pnpm install
pnpm docs:check
```

## Pull requests

- Keep each pull request focused on one problem.
- Add or update tests for behavioral changes.
- Update public documentation and changelogs when an API changes.
- Run `just ci` before requesting review.
- Run `pnpm docs:check` when documentation or site configuration changes.

Small fixes are welcome. For larger API changes, open an issue first so the
design and migration path can be discussed before implementation.
