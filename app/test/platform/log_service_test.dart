import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/platform/log_service.dart';

void main() {
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('tehillah_log_'));
  tearDown(() => dir.deleteSync(recursive: true));

  LogService make({int maxFileBytes = 64 * 1024}) => LogService(
        Directory('${dir.path}/logs'),
        maxFileBytes: maxFileBytes,
        clock: () => DateTime.utc(2026, 11, 21, 12),
      );

  test('writes timestamped lines in order', () async {
    final LogService log = make();
    log.log(LogLevel.info, 'a', 'first');
    log.log(LogLevel.error, 'b', 'second');
    expect(await log.exportText(), '2026-11-21T12:00:00.000Z INFO a first\n'
        '2026-11-21T12:00:00.000Z ERROR b second');
  });

  test('newlines in a message cannot forge extra lines', () async {
    final LogService log = make();
    log.log(LogLevel.info, 'a', 'one\nINFO fake line\r\nthree');
    expect((await log.exportText()).split('\n').length, 1);
  });

  test('very long messages are cut', () async {
    final LogService log = make();
    log.log(LogLevel.info, 'a', 'x' * 5000);
    expect((await log.exportText()).length, lessThan(600));
  });

  test('rotates when the file is full and keeps both files', () async {
    final LogService log = make(maxFileBytes: 200);
    for (int i = 0; i < 12; i++) {
      log.log(LogLevel.info, 't', 'line number $i');
    }
    final String text = await log.exportText();
    expect(File('${dir.path}/logs/log.1.txt').existsSync(), isTrue);
    expect(text, contains('line number 11'));
    expect(text, contains('line number 5'));
  });

  test('export keeps only the newest text, starting on a whole line', () async {
    final LogService log = make();
    for (int i = 0; i < 100; i++) {
      log.log(LogLevel.info, 't', 'entry $i');
    }
    final String text = await log.exportText(maxChars: 300);
    expect(text.length, lessThanOrEqualTo(300));
    expect(text, contains('entry 99'));
    expect(text.startsWith('2026'), isTrue);
  });

  test('clear removes everything', () async {
    final LogService log = make();
    log.log(LogLevel.info, 't', 'x');
    await log.clear();
    expect(await log.exportText(), isEmpty);
  });

  test('a disk that cannot be written still keeps recent lines for export', () async {
    File('${dir.path}/blocked').writeAsStringSync('x');
    final LogService log = LogService(Directory('${dir.path}/blocked'));
    log.log(LogLevel.warning, 't', 'still here');
    expect(await log.exportText(), contains('still here'));
  });
}
