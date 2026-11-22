import 'package:flutter/foundation.dart';

/// A [ValueNotifier] that ignores writes after it is disposed. Providers finish
/// async work (a store write, a billing event) after the screen that owned
/// them may be gone; that must never throw.
class SafeNotifier<T> extends ValueNotifier<T> {
  SafeNotifier(super.value);

  bool _disposed = false;

  bool get isDisposed => _disposed;

  @override
  set value(T newValue) {
    if (_disposed) {
      return;
    }
    super.value = newValue;
  }

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    super.dispose();
  }
}
