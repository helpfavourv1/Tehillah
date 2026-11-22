import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:tehillah/core/config/app_config.dart';
import 'package:tehillah/core/errors/app_error.dart';
import 'package:tehillah/core/models/bible_pack.dart';
import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/pack_manifest.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/core/ports/pack_port.dart';
import 'package:tehillah/platform/http_fetch.dart';

BiblePack _decodePack(Uint8List gzipped) => BiblePack.fromJson(
      jsonMap(jsonDecode(utf8.decode(gzip.decode(gzipped))), 'pack'),
    );

/// Full-Bible packs on disk.
///
/// A download goes to `{lang}.part`, resumes with a Range request after an
/// interruption (one automatic retry), and is checked against the manifest's
/// SHA-256 and parsed before it is installed by a rename. A pack that fails
/// either check is discarded. Installed files per language:
/// `{lang}.json.gz` (the verified download), `{lang}.notice.txt` and
/// `{lang}.meta.json`; the meta file is written last, so a language counts as
/// installed only when all of it is in place.
final class PackService implements PackPort {
  PackService(
    this.root, {
    Uri? manifestUri,
    HttpClientFactory? clientFactory,
    LogPort? log,
    this.timeout = const Duration(seconds: 20),
  })  : manifestUri = manifestUri ?? Uri.parse(AppConfig.manifestUrl),
        _clientFactory = clientFactory ?? defaultHttpClient,
        _log = log;

  final Directory root;
  final Uri manifestUri;
  final Duration timeout;
  final HttpClientFactory _clientFactory;
  final LogPort? _log;

  File _file(String name) => File('${root.path}/$name');

  @override
  Future<PackManifest> fetchManifest() async {
    Object? last;
    for (int attempt = 0; attempt < 2; attempt++) {
      try {
        final String text = await fetchText(manifestUri, timeout: timeout, clientFactory: _clientFactory);
        return PackManifest.fromJson(jsonMap(jsonDecode(text), 'manifest'));
      } on FormatException catch (error) {
        throw SystemRecoverableError('pack.manifest_invalid', 'the pack list is damaged', cause: error);
      } on Object catch (error) {
        last = error;
      }
    }
    throw classifyNetworkError(last!, 'pack.manifest');
  }

  @override
  Future<Set<String>> installedLanguages() async {
    if (!await root.exists()) {
      return <String>{};
    }
    final Set<String> found = <String>{};
    await for (final FileSystemEntity entity in root.list()) {
      final String name = entity.uri.pathSegments.last;
      if (name.endsWith('.meta.json')) {
        final String language = name.substring(0, name.length - '.meta.json'.length);
        if (await _file('$language.json.gz').exists()) {
          found.add(language);
        }
      }
    }
    return found;
  }

  @override
  Stream<PackProgress> download(PackManifestEntry entry) async* {
    final Uri url = manifestUri.resolve(entry.url);
    final File part = _file('${entry.language}.part');
    try {
      await root.create(recursive: true);
      int attempt = 0;
      while (true) {
        try {
          yield* _fetchInto(url, part, entry.bytes);
          break;
        } on Object catch (error) {
          final bool transient = error is SocketException ||
              error is TimeoutException ||
              error is HttpException ||
              error is HandshakeException;
          if (!transient || attempt >= 1) {
            rethrow;
          }
          attempt++;
          _log?.log(LogLevel.info, 'packs', 'download interrupted, resuming: $error');
        }
      }
      final String digest = (await sha256.bind(part.openRead()).first).toString();
      if (digest != entry.sha256) {
        await _discard(part);
        throw const SystemRecoverableError('pack.hash_mismatch', 'the downloaded Bible failed its check');
      }
      try {
        await compute(_decodePack, await part.readAsBytes());
      } on Object catch (error) {
        await _discard(part);
        throw SystemRecoverableError('pack.unreadable', 'the downloaded Bible could not be read', cause: error);
      }
      await _install(entry, part);
      yield PackProgress(entry.bytes, entry.bytes);
    } on FileSystemException catch (error) {
      throw SystemRecoverableError('pack.disk', 'could not store the Bible: ${error.message}', cause: error);
    } on AppError {
      rethrow;
    } on Object catch (error) {
      throw classifyNetworkError(error, 'pack.download');
    }
  }

  Future<void> _discard(File part) async {
    try {
      if (await part.exists()) {
        await part.delete();
      }
    } on FileSystemException {
      // Nothing more can be done; the next attempt overwrites it.
    }
  }

  Stream<PackProgress> _fetchInto(Uri url, File part, int expected) async* {
    int have = await part.exists() ? await part.length() : 0;
    if (have > expected) {
      await part.delete();
      have = 0;
    }
    if (have == expected && expected > 0) {
      yield PackProgress(have, expected);
      return;
    }
    final HttpClient client = _clientFactory();
    client.autoUncompress = false;
    try {
      final HttpClientRequest request = await client.getUrl(url).timeout(timeout);
      request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
      if (have > 0) {
        request.headers.set(HttpHeaders.rangeHeader, 'bytes=$have-');
      }
      final HttpClientResponse response = await request.close().timeout(timeout);
      if (response.statusCode == 416) {
        await response.drain<void>();
        await part.delete();
        throw HttpException('range not satisfiable', uri: url);
      }
      if (response.statusCode != 200 && response.statusCode != 206) {
        await response.drain<void>();
        throw HttpException('HTTP ${response.statusCode}', uri: url);
      }
      final bool append = response.statusCode == 206 && have > 0;
      int received = append ? have : 0;
      final IOSink sink = part.openWrite(mode: append ? FileMode.append : FileMode.write);
      int reported = -1;
      try {
        await for (final List<int> chunk in response.timeout(timeout)) {
          sink.add(chunk);
          received += chunk.length;
          if (received - reported >= 32 * 1024 || received >= expected) {
            reported = received;
            yield PackProgress(received, expected);
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _writeText(String name, String text) async {
    final File temp = _file('$name.tmp');
    await temp.writeAsString(text, flush: true);
    await temp.rename(_file(name).path);
  }

  Future<void> _install(PackManifestEntry entry, File part) async {
    final String language = entry.language;
    await part.rename(_file('$language.json.gz').path);
    try {
      final String notice = await fetchText(
        manifestUri.resolve(entry.noticePath),
        timeout: timeout,
        clientFactory: _clientFactory,
      );
      await _writeText('$language.notice.txt', notice);
    } on Object catch (error) {
      // The notice is also inside the pack itself, so this is not fatal.
      _log?.log(LogLevel.warning, 'packs', 'notice for $language not stored: $error');
    }
    await _writeText(
      '$language.meta.json',
      jsonEncode(<String, Object?>{
        'language': language,
        'translationId': entry.translationId,
        'version': entry.version,
        'sha256': entry.sha256,
      }),
    );
  }

  @override
  Future<BiblePack?> load(String language) async {
    final File file = _file('$language.json.gz');
    try {
      if (!await file.exists() || !await _file('$language.meta.json').exists()) {
        return null;
      }
      return await compute(_decodePack, await file.readAsBytes());
    } on Object catch (error) {
      _log?.log(LogLevel.error, 'packs', 'installed pack $language unreadable: $error');
      return null;
    }
  }

  @override
  Future<String?> readNotice(String language) async {
    final File file = _file('$language.notice.txt');
    try {
      return await file.exists() ? await file.readAsString() : null;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> delete(String language) async {
    for (final String name in <String>[
      '$language.meta.json',
      '$language.json.gz',
      '$language.notice.txt',
      '$language.part',
      '$language.meta.json.tmp',
      '$language.notice.txt.tmp',
    ]) {
      try {
        final File file = _file(name);
        if (await file.exists()) {
          await file.delete();
        }
      } on FileSystemException catch (error) {
        _log?.log(LogLevel.warning, 'packs', 'could not delete $name: ${error.message}');
      }
    }
  }
}
