import 'package:tehillah/core/errors/app_error.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/core/ports/storage_port.dart';
import 'package:tehillah/core/storage/progress_codec.dart';

enum ProgressLoadStatus {
  /// No file yet: a new player.
  fresh,
  loaded,
  migrated,

  /// The main file was damaged and the backup was used.
  recoveredFromBackup,

  /// Both files were damaged: the player starts clean and gets a one-time notice.
  startedClean,

  /// A newer app wrote the file; this app reads it and never writes.
  newerVersionReadOnly,

  /// The file could not be read at all; nothing is written until a load works.
  storageUnavailable,
}

final class ProgressLoad {
  const ProgressLoad(this.progress, this.status);

  final Progress progress;
  final ProgressLoadStatus status;

  /// Whether the player should be told something went wrong with their data.
  bool get needsNotice =>
      status == ProgressLoadStatus.recoveredFromBackup ||
      status == ProgressLoadStatus.startedClean ||
      status == ProgressLoadStatus.newerVersionReadOnly ||
      status == ProgressLoadStatus.storageUnavailable;
}

sealed class SaveResult {
  const SaveResult();
}

final class SaveOk extends SaveResult {
  const SaveOk();
}

/// Saving is switched off to protect a file this app cannot safely replace.
final class SaveSkippedReadOnly extends SaveResult {
  const SaveSkippedReadOnly();
}

/// The write failed. The app keeps working from memory and shows a warning.
final class SaveFailed extends SaveResult {
  const SaveFailed(this.error);

  final StorageDegradedError error;
}

/// The one place that loads and saves progress: recovery, read-only protection
/// and error classification live here so providers and tests share them.
final class ProgressStore {
  ProgressStore(this._storage, this._log, {ProgressCodec? codec, this.fileName = 'progress.json'})
      : _codec = codec ?? ProgressCodec();

  final StoragePort _storage;
  final LogPort _log;
  final ProgressCodec _codec;
  final String fileName;

  bool _readOnly = false;

  bool get readOnly => _readOnly;

  Future<ProgressLoad> load() async {
    String? primary;
    try {
      primary = await _storage.readFile(fileName);
    } on Object catch (error) {
      _log.log(LogLevel.error, 'progress', 'read failed: $error');
      _readOnly = true;
      return ProgressLoad(Progress.empty(), ProgressLoadStatus.storageUnavailable);
    }
    if (primary == null) {
      String? backup;
      try {
        backup = await _storage.readBackup(fileName);
      } on Object {
        backup = null;
      }
      if (backup == null) {
        _readOnly = false;
        return ProgressLoad(Progress.empty(), ProgressLoadStatus.fresh);
      }
      return _fromBackup(backup, 'main file missing');
    }
    try {
      final DecodedProgress decoded = _codec.decode(primary);
      _readOnly = decoded.readOnly;
      if (decoded.readOnly) {
        _log.log(LogLevel.warning, 'progress', 'file is from a newer app; read-only');
        return ProgressLoad(decoded.progress, ProgressLoadStatus.newerVersionReadOnly);
      }
      return ProgressLoad(
        decoded.progress,
        decoded.migratedFrom == null ? ProgressLoadStatus.loaded : ProgressLoadStatus.migrated,
      );
    } on FormatException catch (error) {
      _log.log(LogLevel.error, 'progress', 'main file damaged: ${error.message}');
      String? backup;
      try {
        backup = await _storage.readBackup(fileName);
      } on Object {
        backup = null;
      }
      if (backup == null) {
        return _startClean();
      }
      return _fromBackup(backup, 'main file damaged');
    }
  }

  Future<ProgressLoad> _fromBackup(String backup, String why) async {
    try {
      final DecodedProgress decoded = _codec.decode(backup);
      _readOnly = decoded.readOnly;
      _log.log(LogLevel.warning, 'progress', 'using backup ($why)');
      return ProgressLoad(
        decoded.progress,
        decoded.readOnly
            ? ProgressLoadStatus.newerVersionReadOnly
            : ProgressLoadStatus.recoveredFromBackup,
      );
    } on FormatException catch (error) {
      _log.log(LogLevel.error, 'progress', 'backup damaged: ${error.message}');
      return _startClean();
    }
  }

  ProgressLoad _startClean() {
    _readOnly = false;
    return ProgressLoad(Progress.empty(), ProgressLoadStatus.startedClean);
  }

  /// Never throws. A failure is returned so the caller can show the banner.
  Future<SaveResult> save(Progress progress) async {
    if (_readOnly) {
      return const SaveSkippedReadOnly();
    }
    try {
      await _storage.writeFile(fileName, _codec.encode(progress));
      return const SaveOk();
    } on Object catch (error) {
      _log.log(LogLevel.error, 'progress', 'write failed: $error');
      return SaveFailed(
        StorageDegradedError('storage.progress_write', 'saving progress failed', cause: error),
      );
    }
  }
}
