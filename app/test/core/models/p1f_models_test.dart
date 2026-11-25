import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/catalog/achievement_catalog.dart';
import 'package:tehillah/core/models/achievement_def.dart';
import 'package:tehillah/core/models/bible_book.dart';
import 'package:tehillah/core/models/bible_pack.dart';
import 'package:tehillah/core/models/bookmark.dart';
import 'package:tehillah/core/models/curated_verse.dart';
import 'package:tehillah/core/models/daily_challenge.dart';
import 'package:tehillah/core/models/keeper_profile.dart';
import 'package:tehillah/core/models/language_codes.dart';
import 'package:tehillah/core/models/license_notice.dart';
import 'package:tehillah/core/models/loadout.dart';
import 'package:tehillah/core/models/opponent_def.dart';
import 'package:tehillah/core/models/pack_manifest.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/models/progress_stats.dart';
import 'package:tehillah/core/models/settings_model.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/verse.dart';
import 'package:tehillah/core/models/verse_ref.dart';

Map<String, Object?> viaJson(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;

final String sha = 'a' * 64;

OpponentDef opponent() => OpponentDef(
      id: 's01r1',
      name: 'Tobin Ashgrove',
      team: 'Eden Rovers',
      keeper: KeeperProfile(
        reaction: 0.4,
        reach: 0.5,
        habitReading: 0,
        tendency: <KeeperDive, double>{
          for (final KeeperDive d in KeeperDive.values) d: 1 / 6,
        },
      ),
    );

void main() {
  group('VerseRef', () {
    test('there are 66 unique books', () {
      expect(osisBookIds, hasLength(66));
      expect(osisBookIds.toSet(), hasLength(66));
      expect(osisBookIds.first, 'Gen');
      expect(osisBookIds.last, 'Rev');
    });

    test('parses, prints and round-trips', () {
      final VerseRef r = VerseRef.parse('Ps.23.1');
      expect(r, const VerseRef('Ps', 23, 1));
      expect(r.toString(), 'Ps.23.1');
      expect(VerseRef.fromJson(viaJson(r.toJson())), r);
      expect(VerseRef.parse('1John.4.8').book, '1John');
    });

    test('rejects malformed references', () {
      for (final String bad in <String>['', 'Ps.23', 'Ps.0.1', 'Ps.1.0', 'Foo.1.1', 'Ps.a.1', 'Ps.1.1.1']) {
        expect(() => VerseRef.parse(bad), throwsFormatException, reason: bad);
      }
    });

    test('sorts in canonical order', () {
      final List<VerseRef> refs = <VerseRef>[
        VerseRef.parse('Matt.1.1'),
        VerseRef.parse('Ps.23.2'),
        VerseRef.parse('Gen.1.1'),
        VerseRef.parse('Ps.23.1'),
        VerseRef.parse('Ps.9.1'),
      ]..sort();
      expect(refs.map((VerseRef r) => r.toString()), <String>[
        'Gen.1.1', 'Ps.9.1', 'Ps.23.1', 'Ps.23.2', 'Matt.1.1',
      ]);
    });
  });

  group('LanguageCodes', () {
    test('eleven languages, two right-to-left', () {
      expect(LanguageCodes.all, hasLength(11));
      expect(LanguageCodes.rightToLeft, <String>{'ar', 'he'});
      expect(LanguageCodes.isSupported('pt_BR'), isTrue);
      expect(LanguageCodes.isSupported('pt'), isFalse);
    });
  });

  group('Verse and CuratedVerse', () {
    test('verse round-trips and rejects an unsupported language', () {
      final Verse v = Verse(
        ref: VerseRef.parse('Ps.23.1'), text: 'The LORD is my shepherd',
        language: 'en', translationId: 'BSB',
      );
      expect(Verse.fromJson(viaJson(v.toJson())), v);
      final Map<String, Object?> bad = v.toJson()..['language'] = 'xx';
      expect(() => Verse.fromJson(bad), throwsFormatException);
    });

    test('curated verse keeps its moments and round-trips', () {
      final CuratedVerse c = CuratedVerse(
        id: 'cv001', ref: VerseRef.parse('Ps.46.10'),
        moments: <VerseMoment>{VerseMoment.selah, VerseMoment.miss},
      );
      expect(c.suits(VerseMoment.selah), isTrue);
      expect(c.suits(VerseMoment.win), isFalse);
      final CuratedVerse back = CuratedVerse.fromJson(viaJson(c.toJson()));
      expect(back, c);
      expect(back.hashCode, c.hashCode);
    });

    test('a curated verse without moments is rejected', () {
      expect(
        () => CuratedVerse.fromJson(<String, Object?>{
          'id': 'x', 'ref': 'Ps.1.1', 'moments': <Object?>[],
        }),
        throwsFormatException,
      );
    });
  });

  group('BibleBook and BiblePack', () {
    final Map<String, Object?> packJson = <String, Object?>{
      'schemaVersion': 1,
      'language': 'en',
      'translationId': 'BSB',
      'source': 'Berean Standard Bible',
      'license': 'Public domain',
      'books': <String, Object?>{
        'Ps': <Object?>[
          <Object?>['one', 'two', 'three'],
          <Object?>['four', 'five'],
        ],
        'Gen': <Object?>[
          <Object?>['in the beginning'],
        ],
      },
    };

    test('book counts verses per chapter', () {
      final BibleBook b = BibleBook(osisId: 'Ps', chapterVerseCounts: <int>[3, 2]);
      expect(b.chapters, 2);
      expect(b.versesIn(1), 3);
      expect(b.versesIn(3), 0);
      expect(b.versesIn(0), 0);
      expect(b.order, osisBookIds.indexOf('Ps'));
      expect(BibleBook.fromJson(viaJson(b.toJson())), b);
    });

    test('pack looks up verses by the pack numbering', () {
      final BiblePack p = BiblePack.fromJson(packJson);
      expect(p.verse('Ps', 1, 3), 'three');
      expect(p.verse('Ps', 2, 1), 'four');
      expect(p.verse('Ps', 2, 3), isNull);
      expect(p.verse('Ps', 3, 1), isNull);
      expect(p.verse('Ps', 1, 0), isNull);
      expect(p.verse('Matt', 1, 1), isNull);
      expect(p.hasBook('Gen'), isTrue);
      expect(p.chapter('Ps', 2), <String>['four', 'five']);
    });

    test('books come back in canonical order with counts', () {
      final List<BibleBook> books = BiblePack.fromJson(packJson).books;
      expect(books.map((BibleBook b) => b.osisId), <String>['Gen', 'Ps']);
      expect(books.last.chapterVerseCounts, <int>[3, 2]);
    });

    test('pack round-trips through JSON', () {
      final BiblePack p = BiblePack.fromJson(packJson);
      final BiblePack back = BiblePack.fromJson(viaJson(p.toJson()));
      expect(back.verse('Ps', 1, 1), 'one');
      expect(back.language, 'en');
      expect(back.license, 'Public domain');
    });

    test('bad packs are rejected', () {
      Map<String, Object?> with_(String key, Object? value) =>
          <String, Object?>{...packJson, key: value};
      expect(() => BiblePack.fromJson(with_('schemaVersion', 2)), throwsFormatException);
      expect(() => BiblePack.fromJson(with_('language', 'xx')), throwsFormatException);
      expect(() => BiblePack.fromJson(with_('books', <String, Object?>{})), throwsFormatException);
      expect(
        () => BiblePack.fromJson(with_('books', <String, Object?>{'Foo': <Object?>[<Object?>['a']]})),
        throwsFormatException,
      );
      expect(
        () => BiblePack.fromJson(with_('books', <String, Object?>{'Ps': <Object?>[<Object?>[1]]})),
        throwsFormatException,
      );
    });
  });

  group('PackManifest', () {
    Map<String, Object?> entry(String lang) => <String, Object?>{
          'language': lang,
          'translationId': 'BSB',
          'version': 1,
          'url': 'en-1.json.gz',
          'bytes': 1234,
          'sha256': sha,
          'noticePath': 'notices/en.txt',
        };

    test('round-trips and finds a language', () {
      final PackManifest m = PackManifest.fromJson(<String, Object?>{
        'schemaVersion': 1,
        'packs': <Object?>[entry('en'), entry('es')],
      });
      expect(PackManifest.fromJson(viaJson(m.toJson())), m);
      expect(m.forLanguage('es')!.language, 'es');
      expect(m.forLanguage('de'), isNull);
    });

    test('rejects a bad hash, a duplicate language and a bad size', () {
      expect(
        () => PackManifestEntry.fromJson(<String, Object?>{...entry('en'), 'sha256': 'ABC'}),
        throwsFormatException,
      );
      expect(
        () => PackManifestEntry.fromJson(<String, Object?>{...entry('en'), 'bytes': 0}),
        throwsFormatException,
      );
      expect(
        () => PackManifest.fromJson(<String, Object?>{
          'schemaVersion': 1,
          'packs': <Object?>[entry('en'), entry('en')],
        }),
        throwsFormatException,
      );
    });
  });

  group('Bookmark and Highlight', () {
    final DateTime t = DateTime.utc(2026, 11, 19, 10, 30);

    test('bookmark round-trips and keeps UTC', () {
      final Bookmark b = Bookmark(ref: VerseRef.parse('Ps.23.1'), language: 'en', createdAt: t);
      final Bookmark back = Bookmark.fromJson(viaJson(b.toJson()));
      expect(back, b);
      expect(back.createdAt.isUtc, isTrue);
      expect(Bookmark(ref: b.ref, language: 'en', createdAt: t.toLocal()), b);
    });

    test('highlight round-trips and recolors', () {
      final Highlight h = Highlight(
        ref: VerseRef.parse('John.3.16'), language: 'es', color: HighlightColor.sky, createdAt: t,
      );
      expect(Highlight.fromJson(viaJson(h.toJson())), h);
      final Highlight rose = h.copyWith(color: HighlightColor.rose);
      expect(rose.color, HighlightColor.rose);
      expect(rose.createdAt, h.createdAt);
      expect(rose, isNot(h));
    });

    test('bad language and bad date are rejected', () {
      final Map<String, Object?> json = Bookmark(
        ref: VerseRef.parse('Ps.1.1'), language: 'en', createdAt: t,
      ).toJson();
      expect(() => Bookmark.fromJson(<String, Object?>{...json, 'language': 'xx'}), throwsFormatException);
      expect(() => Bookmark.fromJson(<String, Object?>{...json, 'createdAt': 'yesterday'}), throwsFormatException);
    });
  });

  group('LicenseNotice', () {
    test('round-trips with and without a link', () {
      const LicenseNotice a = LicenseNotice(
        id: 'pt', title: 'Bíblia Livre', license: 'CC BY 4.0', attribution: 'Bíblia Livre (BLIVRE)',
        link: 'https://creativecommons.org/licenses/by/4.0/',
      );
      const LicenseNotice b = LicenseNotice(id: 'x', title: 'X', license: 'MIT', attribution: 'X');
      expect(LicenseNotice.fromJson(viaJson(a.toJson())), a);
      expect(LicenseNotice.fromJson(viaJson(b.toJson())), b);
    });

    test('a non-https link is rejected', () {
      expect(
        () => LicenseNotice.fromJson(<String, Object?>{
          'id': 'x', 'title': 'X', 'license': 'MIT', 'attribution': 'X', 'link': 'http://x.org',
        }),
        throwsFormatException,
      );
    });
  });

  group('Achievements', () {
    test('catalog has nine unique fruit achievements', () {
      expect(AchievementCatalog.all, hasLength(9));
      expect(AchievementCatalog.all.map((AchievementDef a) => a.id).toSet(), hasLength(9));
      expect(AchievementCatalog.byId('selfControl')!.threshold, 9);
      expect(AchievementCatalog.byId('selfControl')!.rule, AchievementRule.goalStreak);
      expect(AchievementCatalog.byId('nope'), isNull);
    });

    test('definition round-trips', () {
      for (final AchievementDef a in AchievementCatalog.all) {
        expect(AchievementDef.fromJson(viaJson(a.toJson())), a);
      }
    });
  });

  group('DailyChallenge and DailyRecord', () {
    test('challenge round-trips', () {
      final DailyChallenge c = DailyChallenge(
        dateKey: '2026-11-19', seed: 99, opponent: opponent(), difficulty: 0.5, wind: -0.2,
      );
      expect(DailyChallenge.fromJson(viaJson(c.toJson())), c);
      expect(c.kicksPerSide, 5);
    });

    test('record round-trips and the date key is checked', () {
      const DailyRecord r = DailyRecord(dateKey: '2026-11-19', won: true, goals: 4);
      expect(DailyRecord.fromJson(viaJson(r.toJson())), r);
      expect(
        () => DailyRecord.fromJson(<String, Object?>{'dateKey': '19/11/2026', 'won': true, 'goals': 1}),
        throwsFormatException,
      );
    });
  });

  group('SettingsModel', () {
    test('defaults', () {
      const SettingsModel s = SettingsModel();
      expect(s.themeChoice, ThemeChoice.system);
      expect(s.inputScheme, InputScheme.flick);
      expect(s.appLocale, isNull);
      expect(s.readerLocale, 'en');
      expect(s.remindersOn, isFalse);
      expect(s.reminderMinuteOfDay, 1080);
      expect(s.packWifiOnly, isTrue);
    });

    test('round-trips every field', () {
      const SettingsModel s = SettingsModel(
        themeChoice: ThemeChoice.dark, readerTheme: ReaderTheme.sepia, appLocale: 'ar',
        readerLocale: 'he', inputScheme: InputScheme.timingBar, soundOn: false, musicOn: false,
        hapticsOn: false, remindersOn: true, reminderMinuteOfDay: 450, readerTextScale: 1.4,
        packWifiOnly: false,
      );
      final SettingsModel back = SettingsModel.fromJson(viaJson(s.toJson()));
      expect(back, s);
      expect(back.hashCode, s.hashCode);
    });

    test('a bad or missing field falls back to its default, the rest is kept', () {
      final SettingsModel s = SettingsModel.fromJson(<String, Object?>{
        'themeChoice': 'neon',
        'appLocale': 'xx',
        'readerLocale': 42,
        'readerTextScale': 9,
        'reminderMinuteOfDay': 2000,
        'soundOn': 'yes',
        'hapticsOn': false,
      });
      expect(s.themeChoice, ThemeChoice.system);
      expect(s.appLocale, isNull);
      expect(s.readerLocale, 'en');
      expect(s.readerTextScale, 1.0);
      expect(s.reminderMinuteOfDay, 1080);
      expect(s.soundOn, isTrue);
      expect(s.hapticsOn, isFalse);
      expect(SettingsModel.fromJson(<String, Object?>{}), const SettingsModel());
    });

    test('copyWith can switch back to the device language', () {
      const SettingsModel s = SettingsModel(appLocale: 'de');
      expect(s.copyWith(readerTheme: ReaderTheme.dark).appLocale, 'de');
      expect(s.copyWith(followDeviceLanguage: true).appLocale, isNull);
      expect(s.copyWith(appLocale: 'fr').appLocale, 'fr');
    });
  });

  group('ProgressStats', () {
    test('round-trips; missing fields read as zero', () {
      const ProgressStats s = ProgressStats(matchesPlayed: 3, goals: 9, bestGoalStreak: 4);
      expect(ProgressStats.fromJson(viaJson(s.toJson())), s);
      expect(ProgressStats.fromJson(<String, Object?>{}), const ProgressStats());
      expect(s.copyWith(goals: 10).goals, 10);
      expect(
        () => ProgressStats.fromJson(<String, Object?>{'goals': -1}),
        throwsFormatException,
      );
    });
  });

  group('Progress', () {
    Progress full() => Progress(
          matchStars: <String, int>{'s02r1': 2, 's01r1': 3},
          lamps: <int>{2, 1},
          announcedUnlocks: <String>{'joy'},
          achievements: <String>{'love'},
          dailyHistory: <String, DailyRecord>{
            '2026-11-19': const DailyRecord(dateKey: '2026-11-19', won: true, goals: 4),
          },
          bookmarks: <Bookmark>[
            Bookmark(ref: VerseRef.parse('Ps.23.1'), language: 'en', createdAt: DateTime.utc(2026, 11, 19)),
          ],
          highlights: <Highlight>[
            Highlight(
              ref: VerseRef.parse('Ps.23.2'), language: 'en',
              color: HighlightColor.leaf, createdAt: DateTime.utc(2026, 11, 19),
            ),
          ],
          loadout: const Loadout(ballId: 'joy', gearId: 'beltOfTruth'),
          stats: const ProgressStats(matchesPlayed: 5, matchesWon: 4),
          sessions: 3,
          ratingPromptShown: true,
          sevenDaysStart: '2026-11-18',
          sevenDaysDone: <int>{1, 2},
        );

    test('an empty career is the baseline', () {
      final Progress p = Progress.empty();
      expect(p.schemaVersion, Progress.currentSchemaVersion);
      expect(p.totalStars, 0);
      expect(p.starsFor('s01r1'), 0);
      expect(p.loadout, Loadout.starter);
      expect(p.sessions, 0);
      expect(Progress.fromJson(viaJson(p.toJson())), p);
    });

    test('round-trips with everything set', () {
      final Progress p = full();
      final Progress back = Progress.fromJson(viaJson(p.toJson()));
      expect(back, p);
      expect(back.hashCode, p.hashCode);
      expect(back.totalStars, 5);
      expect(back.starsFor('s02r1'), 2);
    });

    test('the saved form is canonical (sorted)', () {
      final Map<String, Object?> j = full().toJson();
      expect((j['matchStars']! as Map<String, Object?>).keys.toList(), <String>['s01r1', 's02r1']);
      expect(j['lamps'], <int>[1, 2]);
    });

    test('collections are read-only', () {
      final Progress p = full();
      expect(() => p.lamps.add(3), throwsUnsupportedError);
      expect(() => p.matchStars['x'] = 1, throwsUnsupportedError);
      expect(() => p.bookmarks.clear(), throwsUnsupportedError);
    });

    test('older files with missing fields still load', () {
      final Progress p = Progress.fromJson(<String, Object?>{'schemaVersion': 1});
      expect(p.schemaVersion, 1);
      expect(p.copyWith(schemaVersion: Progress.currentSchemaVersion), Progress.empty());
    });

    test('a newer schema number is carried through for the codec to decide', () {
      expect(Progress.fromJson(<String, Object?>{'schemaVersion': 7}).schemaVersion, 7);
    });

    test('corrupt data is rejected', () {
      Map<String, Object?> base() => viaJson(full().toJson());
      expect(() => Progress.fromJson(<String, Object?>{}), throwsFormatException);
      expect(() => Progress.fromJson(base()..['matchStars'] = <String, Object?>{'a': 4}), throwsFormatException);
      expect(() => Progress.fromJson(base()..['lamps'] = <Object?>['x']), throwsFormatException);
      expect(() => Progress.fromJson(base()..['sevenDaysDone'] = <Object?>[9]), throwsFormatException);
      expect(() => Progress.fromJson(base()..['bookmarks'] = 'no'), throwsFormatException);
      expect(
        () => Progress.fromJson(base()
          ..['dailyHistory'] = <String, Object?>{
            '2026-11-20': const DailyRecord(dateKey: '2026-11-19', won: true, goals: 1).toJson(),
          }),
        throwsFormatException,
      );
    });

    test('copyWith changes one part and can clear Seven Days', () {
      final Progress p = full();
      final Progress q = p.copyWith(sessions: 4);
      expect(q.sessions, 4);
      expect(q.lamps, p.lamps);
      expect(q, isNot(p));
      final Progress cleared = p.copyWith(clearSevenDays: true);
      expect(cleared.sevenDaysStart, isNull);
      expect(cleared.sevenDaysDone, isEmpty);
    });
  });
}
