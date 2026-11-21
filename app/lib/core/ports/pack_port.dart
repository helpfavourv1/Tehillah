import 'package:tehillah/core/models/bible_pack.dart';
import 'package:tehillah/core/models/pack_manifest.dart';

/// Bytes received so far out of [total] (0 when the size is not known).
final class PackProgress {
  const PackProgress(this.received, this.total);

  final int received;
  final int total;

  double get fraction => total <= 0 ? 0 : (received / total).clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      other is PackProgress && other.received == received && other.total == total;

  @override
  int get hashCode => Object.hash(received, total);
}

/// Full-Bible packs: download, check, install, read and delete.
abstract interface class PackPort {
  /// Throws an `AppError` if the manifest cannot be fetched.
  Future<PackManifest> fetchManifest();

  Future<Set<String>> installedLanguages();

  /// Downloads, verifies the SHA-256, unpacks and installs the pack atomically.
  /// The stream ends when the pack is installed and errors with an `AppError`
  /// (a hash mismatch discards the file).
  Stream<PackProgress> download(PackManifestEntry entry);

  /// The installed pack for a language, or null if it is not installed.
  Future<BiblePack?> load(String language);

  /// The notice text stored beside an installed pack.
  Future<String?> readNotice(String language);

  Future<void> delete(String language);
}
