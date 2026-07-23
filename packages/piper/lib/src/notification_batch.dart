import 'dart:collection';

import 'package:meta/meta.dart';

/// Coordinates synchronous notifications so derived state can settle first.
@internal
final class PiperNotificationBatch {
  PiperNotificationBatch._();

  static final Queue<void Function()> _pending = Queue();
  static int _notificationDepth = 0;
  static bool _isFlushing = false;

  static void notify(Iterable<void Function()> listeners) {
    _notificationDepth++;
    try {
      for (final listener in List<void Function()>.of(listeners)) {
        listener();
      }
    } finally {
      _notificationDepth--;
      _flush();
    }
  }

  static void schedule(void Function() notification) {
    _pending.addLast(notification);
    _flush();
  }

  static void _flush() {
    if (_notificationDepth > 0 || _isFlushing) return;
    _isFlushing = true;
    Object? firstError;
    StackTrace? firstStackTrace;
    try {
      while (_pending.isNotEmpty) {
        try {
          _pending.removeFirst()();
        } catch (error, stackTrace) {
          // Drain the queue before rethrowing so no computed stays pending.
          firstError ??= error;
          firstStackTrace ??= stackTrace;
        }
      }
    } finally {
      _isFlushing = false;
    }
    if (firstError != null) {
      Error.throwWithStackTrace(firstError, firstStackTrace!);
    }
  }
}
