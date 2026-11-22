import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/core/ports/storage_port.dart';

/// In-memory storage that mimics the adapter: a write keeps the previous copy
/// as the backup. Failures can be switched on per operation.
class FakeStorage implements StoragePort {
  final Map<String, String> files = <String, String>{};
  final Map<String, String> backups = <String, String>{};
  final Map<String, String> values = <String, String>{};

  bool failReads = false;
  bool failWrites = false;

  @override
  Future<String?> readFile(String name) async {
    if (failReads) {
      throw StateError('read failed');
    }
    return files[name];
  }

  @override
  Future<String?> readBackup(String name) async {
    if (failReads) {
      throw StateError('read failed');
    }
    return backups[name];
  }

  @override
  Future<void> writeFile(String name, String contents) async {
    if (failWrites) {
      throw StateError('write failed');
    }
    final String? previous = files[name];
    if (previous != null) {
      backups[name] = previous;
    }
    files[name] = contents;
  }

  @override
  Future<void> removeFile(String name) async {
    files.remove(name);
    backups.remove(name);
  }

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async => values[key] = value;

  @override
  Future<void> removeKey(String key) async => values.remove(key);
}

/// A log that keeps its lines in a list.
final class FakeLog implements LogPort {
  final List<String> lines = <String>[];

  @override
  void log(LogLevel level, String tag, String message) =>
      lines.add('${level.name} $tag $message');

  @override
  Future<String> exportText() async => lines.join('\n');

  @override
  Future<void> clear() async => lines.clear();
}
