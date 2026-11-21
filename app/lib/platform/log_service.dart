import 'dart:async';
import 'dart:io';

import 'package:tehillah/core/ports/log_port.dart';

/// The local log. It keeps two files (`log.txt` and the older `log.1.txt`),
/// each capped in size, plus the last lines in memory in case the disk fails.
/// No third-party crash SDK: [exportText] gives the body of an email the user
/// can send.
final class LogService implements LogPort {
  LogService(this.root, {this.maxFileBytes = 64 * 1024, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static const int _recentLimit = 200;
  static const int _lineLimit = 500;

  final Directory root;
  final int maxFileBytes;
  final DateTime Function() _clock;
  final List<String> _recent = <String>[];
  Future<void> _queue = Future<void>.value();

  File get _current => File('${root.path}/log.txt');
  File get _older => File('${root.path}/log.1.txt');

  @override
  void log(LogLevel level, String tag, String message) {
    String text = message.replaceAll(RegExp(r'[\r\n]+'), ' | ');
    if (text.length > _lineLimit) {
      text = '${text.substring(0, _lineLimit)}...';
    }
    final String line =
        '${_clock().toUtc().toIso8601String()} ${level.name.toUpperCase()} $tag $text';
    _recent.add(line);
    if (_recent.length > _recentLimit) {
      _recent.removeAt(0);
    }
    _queue = _queue.then((_) => _append(line));
  }

  Future<void> _append(String line) async {
    try {
      await root.create(recursive: true);
      if (await _current.exists() && await _current.length() > maxFileBytes) {
        await _current.rename(_older.path);
      }
      await _current.writeAsString('$line\n', mode: FileMode.append, flush: true);
    } on Object {
      // The in-memory copy still holds the line; logging never throws.
    }
  }

  /// Waits until every queued line has been written.
  Future<void> flush() => _queue;

  /// The newest lines, at most [maxChars] characters, oldest first.
  @override
  Future<String> exportText({int maxChars = 12000}) async {
    await flush();
    final StringBuffer all = StringBuffer();
    try {
      if (await _older.exists()) {
        all.write(await _older.readAsString());
      }
      if (await _current.exists()) {
        all.write(await _current.readAsString());
      }
    } on Object {
      all.clear();
    }
    String text = all.toString();
    if (text.isEmpty) {
      text = _recent.map((String l) => '$l\n').join();
    }
    if (text.length > maxChars) {
      text = text.substring(text.length - maxChars);
      final int firstBreak = text.indexOf('\n');
      if (firstBreak >= 0) {
        text = text.substring(firstBreak + 1);
      }
    }
    return text.trimRight();
  }

  @override
  Future<void> clear() async {
    await flush();
    _recent.clear();
    for (final File file in <File>[_current, _older]) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } on FileSystemException {
        // Nothing else to do.
      }
    }
  }
}
