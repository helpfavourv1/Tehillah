/// One step that rewrites saved data from [from] to [to] (always from + 1).
final class Migration {
  const Migration({required this.from, required this.to, required this.apply})
      : assert(to == from + 1);

  final int from;
  final int to;
  final Map<String, Object?> Function(Map<String, Object?> data) apply;
}

/// What [Migrator.upgrade] did.
sealed class MigrationOutcome {
  const MigrationOutcome();
}

/// The data is at [version] (the current one) and is ready to parse.
final class MigrationCurrent extends MigrationOutcome {
  const MigrationCurrent(this.data, {required this.migratedFrom});

  final Map<String, Object?> data;

  /// The version the data was stored at, or null if nothing was migrated.
  final int? migratedFrom;
}

/// The data was written by a newer app. It must be treated as read-only and
/// never overwritten.
final class MigrationNewer extends MigrationOutcome {
  const MigrationNewer(this.data, this.version);

  final Map<String, Object?> data;
  final int version;
}

/// Runs migrations from a stored version up to [currentVersion].
final class Migrator {
  Migrator({required this.currentVersion, List<Migration> migrations = const <Migration>[]})
      : _migrations = <int, Migration>{for (final Migration m in migrations) m.from: m} {
    for (int v = 1; v < currentVersion; v++) {
      if (!_migrations.containsKey(v)) {
        throw ArgumentError('no migration from version $v');
      }
    }
  }

  final int currentVersion;
  final Map<int, Migration> _migrations;

  /// Reads `schemaVersion` from [data] and brings it to the current version.
  /// Throws [FormatException] if the version is missing, below 1, or a step
  /// fails, so the caller can fall back to the backup.
  MigrationOutcome upgrade(Map<String, Object?> data) {
    final Object? stored = data['schemaVersion'];
    if (stored is! int || stored < 1) {
      throw const FormatException('"schemaVersion" must be a positive integer');
    }
    if (stored > currentVersion) {
      return MigrationNewer(data, stored);
    }
    Map<String, Object?> current = data;
    int version = stored;
    while (version < currentVersion) {
      final Migration step = _migrations[version]!;
      final Map<String, Object?> next = step.apply(current);
      current = <String, Object?>{...next, 'schemaVersion': step.to};
      version = step.to;
    }
    return MigrationCurrent(current, migratedFrom: stored == currentVersion ? null : stored);
  }
}
