import 'dart:convert';

enum ConsentStatus { unknown, required, notRequired, obtained }

/// The consent state as Google's User Messaging Platform reports it.
final class ConsentSnapshot {
  const ConsentSnapshot({
    required this.status,
    required this.canRequestAds,
    required this.privacyOptionsRequired,
  });

  /// No answer yet: ads may not be requested.
  static const ConsentSnapshot unknown = ConsentSnapshot(
    status: ConsentStatus.unknown,
    canRequestAds: false,
    privacyOptionsRequired: false,
  );

  /// Reads a saved snapshot. Anything unreadable is [unknown], never a guess
  /// that allows ads.
  factory ConsentSnapshot.decode(String? raw) {
    if (raw == null) {
      return unknown;
    }
    try {
      final Object? value = jsonDecode(raw);
      if (value is Map<String, Object?>) {
        final Object? status = value['status'];
        final Object? can = value['canRequestAds'];
        final Object? options = value['privacyOptionsRequired'];
        if (can is bool && options is bool) {
          for (final ConsentStatus s in ConsentStatus.values) {
            if (s.name == status) {
              return ConsentSnapshot(
                status: s,
                canRequestAds: can,
                privacyOptionsRequired: options,
              );
            }
          }
        }
      }
    } on FormatException {
      // Fall through.
    }
    return unknown;
  }

  final ConsentStatus status;
  final bool canRequestAds;
  final bool privacyOptionsRequired;

  String encode() => jsonEncode(<String, Object?>{
        'status': status.name,
        'canRequestAds': canRequestAds,
        'privacyOptionsRequired': privacyOptionsRequired,
      });

  @override
  bool operator ==(Object other) =>
      other is ConsentSnapshot &&
      other.status == status &&
      other.canRequestAds == canRequestAds &&
      other.privacyOptionsRequired == privacyOptionsRequired;

  @override
  int get hashCode => Object.hash(status, canRequestAds, privacyOptionsRequired);

  @override
  String toString() => 'ConsentSnapshot($status, ads: $canRequestAds, options: $privacyOptionsRequired)';
}

/// The consent platform behind an interface.
abstract interface class ConsentPort {
  /// Refreshes consent information and shows the form when one is required and
  /// available. Throws if the refresh could not complete (for example offline).
  Future<ConsentSnapshot> refresh();

  /// The state the platform already holds on the device, without the network.
  Future<ConsentSnapshot> current();

  /// Shows the privacy options form and returns the new state.
  Future<ConsentSnapshot> showPrivacyOptions();
}
