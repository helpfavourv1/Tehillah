import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/platform/storage_service.dart';

import '../fakes/fake_storage.dart';

final class _MemoryBackend implements KeyValueBackend {
  final Map<String, String> data = <String, String>{};
  bool failWrites = false;

  @override
  Future<String?> getString(String key) async => data[key];

  @override
  Future<void> setString(String key, String value) async {
    if (failWrites) {
      throw StateError('prefs write failed');
    }
    data[key] = value;
  }

  @override
  Future<void> remove(String key) async => data.remove(key);
}

void main() {
  late Directory dir;
  late _MemoryBackend backend;
  late FakeLog log;
  late StorageService storage;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('tehillah_storage_');
    backend = _MemoryBackend();
    log = FakeLog();
    storage = StorageService(Directory('${dir.path}/data'), keyValues: backend, log: log);
  });

  tearDown(() => dir.deleteSync(recursive: true));

  test('a missing file reads as null', () async {
    expect(await storage.readFile('progress.json'), isNull);
    expect(await storage.readBackup('progress.json'), isNull);
  });

  test('write then read round trips, including non-ASCII text', () async {
    await storage.writeFile('progress.json', 'שלום – 神は愛');
    expect(await storage.readFile('progress.json'), 'שלום – 神は愛');
  });

  test('the first write has no backup', () async {
    await storage.writeFile('progress.json', 'one');
    expect(await storage.readBackup('progress.json'), isNull);
  });

  test('each write keeps the previous copy as the backup', () async {
    await storage.writeFile('progress.json', 'one');
    await storage.writeFile('progress.json', 'two');
    await storage.writeFile('progress.json', 'three');
    expect(await storage.readFile('progress.json'), 'three');
    expect(await storage.readBackup('progress.json'), 'two');
  });

  test('no temporary files are left behind', () async {
    await storage.writeFile('progress.json', 'one');
    await storage.writeFile('progress.json', 'two');
    final List<String> names = Directory('${dir.path}/data')
        .listSync()
        .map((FileSystemEntity e) => e.uri.pathSegments.last)
        .toList()
      ..sort();
    expect(names, <String>['progress.json', 'progress.json.bak']);
  });

  test('damaged bytes read as text that fails a checksum instead of throwing', () async {
    await storage.writeFile('progress.json', 'ok');
    File('${dir.path}/data/progress.json').writeAsBytesSync(<int>[0xFF, 0xFE, 0x41]);
    final String? text = await storage.readFile('progress.json');
    expect(text, isNotNull);
    expect(text, contains('A'));
  });

  test('a failed write keeps the text in memory, rethrows and logs', () async {
    // A plain file where the folder should be makes every write fail.
    File('${dir.path}/blocked').writeAsStringSync('x');
    final StorageService blocked =
        StorageService(Directory('${dir.path}/blocked'), keyValues: backend, log: log);
    await expectLater(blocked.writeFile('progress.json', 'kept'), throwsA(isA<FileSystemException>()));
    expect(await blocked.readFile('progress.json'), 'kept');
    expect(log.lines.any((String l) => l.contains('write of progress.json failed')), isTrue);
  });

  test('removeFile deletes the file and its backup', () async {
    await storage.writeFile('progress.json', 'one');
    await storage.writeFile('progress.json', 'two');
    await storage.removeFile('progress.json');
    expect(await storage.readFile('progress.json'), isNull);
    expect(await storage.readBackup('progress.json'), isNull);
    await storage.removeFile('progress.json');
  });

  test('names that could escape the folder or clash with temp files are rejected', () async {
    for (final String bad in <String>['../x', 'a/b', '', '.hidden', 'x.tmp', 'x.bak', 'a b']) {
      expect(() => storage.writeFile(bad, 'x'), throwsArgumentError, reason: bad);
      expect(() => storage.readFile(bad), throwsArgumentError, reason: bad);
    }
  });

  test('key-value round trip and removal', () async {
    expect(await storage.getString('k'), isNull);
    await storage.setString('k', 'v');
    expect(await storage.getString('k'), 'v');
    await storage.removeKey('k');
    expect(await storage.getString('k'), isNull);
  });

  test('a failed key-value write is rethrown but still readable this session', () async {
    backend.failWrites = true;
    await expectLater(storage.setString('k', 'v'), throwsStateError);
    expect(await storage.getString('k'), 'v');
    backend.failWrites = false;
    await storage.setString('k', 'w');
    expect(await storage.getString('k'), 'w');
  });
}
