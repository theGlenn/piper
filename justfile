# Get dependencies for client_package
get-client_package:
    dart pub -C packages/client_package get

# Publish flutter_piper package
publish-flutter_piper:
    dart pub -C packages/flutter_piper publish

# Publish piper package
publish-piper:
    dart pub -C packages/piper publish
