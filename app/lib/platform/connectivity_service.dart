import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tehillah/core/ports/connectivity_port.dart';

/// Reduces the plugin's list of active connections to one kind. Wi-Fi and
/// Ethernet count as Wi-Fi (not metered); mobile data comes next; an empty list
/// or "none" means offline; anything else (VPN, Bluetooth) is "other".
ConnectionKind connectionKindOf(List<ConnectivityResult> results) {
  if (results.contains(ConnectivityResult.wifi) || results.contains(ConnectivityResult.ethernet)) {
    return ConnectionKind.wifi;
  }
  if (results.contains(ConnectivityResult.mobile)) {
    return ConnectionKind.mobile;
  }
  if (results.isEmpty || results.every((ConnectivityResult r) => r == ConnectivityResult.none)) {
    return ConnectionKind.none;
  }
  return ConnectionKind.other;
}

final class ConnectivityService implements ConnectivityPort {
  ConnectivityService({Connectivity? connectivity}) : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<ConnectionKind> current() async {
    try {
      return connectionKindOf(await _connectivity.checkConnectivity());
    } on Object {
      // Unknown is treated as not Wi-Fi, so a Wi-Fi-only download waits.
      return ConnectionKind.other;
    }
  }

  @override
  Stream<ConnectionKind> get changes =>
      _connectivity.onConnectivityChanged.map(connectionKindOf);
}
