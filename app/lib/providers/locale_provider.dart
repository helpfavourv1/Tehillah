import 'package:flutter/foundation.dart';
import 'package:tehillah/core/models/language_codes.dart';
import 'package:tehillah/core/models/settings_model.dart';
import 'package:tehillah/providers/safe_notifier.dart';
import 'package:tehillah/providers/settings_provider.dart';

/// The two independent languages: the interface and the Bible reader.
@immutable
final class LocaleState {
  const LocaleState({required this.appOverride, required this.readerLanguage});

  /// The language the user picked for the interface, or null to follow the
  /// device.
  final String? appOverride;

  /// The reader's language, whatever the interface language is.
  final String readerLanguage;

  /// The interface language to use, given the device's languages (most
  /// preferred first). An override always wins.
  String appLanguage(Iterable<String> deviceLanguages) =>
      appOverride ?? LanguageCodes.resolve(deviceLanguages);

  bool get followsDevice => appOverride == null;

  @override
  bool operator ==(Object other) =>
      other is LocaleState &&
      other.appOverride == appOverride &&
      other.readerLanguage == readerLanguage;

  @override
  int get hashCode => Object.hash(appOverride, readerLanguage);
}

/// Interface and reader languages. Follows [SettingsProvider], saves there.
final class LocaleProvider extends SafeNotifier<LocaleState> {
  LocaleProvider(this._settings)
      : super(LocaleState(
          appOverride: _settings.value.appLocale,
          readerLanguage: _settings.value.readerLocale,
        )) {
    _settings.addListener(_sync);
  }

  final SettingsProvider _settings;

  void _sync() {
    final SettingsModel s = _settings.value;
    value = LocaleState(appOverride: s.appLocale, readerLanguage: s.readerLocale);
  }

  /// Sets the interface language. Unsupported codes are ignored.
  void setAppLanguage(String code) {
    if (!LanguageCodes.isSupported(code)) {
      return;
    }
    _settings.update((SettingsModel s) => s.copyWith(appLocale: code));
  }

  void followDeviceLanguage() => _settings
      .update((SettingsModel s) => s.copyWith(followDeviceLanguage: true));

  /// Sets the reader language. Unsupported codes are ignored.
  void setReaderLanguage(String code) {
    if (!LanguageCodes.isSupported(code)) {
      return;
    }
    _settings.update((SettingsModel s) => s.copyWith(readerLocale: code));
  }

  @override
  void dispose() {
    _settings.removeListener(_sync);
    super.dispose();
  }
}
