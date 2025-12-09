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

# Run all tests with coverage and open combined HTML report (requires lcov)
test-coverage-html:
    just piper::test-coverage
    just flutter_piper::test-coverage
    mkdir -p coverage
    # Fix paths in lcov files to be relative to repo root
    sed 's|SF:lib/|SF:packages/piper/lib/|g' packages/piper/coverage/lcov.info > coverage/piper.lcov.info
    sed 's|SF:lib/|SF:packages/flutter_piper/lib/|g' packages/flutter_piper/coverage/lcov.info > coverage/flutter_piper.lcov.info
    lcov -a coverage/piper.lcov.info -a coverage/flutter_piper.lcov.info -o coverage/lcov.info
    genhtml coverage/lcov.info -o coverage/html
    @echo "Combined HTML report generated at coverage/html/index.html"
    open coverage/html/index.html || xdg-open coverage/html/index.html || echo "Open coverage/html/index.html in your browser"

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