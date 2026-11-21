enum ConnectionKind { none, wifi, mobile, other }

abstract interface class ConnectivityPort {
  Future<ConnectionKind> current();

  Stream<ConnectionKind> get changes;
}
