import 'dart:async';
import 'dart:convert';

import 'package:tehillah/core/config/app_config.dart';
import 'package:tehillah/core/models/remote_flags.dart';
import 'package:tehillah/core/ports/flags_port.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/core/ports/storage_port.dart';
import 'package:tehillah/platform/http_fetch.dart';

typedef TextFetcher = Future<String> Function(Uri uri);

/// Reads `flags.json` with a short timeout. A good answer is cached; when the
/// site cannot be reached the last good answer is used, and with none the
/// built-in defaults. Text that is not a JSON object (for example a hotel
/// Wi-Fi login page) is ignored and never overwrites the cache.
final class FlagsService implements FlagsPort {
  FlagsService(this._storage, {TextFetcher? fetcher, Uri? uri, LogPort? log})
      : _fetch = fetcher ?? _defaultFetch,
        _uri = uri ?? Uri.parse(AppConfig.flagsUrl),
        _log = log;

  static const String cacheKey = 'flags.cache.v1';

  static Future<String> _defaultFetch(Uri uri) =>
      fetchText(uri, timeout: const Duration(seconds: 6), maxBytes: 16 * 1024);

  final StoragePort _storage;
  final TextFetcher _fetch;
  final Uri _uri;
  final LogPort? _log;

  @override
  Future<RemoteFlags> load() async {
    try {
      final String text = await _fetch(_uri);
      if (jsonDecode(text) is Map<String, Object?>) {
        try {
          await _storage.setString(cacheKey, text);
        } on Object catch (error) {
          _log?.log(LogLevel.warning, 'flags', 'could not cache flags: $error');
        }
        return RemoteFlags.decode(text);
      }
      _log?.log(LogLevel.warning, 'flags', 'flags answer was not a JSON object');
    } on Object catch (error) {
      _log?.log(LogLevel.info, 'flags', 'flags not fetched: $error');
    }
    try {
      return RemoteFlags.decode(await _storage.getString(cacheKey));
    } on Object {
      return RemoteFlags.defaults;
    }
  }
}
