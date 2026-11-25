import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/errors/app_error.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/models/settings_model.dart';
import 'package:tehillah/core/storage/migrations.dart';
import 'package:tehillah/core/storage/progress_codec.dart';
import 'package:tehillah/core/storage/progress_store.dart';
import 'package:tehillah/core/storage/settings_codec.dart';

import '../../fakes/fake_storage.dart';

Progress _sample() => Progress.empty().copyWith(sessions: 4, ratingPromptShown: true);

String _envelope(String payload, {String? sha}) {
  final Map<String, Object?> good =
      jsonDecode(ProgressCodec().encode(Progress.empty())) as Map<String, Object?>;
  return jsonEncode(<String, Object?>{
    'format': 1,
    'sha256': sha ?? good['sha256'],
    'payload': payload,
  });
}

void main() {
  group('Migrator', () {
    final Migrator migrator = Migrator(
      currentVersion: 3,
      migrations: <Migration>[
        Migration(
          from: 1,
          to: 2,
          apply: (Map<String, Object?> d) => <String, Object?>{...d, 'a': 1},
        ),
        Migration(
          from: 2,
          to: 3,
          apply: (Map<String, Object?> d) => <String, Object?>{...d, 'b': (d['a']! as int) + 1},
        ),
      ],
    );

    test('runs every step in order and stamps the new version', () {
      final MigrationOutcome out = migrator.upgrade(<String, Object?>{'schemaVersion': 1});
      expect(out, isA<MigrationCurrent>());
      final MigrationCurrent current = out as MigrationCurrent;
      expect(current.migratedFrom, 1);
      expect(current.data, <String, Object?>{'schemaVersion': 3, 'a': 1, 'b': 2});
    });

    test('data already current is untouched', () {
      final MigrationCurrent out =
          migrator.upgrade(<String, Object?>{'schemaVersion': 3}) as MigrationCurrent;
      expect(out.migratedFrom, isNull);
    });

    test('newer data is flagged and never migrated', () {
      final MigrationOutcome out = migrator.upgrade(<String, Object?>{'schemaVersion': 9});
      expect(out, isA<MigrationNewer>());
      expect((out as MigrationNewer).version, 9);
    });

    test('a missing or bad version is a format error', () {
      expect(() => migrator.upgrade(<String, Object?>{}), throwsFormatException);
      expect(() => migrator.upgrade(<String, Object?>{'schemaVersion': 0}), throwsFormatException);
      expect(() => migrator.upgrade(<String, Object?>{'schemaVersion': '1'}), throwsFormatException);
    });

    test('a gap in the chain is rejected when the migrator is built', () {
      expect(() => Migrator(currentVersion: 3), throwsArgumentError);
    });
  });

  group('ProgressCodec', () {
    final ProgressCodec codec = ProgressCodec();

    test('round trips', () {
      final DecodedProgress decoded = codec.decode(codec.encode(_sample()));
      expect(decoded.progress, _sample());
      expect(decoded.readOnly, isFalse);
      expect(decoded.migratedFrom, isNull);
    });

    test('rejects text that is not JSON, the wrong shape and the wrong envelope', () {
      expect(() => codec.decode('not json'), throwsFormatException);
      expect(() => codec.decode('[]'), throwsFormatException);
      expect(() => codec.decode('{}'), throwsFormatException);
      expect(
        () => codec.decode(jsonEncode(<String, Object?>{'format': 2, 'sha256': 'x', 'payload': 'y'})),
        throwsFormatException,
      );
    });

    test('rejects a payload whose checksum does not match', () {
      final String raw = codec.encode(_sample());
      final Map<String, Object?> map = jsonDecode(raw) as Map<String, Object?>;
      map['payload'] = (map['payload']! as String).replaceFirst('"sessions":4', '"sessions":5');
      expect(() => codec.decode(jsonEncode(map)), throwsFormatException);
    });

    test('rejects a payload that is not an object even with a valid checksum', () {
      final ProgressCodec other = ProgressCodec();
      final String encoded = other.encode(Progress.empty());
      final Map<String, Object?> map = jsonDecode(encoded) as Map<String, Object?>;
      expect(map['sha256'], isA<String>());
      expect(() => codec.decode(_envelope('[]')), throwsFormatException);
    });

    test('a file from a newer version is read but flagged read-only', () {
      final Migrator v1 = Migrator(currentVersion: 1);
      final ProgressCodec old = ProgressCodec(migrator: v1);
      final Progress future = _sample().copyWith(schemaVersion: 2);
      final DecodedProgress decoded = old.decode(codec.encode(future));
      expect(decoded.readOnly, isTrue);
      expect(decoded.progress.sessions, 4);
    });
  });

  group('ProgressStore', () {
    late FakeStorage storage;
    late FakeLog log;
    late ProgressStore store;

    setUp(() {
      storage = FakeStorage();
      log = FakeLog();
      store = ProgressStore(storage, log);
    });

    test('a new player loads fresh', () async {
      final ProgressLoad load = await store.load();
      expect(load.status, ProgressLoadStatus.fresh);
      expect(load.needsNotice, isFalse);
      expect(load.progress, Progress.empty());
    });

    test('save then load returns the same progress', () async {
      expect(await store.save(_sample()), isA<SaveOk>());
      final ProgressLoad load = await ProgressStore(storage, log).load();
      expect(load.status, ProgressLoadStatus.loaded);
      expect(load.progress, _sample());
    });

    test('a damaged main file recovers from the backup with a notice', () async {
      await store.save(_sample());
      await store.save(_sample().copyWith(sessions: 5));
      storage.files['progress.json'] = '{broken';
      final ProgressLoad load = await ProgressStore(storage, log).load();
      expect(load.status, ProgressLoadStatus.recoveredFromBackup);
      expect(load.needsNotice, isTrue);
      expect(load.progress.sessions, 4);
    });

    test('two damaged files start clean with a notice and saving works', () async {
      storage.files['progress.json'] = '{broken';
      storage.backups['progress.json'] = 'also broken';
      final ProgressStore fresh = ProgressStore(storage, log);
      final ProgressLoad load = await fresh.load();
      expect(load.status, ProgressLoadStatus.startedClean);
      expect(load.needsNotice, isTrue);
      expect(await fresh.save(Progress.empty()), isA<SaveOk>());
    });

    test('a damaged main file with no backup starts clean', () async {
      storage.files['progress.json'] = '{broken';
      expect((await store.load()).status, ProgressLoadStatus.startedClean);
    });

    test('a missing main file with a good backup is recovered', () async {
      await store.save(_sample());
      await store.save(_sample());
      storage.files.remove('progress.json');
      final ProgressLoad load = await ProgressStore(storage, log).load();
      expect(load.status, ProgressLoadStatus.recoveredFromBackup);
    });

    test('a newer file is read-only and is never overwritten', () async {
      final String future = ProgressCodec()
          .encode(_sample().copyWith(schemaVersion: Progress.currentSchemaVersion + 1));
      storage.files['progress.json'] = future;
      final ProgressLoad load = await store.load();
      expect(load.status, ProgressLoadStatus.newerVersionReadOnly);
      expect(store.readOnly, isTrue);
      expect(await store.save(Progress.empty()), isA<SaveSkippedReadOnly>());
      expect(storage.files['progress.json'], future);
    });

    test('unreadable storage blocks writes so good data is not replaced', () async {
      storage.failReads = true;
      final ProgressLoad load = await store.load();
      expect(load.status, ProgressLoadStatus.storageUnavailable);
      expect(await store.save(Progress.empty()), isA<SaveSkippedReadOnly>());
      storage.failReads = false;
      expect((await store.load()).status, ProgressLoadStatus.fresh);
      expect(await store.save(Progress.empty()), isA<SaveOk>());
    });

    test('a failed write is reported as a storage warning and logged', () async {
      storage.failWrites = true;
      final SaveResult result = await store.save(_sample());
      expect(result, isA<SaveFailed>());
      final StorageDegradedError error = (result as SaveFailed).error;
      expect(error.treatment, ErrorTreatment.warningBanner);
      expect(log.lines.any((String l) => l.contains('write failed')), isTrue);
    });
  });

  group('SettingsCodec', () {
    test('round trips', () {
      const SettingsModel s = SettingsModel(soundOn: false, readerLocale: 'fr');
      expect(SettingsCodec.decode(SettingsCodec.encode(s)), s);
    });

    test('unreadable input gives the defaults', () {
      expect(SettingsCodec.decode(null), const SettingsModel());
      expect(SettingsCodec.decode('nope'), const SettingsModel());
      expect(SettingsCodec.decode('[1]'), const SettingsModel());
    });

    test('a bad field keeps the other fields', () {
      final SettingsModel s = SettingsCodec.decode('{"soundOn":false,"themeChoice":"neon"}');
      expect(s.soundOn, isFalse);
      expect(s.themeChoice, ThemeChoice.system);
    });
  });
}
