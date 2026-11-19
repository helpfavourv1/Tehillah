import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/language_codes.dart';

/// One downloadable Bible in `manifest.json`.
final class PackManifestEntry {
  const PackManifestEntry({
    required this.language,
    required this.translationId,
    required this.version,
    required this.url,
    required this.bytes,
    required this.sha256,
    required this.noticePath,
  });

  factory PackManifestEntry.fromJson(Map<String, Object?> json) {
    final String language = readString(json, 'language');
    if (!LanguageCodes.isSupported(language)) {
      throw FormatException('unsupported language "$language"');
    }
    final String sha = readString(json, 'sha256');
    if (!_hex64.hasMatch(sha)) {
      throw const FormatException('"sha256" must be 64 lowercase hex digits');
    }
    return PackManifestEntry(
      language: language,
      translationId: readString(json, 'translationId'),
      version: readInt(json, 'version', min: 1),
      url: readString(json, 'url'),
      bytes: readInt(json, 'bytes', min: 1),
      sha256: sha,
      noticePath: readString(json, 'noticePath'),
    );
  }

  static final RegExp _hex64 = RegExp(r'^[0-9a-f]{64}$');

  final String language;
  final String translationId;

  /// Increases whenever the pack file changes.
  final int version;

  /// Path relative to the manifest, or an absolute https URL.
  final String url;

  /// Size of the downloaded (compressed) file.
  final int bytes;

  /// SHA-256 of the downloaded file, 64 lowercase hex digits.
  final String sha256;

  /// Path of the notice text shipped beside the pack.
  final String noticePath;

  Map<String, Object?> toJson() => <String, Object?>{
        'language': language,
        'translationId': translationId,
        'version': version,
        'url': url,
        'bytes': bytes,
        'sha256': sha256,
        'noticePath': noticePath,
      };

  @override
  bool operator ==(Object other) =>
      other is PackManifestEntry &&
      other.language == language &&
      other.translationId == translationId &&
      other.version == version &&
      other.url == url &&
      other.bytes == bytes &&
      other.sha256 == sha256 &&
      other.noticePath == noticePath;

  @override
  int get hashCode =>
      Object.hash(language, translationId, version, url, bytes, sha256, noticePath);
}

/// The list of every Bible the app can download.
final class PackManifest {
  PackManifest({required this.schemaVersion, required List<PackManifestEntry> entries})
      : entries = List<PackManifestEntry>.unmodifiable(entries);

  factory PackManifest.fromJson(Map<String, Object?> json) {
    final List<PackManifestEntry> entries = <PackManifestEntry>[
      for (final Object? e in jsonList(json['packs'], 'packs'))
        PackManifestEntry.fromJson(jsonMap(e, 'pack')),
    ];
    final Set<String> seen = <String>{};
    for (final PackManifestEntry e in entries) {
      if (!seen.add(e.language)) {
        throw FormatException('language "${e.language}" appears twice');
      }
    }
    return PackManifest(
      schemaVersion: readInt(json, 'schemaVersion', min: 1),
      entries: entries,
    );
  }

  final int schemaVersion;
  final List<PackManifestEntry> entries;

  PackManifestEntry? forLanguage(String language) {
    for (final PackManifestEntry e in entries) {
      if (e.language == language) {
        return e;
      }
    }
    return null;
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'packs': <Object?>[for (final PackManifestEntry e in entries) e.toJson()],
      };

  @override
  bool operator ==(Object other) =>
      other is PackManifest &&
      other.schemaVersion == schemaVersion &&
      listsEqual(other.entries, entries);

  @override
  int get hashCode => Object.hash(schemaVersion, Object.hashAll(entries));
}
