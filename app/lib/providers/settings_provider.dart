import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tehillah/core/models/settings_model.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/core/ports/storage_port.dart';
import 'package:tehillah/core/storage/settings_codec.dart';
import 'package:tehillah/providers/safe_notifier.dart';

/// Owns [SettingsModel] and is the only writer of the settings key. Theme and
/// locale providers read from here, so there is one source of truth.
///
/// A change is applied in memory at once and written afterwards. If the write
/// fails the new value stays in effect for this session and [saveFailed] turns
/// true; the next change writes again, and a success clears it.
final class SettingsProvider extends SafeNotifier<SettingsModel> {
  SettingsProvider(this._storage, this._log) : super(const SettingsModel());

  final StoragePort _storage;
  final LogPort _log;
  final SafeNotifier<bool> _saveFailed = SafeNotifier<bool>(false);

  bool _loaded = false;
  bool _writing = false;
  bool _dirty = false;
  Completer<void>? _idle;

  /// True after a failed write, until a later write succeeds.
  ValueListenable<bool> get saveFailed => _saveFailed;

  bool get isLoaded => _loaded;

  /// Reads the saved settings. Anything unreadable gives the defaults.
  Future<void> load() async {
    String? raw;
    try {
      raw = await _storage.getString(SettingsCodec.key);
    } on Object catch (error) {
      _log.log(LogLevel.error, 'settings', 'read failed: $error');
    }
    _loaded = true;
    value = SettingsCodec.decode(raw);
  }

  /// Applies [change] to the current settings and saves the result.
  void update(SettingsModel Function(SettingsModel current) change) {
    if (!_loaded) {
      _log.log(LogLevel.warning, 'settings', 'update before load ignored');
      return;
    }
    final SettingsModel next = change(value);
    if (next == value) {
      return;
    }
    value = next;
    _dirty = true;
    unawaited(_drain());
  }

  /// Completes when every change made so far has been written (or has failed).
  Future<void> flush() => _idle?.future ?? Future<void>.value();

  Future<void> _drain() async {
    if (_writing) {
      return;
    }
    _writing = true;
    final Completer<void> idle = Completer<void>();
    _idle = idle;
    try {
      while (_dirty) {
        _dirty = false;
        try {
          await _storage.setString(SettingsCodec.key, SettingsCodec.encode(value));
          _saveFailed.value = false;
        } on Object catch (error) {
          _log.log(LogLevel.error, 'settings', 'write failed: $error');
          _saveFailed.value = true;
        }
      }
    } finally {
      _writing = false;
      _idle = null;
      idle.complete();
    }
  }

  @override
  void dispose() {
    if (isDisposed) {
      return;
    }
    _saveFailed.dispose();
    super.dispose();
  }
}
