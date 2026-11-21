/// Persistence interface. The adapter (p2d) writes files atomically: it writes
/// a temporary file, renames it over the real one, and only then replaces the
/// backup with the previous copy, so a crash leaves either the old or the new
/// file whole.
abstract interface class StoragePort {
  /// The text of a file, or null if it does not exist.
  Future<String?> readFile(String name);

  /// The backup copy of a file, or null if there is none.
  Future<String?> readBackup(String name);

  /// Writes a file atomically and keeps the previous copy as its backup.
  Future<void> writeFile(String name, String contents);

  Future<void> removeFile(String name);

  /// Key-value access, used for small settings.
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<void> removeKey(String key);
}
