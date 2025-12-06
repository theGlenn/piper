import 'package:flutter/foundation.dart' as flutter;
import 'package:piper/piper.dart' as piper;

/// Adapts piper's [piper.ValueListenable] to Flutter's [flutter.ValueListenable].
///
/// This allows piper's pure Dart state holders to work seamlessly with
/// Flutter's [ValueListenableBuilder] and other Flutter widgets.
class FlutterListenableAdapter<T> implements flutter.ValueListenable<T> {
  final piper.ValueListenable<T> _source;

  FlutterListenableAdapter(this._source);

  @override
  T get value => _source.value;

  @override
  void addListener(flutter.VoidCallback listener) {
    _source.addListener(listener);
  }

  @override
  void removeListener(flutter.VoidCallback listener) {
    _source.removeListener(listener);
  }
}

/// Extension to easily adapt piper listenables to Flutter listenables.
extension PiperToFlutterListenable<T> on piper.ValueListenable<T> {
  /// Converts this piper [ValueListenable] to a Flutter [ValueListenable].
  flutter.ValueListenable<T> toFlutter() => FlutterListenableAdapter<T>(this);
}

/// Extension to easily get Flutter-compatible listenable from StateHolder.
extension StateHolderFlutterListenable<T> on piper.StateHolder<T> {
  /// Returns a Flutter-compatible [ValueListenable] for this state holder.
  flutter.ValueListenable<T> get flutterListenable =>
      FlutterListenableAdapter<T>(listenable);
}

/// Extension to easily get Flutter-compatible listenable from AsyncStateHolder.
extension AsyncStateHolderFlutterListenable<T> on piper.AsyncStateHolder<T> {
  /// Returns a Flutter-compatible [ValueListenable] for this async state holder.
  flutter.ValueListenable<piper.AsyncState<T>> get flutterListenable =>
      FlutterListenableAdapter<piper.AsyncState<T>>(listenable);
}
