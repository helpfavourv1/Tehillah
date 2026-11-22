import 'package:tehillah/core/models/remote_flags.dart';
import 'package:tehillah/core/ports/flags_port.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/providers/safe_notifier.dart';

/// The remote switches. They start at the safe defaults and are replaced when
/// the flags file arrives; a failure never changes them.
final class FlagsProvider extends SafeNotifier<RemoteFlags> {
  FlagsProvider(this._port, this._log) : super(RemoteFlags.defaults);

  final FlagsPort _port;
  final LogPort _log;

  Future<void> refresh() async {
    try {
      value = await _port.load();
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'flags', 'refresh failed: $error');
    }
  }
}
