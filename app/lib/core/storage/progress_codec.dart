import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/storage/migrations.dart';

/// A decoded save file.
final class DecodedProgress {
  const DecodedProgress({
    required this.progress,
    required this.readOnly,
    required this.migratedFrom,
  });

  final Progress progress;

  /// True when a newer app wrote the file: it may be read but never replaced.
  final bool readOnly;

  /// The stored version if a migration ran, otherwise null.
  final int? migratedFrom;
}

/// Reads and writes the progress file: a small envelope holding the payload as
/// a string and its SHA-256, so any damage is detected before parsing.
///
/// `{"format":1,"sha256":"<hex>","payload":"<progress json>"}`
final class ProgressCodec {
  ProgressCodec({Migrator? migrator})
      : _migrator = migrator ?? Migrator(currentVersion: Progress.currentSchemaVersion);

  static const int envelopeFormat = 1;

  final Migrator _migrator;

  String encode(Progress progress) {
    final String payload = jsonEncode(progress.toJson());
    return jsonEncode(<String, Object?>{
      'format': envelopeFormat,
      'sha256': sha256.convert(utf8.encode(payload)).toString(),
      'payload': payload,
    });
  }

  /// Throws [FormatException] for anything damaged: not JSON, wrong envelope,
  /// checksum mismatch, or data that fails validation.
  DecodedProgress decode(String raw) {
    final Object? outer;
    try {
      outer = jsonDecode(raw);
    } on FormatException {
      throw const FormatException('the save file is not JSON');
    }
    final Map<String, Object?> envelope = jsonMap(outer, 'save file');
    if (readInt(envelope, 'format', min: 1) != envelopeFormat) {
      throw const FormatException('the save file has an unknown envelope');
    }
    final String payload = readString(envelope, 'payload');
    final String expected = readString(envelope, 'sha256');
    if (sha256.convert(utf8.encode(payload)).toString() != expected) {
      throw const FormatException('the save file failed its checksum');
    }
    final Object? inner;
    try {
      inner = jsonDecode(payload);
    } on FormatException {
      throw const FormatException('the save payload is not JSON');
    }
    final MigrationOutcome outcome = _migrator.upgrade(jsonMap(inner, 'save payload'));
    switch (outcome) {
      case MigrationCurrent(:final Map<String, Object?> data, :final int? migratedFrom):
        return DecodedProgress(
          progress: Progress.fromJson(data),
          readOnly: false,
          migratedFrom: migratedFrom,
        );
      case MigrationNewer(:final Map<String, Object?> data):
        return DecodedProgress(
          progress: Progress.fromJson(data),
          readOnly: true,
          migratedFrom: null,
        );
    }
  }
}
