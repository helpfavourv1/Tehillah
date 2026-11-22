import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/models/language_codes.dart';
import 'package:tehillah/core/models/settings_model.dart';
import 'package:tehillah/core/storage/settings_codec.dart';
import 'package:tehillah/providers/locale_provider.dart';
import 'package:tehillah/providers/settings_provider.dart';
import 'package:tehillah/providers/theme_provider.dart';

import '../fakes/fake_storage.dart';

void main() {
  late FakeStorage storage;
  late FakeLog log;
  late SettingsProvider settings;

  setUp(() async {
    storage = FakeStorage();
    log = FakeLog();
    settings = SettingsProvider(storage, log);
  });

  tearDown(() => settings.dispose());

  group('SettingsProvider', () {
    test('a new player gets the defaults', () async {
      await settings.load();
      expect(settings.isLoaded, isTrue);
      expect(settings.value, const SettingsModel());
    });

    test('saved settings are read back', () async {
      storage.values[SettingsCodec.key] =
          SettingsCodec.encode(const SettingsModel(soundOn: false, readerLocale: 'ar'));
      await settings.load();
      expect(settings.value.soundOn, isFalse);
      expect(settings.value.readerLocale, 'ar');
    });

    test('a damaged value gives the defaults', () async {
      storage.values[SettingsCodec.key] = '{not json';
      await settings.load();
      expect(settings.value, const SettingsModel());
    });

    test('a failing read gives the defaults and is logged', () async {
      final SettingsProvider broken = SettingsProvider(_ThrowingStorage(), log);
      await broken.load();
      expect(broken.isLoaded, isTrue);
      expect(broken.value, const SettingsModel());
      expect(log.lines.any((String l) => l.contains('read failed')), isTrue);
      broken.dispose();
    });

    test('an update applies at once and is written', () async {
      await settings.load();
      settings.update((SettingsModel s) => s.copyWith(soundOn: false));
      expect(settings.value.soundOn, isFalse);
      await settings.flush();
      final Map<String, Object?> saved =
          jsonDecode(storage.values[SettingsCodec.key]!) as Map<String, Object?>;
      expect(saved['soundOn'], false);
    });

    test('an update that changes nothing writes nothing', () async {
      await settings.load();
      settings.update((SettingsModel s) => s);
      await settings.flush();
      expect(storage.values, isEmpty);
    });

    test('several quick updates end with the newest value saved', () async {
      await settings.load();
      settings.update((SettingsModel s) => s.copyWith(soundOn: false));
      settings.update((SettingsModel s) => s.copyWith(hapticsOn: false));
      settings.update((SettingsModel s) => s.copyWith(musicOn: false));
      await settings.flush();
      final SettingsModel saved = SettingsCodec.decode(storage.values[SettingsCodec.key]);
      expect(saved.soundOn, isFalse);
      expect(saved.hapticsOn, isFalse);
      expect(saved.musicOn, isFalse);
    });

    test('a failed write keeps the change, flags it, and a later write clears it', () async {
      await settings.load();
      storage.failWrites = true;
      settings.update((SettingsModel s) => s.copyWith(soundOn: false));
      await settings.flush();
      expect(settings.value.soundOn, isFalse);
      expect(settings.saveFailed.value, isTrue);
      storage.failWrites = false;
      settings.update((SettingsModel s) => s.copyWith(hapticsOn: false));
      await settings.flush();
      expect(settings.saveFailed.value, isFalse);
      final SettingsModel saved = SettingsCodec.decode(storage.values[SettingsCodec.key]);
      expect(saved.soundOn, isFalse);
      expect(saved.hapticsOn, isFalse);
    });

    test('an update before load is ignored and logged', () async {
      settings.update((SettingsModel s) => s.copyWith(soundOn: false));
      expect(settings.value.soundOn, isTrue);
      expect(storage.values, isEmpty);
      expect(log.lines.any((String l) => l.contains('before load')), isTrue);
    });

    test('a disposed provider ignores a write that finishes late', () async {
      await settings.load();
      settings.update((SettingsModel s) => s.copyWith(soundOn: false));
      settings.dispose();
      await settings.flush();
      expect(settings.isDisposed, isTrue);
    });
  });

  group('ThemeProvider', () {
    test('starts from the loaded settings and follows later changes', () async {
      storage.values[SettingsCodec.key] =
          SettingsCodec.encode(const SettingsModel(themeChoice: ThemeChoice.dark));
      await settings.load();
      final ThemeProvider theme = ThemeProvider(settings);
      expect(theme.value.choice, ThemeChoice.dark);
      settings.update((SettingsModel s) => s.copyWith(readerTheme: ReaderTheme.sepia));
      expect(theme.value.readerTheme, ReaderTheme.sepia);
      theme.dispose();
    });

    test('setters are saved through settings', () async {
      await settings.load();
      final ThemeProvider theme = ThemeProvider(settings);
      theme.setChoice(ThemeChoice.light);
      theme.setReaderTheme(ReaderTheme.dark);
      await settings.flush();
      final SettingsModel saved = SettingsCodec.decode(storage.values[SettingsCodec.key]);
      expect(saved.themeChoice, ThemeChoice.light);
      expect(saved.readerTheme, ReaderTheme.dark);
      theme.dispose();
    });

    test('system follows the device; light and dark do not', () {
      const ThemeState system =
          ThemeState(choice: ThemeChoice.system, readerTheme: ReaderTheme.light);
      const ThemeState light =
          ThemeState(choice: ThemeChoice.light, readerTheme: ReaderTheme.light);
      const ThemeState dark =
          ThemeState(choice: ThemeChoice.dark, readerTheme: ReaderTheme.light);
      expect(system.isDark(platformIsDark: true), isTrue);
      expect(system.isDark(platformIsDark: false), isFalse);
      expect(light.isDark(platformIsDark: true), isFalse);
      expect(dark.isDark(platformIsDark: false), isTrue);
    });

    test('stops listening once disposed', () async {
      await settings.load();
      final ThemeProvider theme = ThemeProvider(settings);
      theme.dispose();
      settings.update((SettingsModel s) => s.copyWith(themeChoice: ThemeChoice.dark));
      expect(theme.value.choice, ThemeChoice.system);
    });
  });

  group('LocaleProvider', () {
    test('the interface and reader languages are independent', () async {
      await settings.load();
      final LocaleProvider locale = LocaleProvider(settings);
      locale.setAppLanguage('de');
      locale.setReaderLanguage('he');
      expect(locale.value.appOverride, 'de');
      expect(locale.value.readerLanguage, 'he');
      expect(locale.value.appLanguage(<String>['ja']), 'de');
      locale.dispose();
    });

    test('unsupported codes are ignored', () async {
      await settings.load();
      final LocaleProvider locale = LocaleProvider(settings);
      locale.setAppLanguage('xx');
      locale.setReaderLanguage('pt');
      expect(locale.value.appOverride, isNull);
      expect(locale.value.readerLanguage, 'en');
      locale.dispose();
    });

    test('following the device clears the override and resolves device languages', () async {
      await settings.load();
      final LocaleProvider locale = LocaleProvider(settings);
      locale.setAppLanguage('fr');
      locale.followDeviceLanguage();
      expect(locale.value.followsDevice, isTrue);
      expect(locale.value.appLanguage(<String>['pt', 'en']), 'pt_BR');
      await settings.flush();
      expect(SettingsCodec.decode(storage.values[SettingsCodec.key]).appLocale, isNull);
      locale.dispose();
    });
  });

  group('LanguageCodes.resolve', () {
    test('maps device languages to shipped ones', () {
      expect(LanguageCodes.resolve(<String>['pt']), 'pt_BR');
      expect(LanguageCodes.resolve(<String>['zh']), 'zh_Hans');
      expect(LanguageCodes.resolve(<String>['iw']), 'he');
      expect(LanguageCodes.resolve(<String>['HI']), 'hi');
    });

    test('skips unsupported languages and falls back to English', () {
      expect(LanguageCodes.resolve(<String>['sv', 'ko']), 'ko');
      expect(LanguageCodes.resolve(<String>['sv']), 'en');
      expect(LanguageCodes.resolve(<String>[]), 'en');
    });
  });
}

final class _ThrowingStorage extends FakeStorage {
  @override
  Future<String?> getString(String key) async => throw StateError('no storage');
}
