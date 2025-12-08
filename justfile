mod flutter_piper 'packages/flutter_piper'
mod piper 'packages/piper'

default:
    @just --list

# Get dependencies across all packages
deps:
    just piper::deps
    just flutter_piper::deps

# Clean build artifacts across all packages
clean:
    just piper::clean
    just flutter_piper::clean

# Run all tests across all packages
test:
    just piper::test
    just flutter_piper::test

# Run all tests with coverage across all packages
test-coverage:
    just piper::test-coverage
    just flutter_piper::test-coverage

# Analyze code for issues across all packages
analyze:
    just piper::analyze
    just flutter_piper::analyze

# Format all Dart files across all packages
format:
    just piper::format
    just flutter_piper::format

publish-dry-run:
    just piper::publish-dry-run
    just flutter_piper::publish-dry-run

publish:
    just piper::publish
    just flutter_piper::publish

bump-version:
    just piper::bump-version
    just flutter_piper::bump-version

# Run tests and analyze
ci: deps analyze test

show-website-dev:
    cd docs && pnpm run docs:dev