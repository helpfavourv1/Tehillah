import 'package:share_plus/share_plus.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/core/ports/share_port.dart';

final class ShareService implements SharePort {
  ShareService({LogPort? log}) : _log = log;

  final LogPort? _log;

  @override
  Future<bool> shareText(String text, {String? subject}) async {
    if (text.trim().isEmpty) {
      return false;
    }
    try {
      await SharePlus.instance.share(ShareParams(text: text, subject: subject));
      return true;
    } on Object catch (error) {
      _log?.log(LogLevel.warning, 'share', 'share failed: $error');
      return false;
    }
  }
}
