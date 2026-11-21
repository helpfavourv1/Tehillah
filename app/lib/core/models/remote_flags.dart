import 'dart:convert';

/// Switches read from `flags.json` on the website, so a broken feature can be
/// turned off without a new build. Every flag defaults to on, and a missing or
/// wrongly typed value falls back to its default.
final class RemoteFlags {
  const RemoteFlags({
    this.adsEnabled = true,
    this.interstitialsEnabled = true,
    this.rewardedEnabled = true,
    this.readerDownloadEnabled = true,
  });

  static const RemoteFlags defaults = RemoteFlags();

  factory RemoteFlags.decode(String? raw) {
    if (raw == null) {
      return defaults;
    }
    try {
      final Object? value = jsonDecode(raw);
      if (value is Map<String, Object?>) {
        bool read(String key) {
          final Object? v = value[key];
          return v is bool ? v : true;
        }

        return RemoteFlags(
          adsEnabled: read('adsEnabled'),
          interstitialsEnabled: read('interstitialsEnabled'),
          rewardedEnabled: read('rewardedEnabled'),
          readerDownloadEnabled: read('readerDownloadEnabled'),
        );
      }
    } on FormatException {
      // Fall through.
    }
    return defaults;
  }

  final bool adsEnabled;
  final bool interstitialsEnabled;
  final bool rewardedEnabled;
  final bool readerDownloadEnabled;

  String encode() => jsonEncode(<String, Object?>{
        'adsEnabled': adsEnabled,
        'interstitialsEnabled': interstitialsEnabled,
        'rewardedEnabled': rewardedEnabled,
        'readerDownloadEnabled': readerDownloadEnabled,
      });

  @override
  bool operator ==(Object other) =>
      other is RemoteFlags &&
      other.adsEnabled == adsEnabled &&
      other.interstitialsEnabled == interstitialsEnabled &&
      other.rewardedEnabled == rewardedEnabled &&
      other.readerDownloadEnabled == readerDownloadEnabled;

  @override
  int get hashCode =>
      Object.hash(adsEnabled, interstitialsEnabled, rewardedEnabled, readerDownloadEnabled);
}
