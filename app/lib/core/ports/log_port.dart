enum LogLevel { debug, info, warning, error }

/// The local log. There is no third-party crash SDK: the user can send the
/// exported text by email.
abstract interface class LogPort {
  void log(LogLevel level, String tag, String message);

  /// The retained log lines as plain text, newest last.
  Future<String> exportText();

  Future<void> clear();
}
