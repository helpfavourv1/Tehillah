import 'dart:convert';

import 'package:tehillah/core/models/settings_model.dart';

/// Settings are small and forgiving: anything unreadable gives the defaults,
/// and a bad single field keeps the other fields (see [SettingsModel.fromJson]).
abstract final class SettingsCodec {
  static const String key = 'settings.v1';

  static String encode(SettingsModel settings) => jsonEncode(settings.toJson());

  static SettingsModel decode(String? raw) {
    if (raw == null) {
      return const SettingsModel();
    }
    try {
      final Object? value = jsonDecode(raw);
      if (value is Map<String, Object?>) {
        return SettingsModel.fromJson(value);
      }
    } on FormatException {
      // Fall through to the defaults.
    }
    return const SettingsModel();
  }
}
