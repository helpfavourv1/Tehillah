import 'package:tehillah/core/models/remote_flags.dart';

abstract interface class FlagsPort {
  /// The remote switches, or the cached or default ones. Never throws.
  Future<RemoteFlags> load();
}
