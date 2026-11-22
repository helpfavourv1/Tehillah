import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:tehillah/core/errors/app_error.dart';
import 'package:tehillah/core/models/bible_pack.dart';
import 'package:tehillah/core/models/bookmark.dart';
import 'package:tehillah/core/models/pack_manifest.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/models/remote_flags.dart';
import 'package:tehillah/core/models/verse_ref.dart';
import 'package:tehillah/core/ports/connectivity_port.dart';
import 'package:tehillah/core/storage/progress_store.dart';
import 'package:tehillah/providers/bookmark_provider.dart';
import 'package:tehillah/providers/locale_provider.dart';
import 'package:tehillah/providers/pack_provider.dart';
import 'package:tehillah/providers/progress_provider.dart';
import 'package:tehillah/providers/reader_provider.dart';
import 'package:tehillah/providers/settings_provider.dart';

import '../fakes/fake_ports.dart';
import '../fakes/fake_storage.dart';

BiblePack _pack(String language) => BiblePack.fromJson(<String, Object?>{
      'schemaVersion': 1,
      'language': language,
      'translationId': language.toUpperCase(),
      'source': 'test source',
      'license': 'test license',
      'books': <String, Object?>{
        'Gen': <Object?>[
          <String>['In the beginning God created', 'The earth was formless', 'Let there be light'],
          <String>['Thus the heavens were finished', 'On the seventh day'],
        ],
        'Exod': <Object?>[
          <String>['These are the names', 'Joseph was in Egypt'],
        ],
        'Matt': <Object?>[
          <String>['The book of the genealogy'],
        ],
      },
    });

PackManifest _manifest() => PackManifest(
      schemaVersion: 1,
      entries: <PackManifestEntry>[
        PackManifestEntry(
          language: 'en',
          translationId: 'EN',
          version: 1,
          url: '/p/en.json.gz',
          bytes: 100,
          sha256: '0' * 64,
          noticePath: '/p/n.txt',
        ),
      ],
    );

Future<void> _settle() async {
  for (int i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeStorage storage;
  late FakeLog log;
  late FakePacks packsPort;
  late FakeConnectivity connectivity;
  late ValueNotifier<RemoteFlags> flags;
  late SettingsProvider settings;
  late LocaleProvider locale;
  late PackProvider packs;

  setUp(() async {
    storage = FakeStorage();
    log = FakeLog();
    packsPort = FakePacks()..manifest = _manifest();
    connectivity = FakeConnectivity();
    flags = ValueNotifier<RemoteFlags>(RemoteFlags.defaults);
    settings = SettingsProvider(storage, log);
    await settings.load();
    locale = LocaleProvider(settings);
    packs = PackProvider(packs: packsPort, connectivity: connectivity, flags: flags, log: log);
  });

  tearDown(() {
    packs.dispose();
    locale.dispose();
    settings.dispose();
    flags.dispose();
  });

  group('PackProvider', () {
    test('starts with every language not installed', () {
      expect(packs.value.of('en').phase, PackPhase.notInstalled);
      expect(packs.value.busyLanguage, isNull);
    });

    test('refresh finds installed Bibles', () async {
      packsPort.installed['en'] = _pack('en');
      await packs.refresh();
      expect(packs.value.isInstalled('en'), isTrue);
      expect(packs.value.isInstalled('es'), isFalse);
    });

    test('a download reports progress, installs and ends installed', () async {
      packsPort.installOnDownload = _pack('en');
      final List<PackPhase> phases = <PackPhase>[];
      packs.addListener(() => phases.add(packs.value.of('en').phase));
      await packs.download('en', wifiOnly: true);
      expect(phases.first, PackPhase.downloading);
      expect(packs.value.of('en').phase, PackPhase.installed);
      expect(packs.value.busyLanguage, isNull);
    });

    test('Wi-Fi only on mobile data fails with a message the prompt can offer to change', () async {
      connectivity.kind = ConnectionKind.mobile;
      await packs.download('en', wifiOnly: true);
      expect(packs.value.of('en').phase, PackPhase.failed);
      expect(packs.value.of('en').error!.code, 'pack.needs_wifi');
      await packs.download('en', wifiOnly: false);
      expect(packs.value.of('en').phase, PackPhase.installed);
    });

    test('offline fails as a user-recoverable error', () async {
      connectivity.kind = ConnectionKind.none;
      await packs.download('en', wifiOnly: false);
      expect(packs.value.of('en').error, isA<UserRecoverableError>());
      expect(packs.value.of('en').error!.code, 'pack.offline');
    });

    test('an error from the transfer is kept as the failure and retry works', () async {
      packsPort.downloadError =
          const SystemRecoverableError('pack.hash_mismatch', 'failed its check');
      await packs.download('en', wifiOnly: false);
      expect(packs.value.of('en').phase, PackPhase.failed);
      expect(packs.value.of('en').error!.code, 'pack.hash_mismatch');
      packsPort.downloadError = null;
      await packs.download('en', wifiOnly: false);
      expect(packs.value.of('en').phase, PackPhase.installed);
    });

    test('an unknown language in the list fails cleanly', () async {
      await packs.download('es', wifiOnly: false);
      expect(packs.value.of('es').error!.code, 'pack.not_listed');
    });

    test('a manifest that cannot be fetched fails without throwing', () async {
      packsPort.manifest = null;
      await packs.download('en', wifiOnly: false);
      expect(packs.value.of('en').phase, PackPhase.failed);
    });

    test('the remote switch blocks downloads', () async {
      flags.value = const RemoteFlags(readerDownloadEnabled: false);
      await packs.download('en', wifiOnly: false);
      expect(packs.value.of('en').phase, PackPhase.blocked);
      expect(packs.value.of('en').error!.code, 'pack.disabled');
    });

    test('delete removes an installed Bible', () async {
      packsPort.installOnDownload = _pack('en');
      await packs.download('en', wifiOnly: false);
      await packs.delete('en');
      expect(packs.value.isInstalled('en'), isFalse);
    });

    test('an unsupported or installed language is ignored', () async {
      await packs.download('xx', wifiOnly: false);
      packsPort.installed['en'] = _pack('en');
      await packs.refresh();
      await packs.download('en', wifiOnly: false);
      expect(packsPort.downloads, 0);
    });
  });

  group('ReaderProvider', () {
    late ReaderProvider reader;

    ReaderProvider make() => ReaderProvider(
          packs: packsPort,
          locale: locale,
          settings: settings,
          packState: packs,
          storage: storage,
          log: log,
        );

    setUp(() => reader = make());
    tearDown(() => reader.dispose());

    test('with no Bible installed the reader reports a missing pack', () async {
      await reader.load();
      expect(reader.value.status, ReaderStatus.missingPack);
      expect(reader.value.ready, isFalse);
    });

    test('with a Bible installed it opens at Genesis 1', () async {
      packsPort.installed['en'] = _pack('en');
      await reader.load();
      expect(reader.value.ready, isTrue);
      expect(reader.value.book, 'Gen');
      expect(reader.value.chapter, 1);
      expect(reader.value.verses.length, 3);
      expect(reader.value.hasPrevious, isFalse);
      expect(reader.value.hasNext, isTrue);
      expect(reader.value.translationId, 'EN');
    });

    test('next and previous cross book boundaries and stop at the ends', () async {
      packsPort.installed['en'] = _pack('en');
      await reader.load();
      expect(reader.next(), isTrue);
      expect(reader.value.chapter, 2);
      expect(reader.next(), isTrue);
      expect(reader.value.book, 'Exod');
      expect(reader.next(), isTrue);
      expect(reader.value.book, 'Matt');
      expect(reader.next(), isFalse);
      expect(reader.value.hasNext, isFalse);
      expect(reader.previous(), isTrue);
      expect(reader.value.book, 'Exod');
      expect(reader.previous(), isTrue);
      expect(reader.value.book, 'Gen');
      expect(reader.value.chapter, 2);
      expect(reader.previous(), isTrue);
      expect(reader.previous(), isFalse);
    });

    test('goTo opens a chapter and refuses one that does not exist', () async {
      packsPort.installed['en'] = _pack('en');
      await reader.load();
      expect(reader.goTo('Exod', 1), isTrue);
      expect(reader.value.verses.length, 2);
      expect(reader.goTo('Exod', 9), isFalse);
      expect(reader.goTo('Ps', 1), isFalse);
      expect(reader.value.book, 'Exod');
    });

    test('openRef opens the chapter and marks the verse', () async {
      packsPort.installed['en'] = _pack('en');
      await reader.load();
      expect(reader.openRef(VerseRef.parse('Gen.2.2')), isTrue);
      expect(reader.value.chapter, 2);
      expect(reader.value.focusVerse, 2);
      expect(reader.openRef(VerseRef.parse('Gen.2.9')), isFalse);
    });

    test('navigation before the Bible is open does nothing', () async {
      expect(reader.next(), isFalse);
      expect(reader.goTo('Gen', 1), isFalse);
      expect(reader.openRef(VerseRef.parse('Gen.1.1')), isFalse);
    });

    test('the place is remembered per language across a restart', () async {
      packsPort.installed['en'] = _pack('en');
      await reader.load();
      reader.goTo('Exod', 1);
      await _settle();
      final ReaderProvider again = make();
      await again.load();
      expect(again.value.book, 'Exod');
      again.dispose();
    });

    test('a saved place that no longer exists falls back to the first book', () async {
      storage.values[ReaderProvider.positionKey] = '{"en":{"book":"Rev","chapter":3}}';
      packsPort.installed['en'] = _pack('en');
      await reader.load();
      expect(reader.value.book, 'Gen');
    });

    test('a damaged saved place is ignored', () async {
      storage.values[ReaderProvider.positionKey] = 'not json';
      packsPort.installed['en'] = _pack('en');
      await reader.load();
      expect(reader.value.ready, isTrue);
    });

    test('search finds verses, and an empty query clears the results', () async {
      packsPort.installed['en'] = _pack('en');
      await reader.load();
      await reader.search('light');
      expect(reader.value.query, 'light');
      expect(reader.value.results.map((h) => h.ref.toString()), contains('Gen.1.3'));
      await reader.search('   ');
      expect(reader.value.query, isEmpty);
      expect(reader.value.results, isEmpty);
    });

    test('changing the reader language reloads that language', () async {
      packsPort.installed['en'] = _pack('en');
      packsPort.installed['es'] = _pack('es');
      await reader.load();
      locale.setReaderLanguage('es');
      await _settle();
      expect(reader.value.language, 'es');
      expect(reader.value.translationId, 'ES');
    });

    test('a language with no Bible shows the missing state and then opens once it installs', () async {
      locale.setReaderLanguage('es');
      await reader.load();
      expect(reader.value.status, ReaderStatus.missingPack);
      packsPort.installed['es'] = _pack('es');
      await packs.refresh();
      await _settle();
      expect(reader.value.ready, isTrue);
    });

    test('text size is clamped and saved with the settings', () async {
      reader.setTextScale(5);
      expect(settings.value.readerTextScale, 2.0);
      expect(reader.value.textScale, 2.0);
      reader.setTextScale(0.1);
      expect(settings.value.readerTextScale, 0.8);
    });

    test('the notice for the open Bible can be read', () async {
      packsPort.installed['en'] = _pack('en');
      packsPort.notices['en'] = 'public domain';
      await reader.load();
      expect(await reader.notice(), 'public domain');
    });
  });

  group('BookmarkProvider', () {
    late ProgressProvider progress;
    late BookmarkProvider marks;
    late DateTime now;

    setUp(() async {
      progress = ProgressProvider(ProgressStore(storage, log), log);
      await progress.load();
      now = DateTime.utc(2026, 11, 22, 10);
      marks = BookmarkProvider(progress, clock: () => now);
    });

    tearDown(() {
      marks.dispose();
      progress.dispose();
    });

    final VerseRef john = VerseRef.parse('John.3.16');
    final VerseRef psalm = VerseRef.parse('Ps.23.1');

    test('toggling adds a bookmark and toggling again removes it', () async {
      expect(marks.toggleBookmark(john, 'en'), isTrue);
      expect(marks.value.isBookmarked(john, 'en'), isTrue);
      expect(marks.value.isBookmarked(john, 'es'), isFalse);
      expect(marks.toggleBookmark(john, 'en'), isFalse);
      expect(marks.value.bookmarks, isEmpty);
      await progress.flush();
    });

    test('bookmarks are listed newest first and saved with the career', () async {
      marks.toggleBookmark(john, 'en');
      now = now.add(const Duration(minutes: 5));
      marks.toggleBookmark(psalm, 'en');
      expect(marks.value.bookmarks.first.ref, psalm);
      await progress.flush();
      final ProgressProvider again = ProgressProvider(ProgressStore(storage, log), log);
      await again.load();
      expect(again.progress.bookmarks.length, 2);
      again.dispose();
    });

    test('a highlight is set, recoloured, and removed by choosing its colour again', () async {
      marks.setHighlight(john, 'en', HighlightColor.sun);
      expect(marks.value.highlightOf(john, 'en'), HighlightColor.sun);
      marks.setHighlight(john, 'en', HighlightColor.sky);
      expect(marks.value.highlightOf(john, 'en'), HighlightColor.sky);
      expect(marks.value.highlights.length, 1);
      marks.setHighlight(john, 'en', HighlightColor.sky);
      expect(marks.value.highlightOf(john, 'en'), isNull);
      marks.setHighlight(john, 'en', HighlightColor.leaf);
      marks.setHighlight(john, 'en', null);
      expect(marks.value.highlights, isEmpty);
      await progress.flush();
    });

    test('changes to the career from elsewhere show up', () {
      progress.update((Progress p) => p.copyWith(bookmarks: <Bookmark>[
            Bookmark(ref: john, language: 'de', createdAt: now),
          ]));
      expect(marks.value.isBookmarked(john, 'de'), isTrue);
    });
  });
}
