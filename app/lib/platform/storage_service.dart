import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/core/ports/storage_port.dart';

/// Small key-value storage behind the real plugin, so tests can swap it.
abstract interface class KeyValueBackend {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);
}

final class SharedPreferencesBackend implements KeyValueBackend {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  @override
  Future<String?> getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// Real persistence. Files are written atomically: the text goes to a
/// temporary file, which is renamed over the real one, and only then does the
/// previous copy replace the backup. A crash at any moment leaves a whole file.
///
/// When the disk refuses a write, the text is kept in memory for the rest of
/// the session (reads return it) and the error is rethrown so the caller can
/// show its warning banner.
final class StorageService implements StoragePort {
  StorageService(this.root, {KeyValueBackend? keyValues, LogPort? log})
      : _keyValues = keyValues ?? SharedPreferencesBackend(),
        _log = log;

  /// Opens storage in the app's private support directory.
  static Future<StorageService> open({LogPort? log}) async {
    final Directory base = await getApplicationSupportDirectory();
    return StorageService(Directory('${base.path}/tehillah'), log: log);
  }

  static final RegExp _validName = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$');

  final Directory root;
  final KeyValueBackend _keyValues;
  final LogPort? _log;
  final Map<String, String> _memoryFiles = <String, String>{};
  final Map<String, String> _memoryValues = <String, String>{};

  File _file(String name) => File('${root.path}/$name');

  void _check(String name) {
    if (!_validName.hasMatch(name) || name.endsWith('.tmp') || name.endsWith('.bak')) {
      throw ArgumentError.value(name, 'name', 'not a valid file name');
    }
  }

  Future<String?> _readText(File file) async {
    if (!await file.exists()) {
      return null;
    }
    // Damaged bytes decode to replacement characters, so the codec's checksum
    // fails and recovery runs, instead of this layer throwing.
    return utf8.decode(await file.readAsBytes(), allowMalformed: true);
  }

  @override
  Future<String?> readFile(String name) async {
    _check(name);
    final String? kept = _memoryFiles[name];
    if (kept != null) {
      return kept;
    }
    return _readText(_file(name));
  }

  @override
  Future<String?> readBackup(String name) async {
    _check(name);
    return _readText(_file('$name.bak'));
  }

  @override
  Future<void> writeFile(String name, String contents) async {
    _check(name);
    try {
      await root.create(recursive: true);
      final File main = _file(name);
      String? previous;
      try {
        previous = await _readText(main);
      } on FileSystemException {
        previous = null;
      }
      final File temp = _file('$name.tmp');
      await temp.writeAsString(contents, flush: true);
      await temp.rename(main.path);
      _memoryFiles.remove(name);
      if (previous != null) {
        try {
          final File backupTemp = _file('$name.bak.tmp');
          await backupTemp.writeAsString(previous, flush: true);
          await backupTemp.rename(_file('$name.bak').path);
        } on FileSystemException catch (error) {
          _log?.log(LogLevel.warning, 'storage', 'backup of $name failed: ${error.message}');
        }
      }
    } on FileSystemException catch (error) {
      _memoryFiles[name] = contents;
      _log?.log(LogLevel.error, 'storage', 'write of $name failed: ${error.message}');
      rethrow;
    }
  }

  @override
  Future<void> removeFile(String name) async {
    _check(name);
    _memoryFiles.remove(name);
    for (final String suffix in <String>['', '.bak', '.tmp', '.bak.tmp']) {
      try {
        final File file = _file('$name$suffix');
        if (await file.exists()) {
          await file.delete();
        }
      } on FileSystemException catch (error) {
        _log?.log(LogLevel.warning, 'storage', 'could not delete $name$suffix: ${error.message}');
      }
    }
  }

  @override
  Future<String?> getString(String key) async {
    final String? kept = _memoryValues[key];
    if (kept != null) {
      return kept;
    }
    return _keyValues.getString(key);
  }

  @override
  Future<void> setString(String key, String value) async {
    try {
      await _keyValues.setString(key, value);
      _memoryValues.remove(key);
    } on Object catch (error) {
      _memoryValues[key] = value;
      _log?.log(LogLevel.error, 'storage', 'could not save $key: $error');
      rethrow;
    }
  }

  @override
  Future<void> removeKey(String key) async {
    _memoryValues.remove(key);
    await _keyValues.remove(key);
  }
}
