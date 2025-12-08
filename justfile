# Get dependencies for client_package
get-client_package:
    dart pub -C packages/client_package get

# Publish flutter_piper package
publish-flutter_piper:
    dart pub -C packages/flutter_piper publish

# Publish piper package
publish-piper:
    dart pub -C packages/piper publish

# Run tests for flutter_piper package
test-flutter_piper:
    dart test -C packages/flutter_piper

# Run tests for piper package
test-piper:
    dart test -C packages/piper

# Run tests for all packages
test: test-flutter_piper test-piper

show-website-dev:
    cd docs && pnpm run docs:dev