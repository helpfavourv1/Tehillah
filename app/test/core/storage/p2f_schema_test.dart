import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/models/remote_flags.dart';
import 'package:tehillah/core/models/settings_model.dart';
import 'package:tehillah/core/storage/progress_codec.dart';

String envelope(Map<String, Object?> payload) {
  final String text = jsonEncode(payload);
  return jsonEncode(<String, Object?>{
    'format': 1,
    'sha256': sha256.convert(utf8.encode(text)).toString(),
    'payload': text,
  });
}

void main() {
  onboardingFlagTests();
  group('progress schema 2', () {
    test('this build writes version 2', () {
      expect(Progress.currentSchemaVersion, 2);
      expect(Progress.empty().schemaVersion, 2);
    });

    test('a version 1 file is migrated and every new field starts at its default', () {
      final Map<String, Object?> v1 = Progress.empty().toJson()
        ..['schemaVersion'] = 1
        ..remove('rescuedDays')
        ..remove('jerichoCleared')
        ..remove('jerichoCompletions')
        ..remove('slingBest')
        ..remove('slingPlays');
      final DecodedProgress d = ProgressCodec().decode(envelope(v1));
      expect(d.migratedFrom, 1);
      expect(d.readOnly, isFalse);
      expect(d.progress.schemaVersion, 2);
      expect(d.progress.rescuedDays, isEmpty);
      expect(d.progress.jerichoCleared, 0);
      expect(d.progress.jerichoCompletions, 0);
      expect(d.progress.slingBest, 0);
      expect(d.progress.slingPlays, 0);
    });

    test('a version 3 file is read-only and never migrated', () {
      final Map<String, Object?> v3 = Progress.empty().toJson()..['schemaVersion'] = 3;
      final DecodedProgress d = ProgressCodec().decode(envelope(v3));
      expect(d.readOnly, isTrue);
      expect(d.migratedFrom, isNull);
    });

    test('the new fields round trip', () {
      final Progress p = Progress(
        rescuedDays: <String>{'2026-11-22'},
        jerichoCleared: 4,
        jerichoCompletions: 2,
        slingBest: 3,
        slingPlays: 9,
      );
      expect(Progress.fromJson(p.toJson()), p);
      final DecodedProgress d = ProgressCodec().decode(ProgressCodec().encode(p));
      expect(d.progress, p);
    });

    test('bad values are rejected', () {
      Map<String, Object?> with_(String k, Object? v) => Progress.empty().toJson()..[k] = v;
      expect(() => Progress.fromJson(with_('slingBest', 4)), throwsFormatException);
      expect(() => Progress.fromJson(with_('jerichoCleared', 8)), throwsFormatException);
      expect(() => Progress.fromJson(with_('slingPlays', -1)), throwsFormatException);
      expect(() => Progress.fromJson(with_('rescuedDays', <Object?>['nope'])), throwsFormatException);
      expect(() => Progress.fromJson(with_('rescuedDays', <Object?>[3])), throwsFormatException);
    });
  });

  group('remote flags: latest build', () {
    test('defaults to unknown, which suggests nothing', () {
      expect(RemoteFlags.decode(null).latestBuild, 0);
      expect(RemoteFlags.decode('{}').latestBuild, 0);
    });

    test('is read when a whole number, else ignored', () {
      expect(RemoteFlags.decode('{"latestBuild": 7}').latestBuild, 7);
      expect(RemoteFlags.decode('{"latestBuild": "7"}').latestBuild, 0);
      expect(RemoteFlags.decode('{"latestBuild": -1}').latestBuild, 0);
    });

    test('round trips', () {
      const RemoteFlags f = RemoteFlags(latestBuild: 9);
      expect(RemoteFlags.decode(f.encode()), f);
    });
  });

  group('settings: dismissed update', () {
    test('defaults to zero and round trips', () {
      expect(const SettingsModel().dismissedUpdateBuild, 0);
      final SettingsModel s = const SettingsModel().copyWith(dismissedUpdateBuild: 5);
      expect(SettingsModel.fromJson(s.toJson()), s);
    });

    test('a missing or bad value reads as zero', () {
      expect(SettingsModel.fromJson(<String, Object?>{}).dismissedUpdateBuild, 0);
      expect(SettingsModel.fromJson(<String, Object?>{'dismissedUpdateBuild': -3}).dismissedUpdateBuild, 0);
      expect(SettingsModel.fromJson(<String, Object?>{'dismissedUpdateBuild': 'x'}).dismissedUpdateBuild, 0);
    });
  });
}

void onboardingFlagTests() {
  group('SettingsModel onboardingDone', () {
    test('is false by default and survives a json round trip', () {
      expect(const SettingsModel().onboardingDone, isFalse);
      final SettingsModel done = const SettingsModel().copyWith(onboardingDone: true);
      expect(SettingsModel.fromJson(done.toJson()).onboardingDone, isTrue);
    });

    test('older saved settings without the key read as not done', () {
      expect(SettingsModel.fromJson(<String, Object?>{}).onboardingDone, isFalse);
      expect(SettingsModel.fromJson(<String, Object?>{'onboardingDone': 'yes'}).onboardingDone, isFalse);
    });

    test('takes part in equality', () {
      expect(const SettingsModel() == const SettingsModel().copyWith(onboardingDone: true), isFalse);
    });
  });
}
