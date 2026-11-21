import 'package:tehillah/core/ports/consent_port.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/core/ports/storage_port.dart';

/// Keeps the consent decision the app acts on.
///
/// The rule: a refresh that completes is a real answer and is honored, whether
/// it allows ads or not (a decline, a withdrawal or no answer yet all disable
/// requests when the platform says so). A refresh that fails, for example
/// offline, is not an answer and never replaces the last saved state, so saved
/// consent that allows ads keeps allowing them.
final class ConsentTracker {
  ConsentTracker(this._port, this._storage, this._log);

  static const String storageKey = 'consent.snapshot.v1';

  final ConsentPort _port;
  final StoragePort _storage;
  final LogPort _log;

  Future<ConsentSnapshot> _saved() async {
    try {
      return ConsentSnapshot.decode(await _storage.getString(storageKey));
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'consent', 'saved state unreadable: $error');
      return ConsentSnapshot.unknown;
    }
  }

  Future<void> _save(ConsentSnapshot snapshot) async {
    try {
      await _storage.setString(storageKey, snapshot.encode());
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'consent', 'could not save state: $error');
    }
  }

  /// Run on every launch before anything else about ads.
  Future<ConsentSnapshot> refresh() async {
    try {
      final ConsentSnapshot fresh = await _port.refresh();
      await _save(fresh);
      return fresh;
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'consent', 'refresh failed, keeping saved state: $error');
      return _fallback();
    }
  }

  /// Opens the privacy options form and applies the new state at once.
  Future<ConsentSnapshot> openPrivacyOptions() async {
    try {
      final ConsentSnapshot updated = await _port.showPrivacyOptions();
      await _save(updated);
      return updated;
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'consent', 'privacy options failed: $error');
      return _fallback();
    }
  }

  Future<ConsentSnapshot> _fallback() async {
    final ConsentSnapshot saved = await _saved();
    if (saved.status != ConsentStatus.unknown) {
      return saved;
    }
    try {
      return await _port.current();
    } on Object {
      return ConsentSnapshot.unknown;
    }
  }
}
