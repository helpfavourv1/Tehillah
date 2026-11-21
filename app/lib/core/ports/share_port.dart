abstract interface class SharePort {
  /// Opens the system share sheet. True if the sheet was shown.
  Future<bool> shareText(String text, {String? subject});
}
