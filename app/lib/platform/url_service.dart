import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/core/ports/url_port.dart';
import 'package:url_launcher/url_launcher.dart';

/// Builds a `mailto:` link with the subject and body encoded as `%20`, not `+`,
/// which mail apps read literally. Throws [ArgumentError] for an address that
/// is not a plain email address.
Uri buildMailUri({required String to, String? subject, String? body}) {
  if (!RegExp(r'^[^\s@<>,;]+@[^\s@<>,;]+\.[^\s@<>,;]+$').hasMatch(to)) {
    throw ArgumentError.value(to, 'to', 'not an email address');
  }
  final List<String> query = <String>[
    if (subject != null && subject.isNotEmpty) 'subject=${Uri.encodeComponent(subject)}',
    if (body != null && body.isNotEmpty) 'body=${Uri.encodeComponent(body)}',
  ];
  return Uri.parse('mailto:$to${query.isEmpty ? '' : '?${query.join('&')}'}');
}

typedef UrlLauncher = Future<bool> Function(Uri uri);

Future<bool> _launchExternal(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

final class UrlService implements UrlPort {
  UrlService({UrlLauncher? launcher, LogPort? log})
      : _launch = launcher ?? _launchExternal,
        _log = log;

  final UrlLauncher _launch;
  final LogPort? _log;

  @override
  Future<bool> openMail({required String to, String? subject, String? body}) async {
    try {
      return await _launch(buildMailUri(to: to, subject: subject, body: body));
    } on Object catch (error) {
      _log?.log(LogLevel.warning, 'url', 'mail failed: $error');
      return false;
    }
  }

  /// Opens http and https links only.
  @override
  Future<bool> openLink(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http') || uri.host.isEmpty) {
      return false;
    }
    try {
      return await _launch(uri);
    } on Object catch (error) {
      _log?.log(LogLevel.warning, 'url', 'link failed: $error');
      return false;
    }
  }
}
