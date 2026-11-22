import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/errors/app_error.dart';
import 'package:tehillah/core/models/bible_pack.dart';
import 'package:tehillah/core/models/pack_manifest.dart';
import 'package:tehillah/core/ports/pack_port.dart';
import 'package:tehillah/platform/pack_service.dart';

/// A small web server that serves byte ranges and can cut one transfer short.
final class _Server {
  late final HttpServer http;
  final Map<String, List<int>> files = <String, List<int>>{};
  final List<String?> ranges = <String?>[];
  int requests = 0;
  int cutFirstAfter = -1;

  Future<void> start() async {
    http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    http.listen(_handle);
  }

  Uri get base => Uri.parse('http://127.0.0.1:${http.port}');

  Future<void> _handle(HttpRequest request) async {
    requests++;
    final List<int>? body = files[request.uri.path];
    if (body == null) {
      request.response.statusCode = 404;
      await request.response.close();
      return;
    }
    final String? range = request.headers.value(HttpHeaders.rangeHeader);
    ranges.add(range);
    int start = 0;
    if (range != null && range.startsWith('bytes=')) {
      start = int.parse(range.substring(6).replaceAll('-', ''));
      request.response.statusCode = 206;
    }
    final List<int> slice = body.sublist(start);
    request.response.contentLength = slice.length;
    if (cutFirstAfter >= 0) {
      final int cut = cutFirstAfter;
      cutFirstAfter = -1;
      request.response.add(slice.sublist(0, cut));
      await request.response.flush();
      final Socket socket = await request.response.detachSocket();
      socket.destroy();
      return;
    }
    request.response.add(slice);
    await request.response.close();
  }

  Future<void> stop() => http.close(force: true);
}

List<int> _gzipPack() {
  final Map<String, Object?> pack = <String, Object?>{
    'schemaVersion': 1,
    'language': 'en',
    'translationId': 'BSB',
    'source': 'test source',
    'license': 'test license',
    'books': <String, Object?>{
      'Gen': <List<String>>[
        <String>[for (int i = 1; i <= 300; i++) 'Verse $i of the first chapter, with its own words ${i * 7919 % 10007}.'],
      ],
    },
  };
  return gzip.encode(utf8.encode(jsonEncode(pack)));
}

void main() {
  late Directory dir;
  late _Server server;
  late List<int> packBytes;
  late PackManifestEntry entry;
  late PackService service;

  PackManifestEntry entryWith({String? sha, int? bytes}) => PackManifestEntry(
        language: 'en',
        translationId: 'BSB',
        version: 1,
        url: '/p/en-1.json.gz',
        bytes: bytes ?? packBytes.length,
        sha256: sha ?? sha256.convert(packBytes).toString(),
        noticePath: '/p/notices/en.txt',
      );

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('tehillah_packs_');
    server = _Server();
    await server.start();
    packBytes = _gzipPack();
    entry = entryWith();
    server.files['/p/en-1.json.gz'] = packBytes;
    server.files['/p/notices/en.txt'] = utf8.encode('Berean Standard Bible - public domain');
    server.files['/p/manifest.json'] = utf8.encode(jsonEncode(<String, Object?>{
      'schemaVersion': 1,
      'packs': <Object?>[
        <String, Object?>{
          'language': 'en',
          'translationId': 'BSB',
          'version': 1,
          'url': '/p/en-1.json.gz',
          'bytes': packBytes.length,
          'sha256': sha256.convert(packBytes).toString(),
          'noticePath': '/p/notices/en.txt',
        },
      ],
    }));
    service = PackService(
      Directory('${dir.path}/packs'),
      manifestUri: server.base.resolve('/p/manifest.json'),
      timeout: const Duration(seconds: 5),
    );
  });

  tearDown(() async {
    await server.stop();
    dir.deleteSync(recursive: true);
  });

  test('the manifest is fetched and parsed', () async {
    final PackManifest manifest = await service.fetchManifest();
    expect(manifest.entries.single.language, 'en');
  });

  test('a missing manifest is a system error after one retry', () async {
    server.files.remove('/p/manifest.json');
    await expectLater(service.fetchManifest(), throwsA(isA<SystemRecoverableError>()));
    expect(server.requests, 2);
  });

  test('a manifest that is not valid is reported as damaged', () async {
    server.files['/p/manifest.json'] = utf8.encode('<html>login</html>');
    await expectLater(
      service.fetchManifest(),
      throwsA(isA<SystemRecoverableError>().having((SystemRecoverableError e) => e.code, 'code', 'pack.manifest_invalid')),
    );
  });

  test('a download installs, reports progress ending at the full size, and can be loaded', () async {
    final List<PackProgress> progress = await service.download(entry).toList();
    expect(progress.last, PackProgress(packBytes.length, packBytes.length));
    expect(progress.map((PackProgress p) => p.received), isNot(contains(-1)));
    expect(await service.installedLanguages(), <String>{'en'});
    final BiblePack? pack = await service.load('en');
    expect(pack, isNotNull);
    expect(pack!.chapter('Gen', 1)!.length, 300);
    expect(await service.readNotice('en'), contains('public domain'));
    expect(File('${dir.path}/packs/en.part').existsSync(), isFalse);
  });

  test('a download that fails its SHA-256 check is discarded and nothing is installed', () async {
    final PackManifestEntry bad = entryWith(sha: '0' * 64);
    await expectLater(
      service.download(bad).toList(),
      throwsA(isA<SystemRecoverableError>().having((SystemRecoverableError e) => e.code, 'code', 'pack.hash_mismatch')),
    );
    expect(await service.installedLanguages(), isEmpty);
    expect(File('${dir.path}/packs/en.part').existsSync(), isFalse);
    expect(await service.load('en'), isNull);
  });

  test('an interrupted transfer resumes with a Range request and installs', () async {
    server.cutFirstAfter = 200;
    final List<PackProgress> progress = await service.download(entry).toList();
    expect(progress.last.received, packBytes.length);
    expect(server.ranges.first, isNull);
    expect(server.ranges.last, startsWith('bytes='));
    expect(await service.installedLanguages(), <String>{'en'});
    expect((await service.load('en'))!.chapter('Gen', 1)!.length, 300);
  });

  test('a file that is in the wrong shape is refused even when its hash matches', () async {
    final List<int> junk = gzip.encode(utf8.encode('{"hello":1}'));
    server.files['/p/en-1.json.gz'] = junk;
    final PackManifestEntry bad = entryWith(sha: sha256.convert(junk).toString(), bytes: junk.length);
    await expectLater(
      service.download(bad).toList(),
      throwsA(isA<SystemRecoverableError>().having((SystemRecoverableError e) => e.code, 'code', 'pack.unreadable')),
    );
    expect(await service.installedLanguages(), isEmpty);
  });

  test('a 404 is a system error', () async {
    server.files.remove('/p/en-1.json.gz');
    await expectLater(service.download(entry).toList(), throwsA(isA<SystemRecoverableError>()));
  });

  test('no connection is a user-recoverable error', () async {
    final Uri closed = server.base.resolve('/p/manifest.json');
    await server.stop();
    final PackService offline = PackService(
      Directory('${dir.path}/offline'),
      manifestUri: closed,
      timeout: const Duration(seconds: 2),
    );
    await expectLater(offline.download(entry).toList(), throwsA(isA<UserRecoverableError>()));
    await expectLater(offline.fetchManifest(), throwsA(isA<UserRecoverableError>()));
    server = _Server();
    await server.start();
  });

  test('a language with a pack file but no meta file is not installed', () async {
    await service.download(entry).toList();
    File('${dir.path}/packs/en.meta.json').deleteSync();
    expect(await service.installedLanguages(), isEmpty);
    expect(await service.load('en'), isNull);
  });

  test('delete removes every file of a language', () async {
    await service.download(entry).toList();
    await service.delete('en');
    expect(await service.installedLanguages(), isEmpty);
    expect(await service.readNotice('en'), isNull);
    expect(Directory('${dir.path}/packs').listSync(), isEmpty);
    await service.delete('en');
  });

  test('a damaged installed pack loads as null instead of throwing', () async {
    await service.download(entry).toList();
    File('${dir.path}/packs/en.json.gz').writeAsBytesSync(<int>[1, 2, 3]);
    expect(await service.load('en'), isNull);
  });
}
