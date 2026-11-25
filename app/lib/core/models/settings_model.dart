import 'package:tehillah/core/models/language_codes.dart';

/// App theme choice. `system` follows the device.
enum ThemeChoice { system, light, dark }

/// Reader theme. Sepia is the warm paper theme.
enum ReaderTheme { light, dark, sepia }

/// How a kick is aimed.
enum InputScheme { flick, timingBar }

/// User settings. Reading is forgiving: a missing or invalid field falls back
/// to its default, so one bad value never costs the user the other settings.
final class SettingsModel {
  const SettingsModel({
    this.themeChoice = ThemeChoice.system,
    this.readerTheme = ReaderTheme.light,
    this.appLocale,
    this.readerLocale = 'en',
    this.inputScheme = InputScheme.flick,
    this.soundOn = true,
    this.musicOn = true,
    this.hapticsOn = true,
    this.remindersOn = false,
    this.reminderMinuteOfDay = 1080,
    this.readerTextScale = 1.0,
    this.packWifiOnly = true,
    this.dismissedUpdateBuild = 0,
  })  : assert(reminderMinuteOfDay >= 0 && reminderMinuteOfDay < 1440),
        assert(readerTextScale >= minTextScale && readerTextScale <= maxTextScale);

  factory SettingsModel.fromJson(Map<String, Object?> json) {
    const SettingsModel d = SettingsModel();
    T pick<T extends Enum>(List<T> values, String key, T fallback) {
      for (final T v in values) {
        if (v.name == json[key]) {
          return v;
        }
      }
      return fallback;
    }

    bool flag(String key, bool fallback) {
      final Object? v = json[key];
      return v is bool ? v : fallback;
    }

    final Object? app = json['appLocale'];
    final Object? reader = json['readerLocale'];
    final Object? minute = json['reminderMinuteOfDay'];
    final Object? scale = json['readerTextScale'];
    final Object? dismissed = json['dismissedUpdateBuild'];
    return SettingsModel(
      themeChoice: pick(ThemeChoice.values, 'themeChoice', d.themeChoice),
      readerTheme: pick(ReaderTheme.values, 'readerTheme', d.readerTheme),
      appLocale: app is String && LanguageCodes.isSupported(app) ? app : null,
      readerLocale:
          reader is String && LanguageCodes.isSupported(reader) ? reader : d.readerLocale,
      inputScheme: pick(InputScheme.values, 'inputScheme', d.inputScheme),
      soundOn: flag('soundOn', d.soundOn),
      musicOn: flag('musicOn', d.musicOn),
      hapticsOn: flag('hapticsOn', d.hapticsOn),
      remindersOn: flag('remindersOn', d.remindersOn),
      reminderMinuteOfDay:
          minute is int && minute >= 0 && minute < 1440 ? minute : d.reminderMinuteOfDay,
      readerTextScale: scale is num &&
              scale >= minTextScale &&
              scale <= maxTextScale
          ? scale.toDouble()
          : d.readerTextScale,
      packWifiOnly: flag('packWifiOnly', d.packWifiOnly),
      dismissedUpdateBuild: dismissed is int && dismissed >= 0 ? dismissed : 0,
    );
  }

  static const double minTextScale = 0.8;
  static const double maxTextScale = 2.0;

  final ThemeChoice themeChoice;
  final ReaderTheme readerTheme;

  /// Interface language override, or null to follow the device.
  final String? appLocale;

  /// The Bible reader's language, independent of the interface language.
  final String readerLocale;

  final InputScheme inputScheme;
  final bool soundOn;
  final bool musicOn;
  final bool hapticsOn;
  final bool remindersOn;

  /// Daily Bread reminder time as minutes after local midnight (1080 is 18:00).
  final int reminderMinuteOfDay;

  /// Reader text size multiplier, 0.8 to 2.0.
  final double readerTextScale;

  /// Download Bible packs on Wi-Fi only (false allows mobile data).
  final bool packWifiOnly;

  /// The newest build the user has already said "not now" to, so the update
  /// prompt does not return for it.
  final int dismissedUpdateBuild;

  SettingsModel copyWith({
    ThemeChoice? themeChoice,
    ReaderTheme? readerTheme,
    String? appLocale,
    bool followDeviceLanguage = false,
    String? readerLocale,
    InputScheme? inputScheme,
    bool? soundOn,
    bool? musicOn,
    bool? hapticsOn,
    bool? remindersOn,
    int? reminderMinuteOfDay,
    double? readerTextScale,
    bool? packWifiOnly,
    int? dismissedUpdateBuild,
  }) {
    return SettingsModel(
      themeChoice: themeChoice ?? this.themeChoice,
      readerTheme: readerTheme ?? this.readerTheme,
      appLocale: followDeviceLanguage ? null : (appLocale ?? this.appLocale),
      readerLocale: readerLocale ?? this.readerLocale,
      inputScheme: inputScheme ?? this.inputScheme,
      soundOn: soundOn ?? this.soundOn,
      musicOn: musicOn ?? this.musicOn,
      hapticsOn: hapticsOn ?? this.hapticsOn,
      remindersOn: remindersOn ?? this.remindersOn,
      reminderMinuteOfDay: reminderMinuteOfDay ?? this.reminderMinuteOfDay,
      readerTextScale: readerTextScale ?? this.readerTextScale,
      packWifiOnly: packWifiOnly ?? this.packWifiOnly,
      dismissedUpdateBuild: dismissedUpdateBuild ?? this.dismissedUpdateBuild,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'themeChoice': themeChoice.name,
        'readerTheme': readerTheme.name,
        'appLocale': appLocale,
        'readerLocale': readerLocale,
        'inputScheme': inputScheme.name,
        'soundOn': soundOn,
        'musicOn': musicOn,
        'hapticsOn': hapticsOn,
        'remindersOn': remindersOn,
        'reminderMinuteOfDay': reminderMinuteOfDay,
        'readerTextScale': readerTextScale,
        'packWifiOnly': packWifiOnly,
        'dismissedUpdateBuild': dismissedUpdateBuild,
      };

  @override
  bool operator ==(Object other) =>
      other is SettingsModel &&
      other.themeChoice == themeChoice &&
      other.readerTheme == readerTheme &&
      other.appLocale == appLocale &&
      other.readerLocale == readerLocale &&
      other.inputScheme == inputScheme &&
      other.soundOn == soundOn &&
      other.musicOn == musicOn &&
      other.hapticsOn == hapticsOn &&
      other.remindersOn == remindersOn &&
      other.reminderMinuteOfDay == reminderMinuteOfDay &&
      other.readerTextScale == readerTextScale &&
      other.packWifiOnly == packWifiOnly &&
      other.dismissedUpdateBuild == dismissedUpdateBuild;

  @override
  int get hashCode => Object.hash(
        themeChoice,
        readerTheme,
        appLocale,
        readerLocale,
        inputScheme,
        soundOn,
        musicOn,
        hapticsOn,
        remindersOn,
        reminderMinuteOfDay,
        readerTextScale,
        packWifiOnly,
        dismissedUpdateBuild,
      );
}
