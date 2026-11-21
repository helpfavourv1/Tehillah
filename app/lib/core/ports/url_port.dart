abstract interface class UrlPort {
  /// Opens the mail app with a draft. False if no mail app could be opened.
  Future<bool> openMail({required String to, String? subject, String? body});

  /// Opens a web link outside the app. False if it could not be opened.
  Future<bool> openLink(String url);
}
