import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/models/bible_pack.dart';
import 'package:tehillah/core/models/curated_verse.dart';
import 'package:tehillah/core/models/language_codes.dart';
import 'package:tehillah/core/models/verse.dart';
import 'package:tehillah/core/models/verse_ref.dart';
import 'package:tehillah/core/verses/reader_index.dart';
import 'package:tehillah/core/verses/verse_repository.dart';

String _curated(List<Map<String, Object?>> verses) =>
    jsonEncode(<String, Object?>{'schemaVersion': 1, 'verses': verses});

String _texts(String language, Map<String, String> texts) => jsonEncode(<String, Object?>{
      'schemaVersion': 1,
      'language': language,
      'translationId': language.toUpperCase(),
      'texts': texts,
    });

final List<Map<String, Object?>> _sample = <Map<String, Object?>>[
  <String, Object?>{'id': 'ps_46_10', 'ref': 'Ps.46.10', 'moments': <String>['selah', 'daily']},
  <String, Object?>{'id': 'gen_1_1', 'ref': 'Gen.1.1', 'moments': <String>['daily']},
  <String, Object?>{'id': 'john_3_16', 'ref': 'John.3.16', 'moments': <String>['win', 'daily']},
];

VerseRepository _repo() => VerseRepository.parse(
      curatedJson: _curated(_sample),
      textJsonByLanguage: <String, String>{
        'en': _texts('en', <String, String>{'ps_46_10': 'Be still', 'gen_1_1': 'In the beginning', 'john_3_16': 'For God so loved'}),
        'es': _texts('es', <String, String>{'ps_46_10': 'Estad quietos', 'gen_1_1': 'En el principio', 'john_3_16': 'Porque de tal manera'}),
      },
    );

BiblePack _pack(String language, Map<String, List<List<String>>> books) => BiblePack.fromJson(
      <String, Object?>{
        'schemaVersion': 1,
        'language': language,
        'translationId': 'T',
        'source': 's',
        'license': 'l',
        'books': books,
      },
    );

void main() {
  group('VerseRepository', () {
    test('serves a verse by id and by canonical reference', () {
      final VerseRepository repo = _repo();
      expect(repo.byId('ps_46_10', 'es')!.text, 'Estad quietos');
      expect(repo.byRef(VerseRef.parse('Gen.1.1'), 'en')!.text, 'In the beginning');
      expect(repo.byId('nope', 'en'), isNull);
      expect(repo.byId('gen_1_1', 'fr'), isNull);
    });

    test('verses are kept in canonical order', () {
      final List<String> ids = _repo().verses.map((CuratedVerse v) => v.id).toList();
      expect(ids, <String>['gen_1_1', 'ps_46_10', 'john_3_16']);
    });

    test('forMoment is deterministic for a seed and only returns fitting verses', () {
      final VerseRepository repo = _repo();
      final Verse? a = repo.forMoment(VerseMoment.daily, 'en', seed: 42);
      final Verse? b = repo.forMoment(VerseMoment.daily, 'en', seed: 42);
      expect(a, b);
      expect(repo.forMoment(VerseMoment.selah, 'en', seed: 1)!.ref.toString(), 'Ps.46.10');
      expect(repo.forMoment(VerseMoment.miss, 'en', seed: 1), isNull);
      expect(repo.forMoment(VerseMoment.daily, 'fr', seed: 1), isNull);
    });

    test('recent verses are skipped unless nothing else fits', () {
      final VerseRepository repo = _repo();
      for (int seed = 0; seed < 40; seed++) {
        final Verse v = repo.forMoment(
          VerseMoment.daily,
          'en',
          seed: seed,
          recent: <String>{'gen_1_1', 'ps_46_10'},
        )!;
        expect(v.ref.toString(), 'John.3.16');
      }
      expect(
        repo.forMoment(VerseMoment.selah, 'en', seed: 1, recent: <String>{'ps_46_10'})!.ref.toString(),
        'Ps.46.10',
      );
    });

    test('every verse is reachable for some seed', () {
      final Set<String> seen = <String>{
        for (int seed = 0; seed < 200; seed++)
          _repo().forMoment(VerseMoment.daily, 'en', seed: seed)!.ref.toString(),
      };
      expect(seen.length, 3);
    });

    test('the library lists a language in canonical order, optionally by moment', () {
      final VerseRepository repo = _repo();
      expect(repo.library('en').map((Verse v) => v.ref.toString()), <String>['Gen.1.1', 'Ps.46.10', 'John.3.16']);
      expect(repo.library('en', moment: VerseMoment.win).length, 1);
      expect(repo.library('fr'), isEmpty);
    });

    test('a damaged bundle is rejected', () {
      expect(
        () => VerseRepository.parse(
          curatedJson: _curated(_sample),
          textJsonByLanguage: <String, String>{
            'en': _texts('en', <String, String>{'ps_46_10': 'x', 'gen_1_1': 'y'}),
          },
        ),
        throwsFormatException,
        reason: 'missing text',
      );
      expect(
        () => VerseRepository.parse(
          curatedJson: _curated(_sample),
          textJsonByLanguage: <String, String>{
            'en': _texts('en', <String, String>{'ps_46_10': 'x', 'gen_1_1': 'y', 'john_3_16': 'z', 'extra': 'q'}),
          },
        ),
        throwsFormatException,
        reason: 'unknown id',
      );
      expect(
        () => VerseRepository.parse(
          curatedJson: _curated(_sample),
          textJsonByLanguage: <String, String>{'es': _texts('en', <String, String>{})},
        ),
        throwsFormatException,
        reason: 'wrong language',
      );
      expect(
        () => VerseRepository.parse(
          curatedJson: _curated(<Map<String, Object?>>[_sample.first, _sample.first]),
          textJsonByLanguage: const <String, String>{},
        ),
        throwsFormatException,
        reason: 'duplicate id',
      );
    });

    test('the real bundled assets parse and cover every language', () {
      final Map<String, String> byLanguage = <String, String>{
        for (final String lang in LanguageCodes.all)
          lang: File('assets/verses/$lang.json').readAsStringSync(),
      };
      final VerseRepository repo = VerseRepository.parse(
        curatedJson: File('assets/verses/curated.json').readAsStringSync(),
        textJsonByLanguage: byLanguage,
      );
      expect(repo.verses.length, 169);
      for (final String lang in LanguageCodes.all) {
        expect(repo.library(lang).length, 169, reason: lang);
        for (final VerseMoment m in VerseMoment.values) {
          expect(repo.forMoment(m, lang, seed: 7), isNotNull, reason: '$lang $m');
        }
      }
    });
  });

  group('SearchText', () {
    test('folds case and accents', () {
      expect(SearchText.fold('Éternel À Œuvre Straße'), 'eternel a oeuvre strasse');
    });

    test('removes Hebrew and Arabic vowel marks', () {
      expect(SearchText.fold('בְּרֵאשִׁית'), 'בראשית');
      expect(SearchText.fold('اللَّهُ'), 'الله');
    });

    test('splits words and cuts CJK runs into pairs', () {
      expect(SearchText.terms('love, joy 2'), <String>['love', 'joy', '2']);
      expect(SearchText.terms('神は愛'), <String>['神は', 'は愛']);
      expect(SearchText.terms('a 愛 b'), <String>['a', '愛', 'b']);
    });
  });

  group('ReaderIndex', () {
    final BiblePack en = _pack('en', <String, List<List<String>>>{
      'Gen': <List<String>>[
        <String>['In the beginning God created the heavens and the earth.', 'The earth was without form.'],
      ],
      'John': <List<String>>[
        <String>['In the beginning was the Word.'],
        <String>['', 'Jesus wept.'],
      ],
    });
    final ReaderIndex index = ReaderIndex.build(en);

    test('skips empty verses', () => expect(index.verseCount, 4));

    test('finds verses with every word, in canonical order', () {
      final List<SearchHit> hits = index.search('beginning word');
      expect(hits.map((SearchHit h) => h.ref.toString()), <String>['John.1.1']);
      final List<SearchHit> two = index.search('in the beginning');
      expect(two.map((SearchHit h) => h.ref.toString()), <String>['Gen.1.1', 'John.1.1']);
    });

    test('matches word starts from three letters', () {
      expect(index.search('creat').map((SearchHit h) => h.ref.toString()), <String>['Gen.1.1']);
      expect(index.search('be').length, 0);
    });

    test('is case and accent insensitive and ignores empty queries', () {
      expect(index.search('JESUS').length, 1);
      expect(index.search('   '), isEmpty);
      expect(index.search('zzzz'), isEmpty);
    });

    test('respects the limit', () {
      expect(index.search('the', limit: 2).length, 2);
      expect(index.search('the', limit: 0), isEmpty);
    });

    test('searches Japanese by pairs and verifies adjacency', () {
      final ReaderIndex ja = ReaderIndex.build(_pack('ja', <String, List<List<String>>>{
        'Gen': <List<String>>[
          <String>['初めに神は天と地とを創造された。', '地は形なく、むなしく。'],
        ],
        'John': <List<String>>[
          <String>['神は愛である。'],
        ],
      }));
      expect(ja.search('神は').map((SearchHit h) => h.ref.toString()), <String>['Gen.1.1', 'John.1.1']);
      expect(ja.search('愛').map((SearchHit h) => h.ref.toString()), <String>['John.1.1']);
      expect(ja.search('天地'), isEmpty, reason: 'pairs 天地 never occur adjacent');
    });

    test('searches Hebrew without vowel marks', () {
      final ReaderIndex he = ReaderIndex.build(_pack('he', <String, List<List<String>>>{
        'Gen': <List<String>>[
          <String>['בְּרֵאשִׁית בָּרָא אֱלֹהִים'],
        ],
      }));
      expect(he.search('ברא').length, 1);
    });

    test('a full-size Bible is searched quickly', () {
      final List<List<String>> chapters = <List<String>>[
        for (int c = 0; c < 1000; c++)
          <String>[for (int v = 0; v < 31; v++) 'word$c verse$v common text with grace and peace'],
      ];
      final ReaderIndex big = ReaderIndex.build(
        _pack('en', <String, List<List<String>>>{'Ps': chapters}),
      );
      expect(big.verseCount, 31000);
      final Stopwatch watch = Stopwatch()..start();
      final List<SearchHit> hits = big.search('grace peace word999');
      watch.stop();
      expect(hits.length, 31);
      expect(watch.elapsedMilliseconds, lessThan(250));
    });
  });
}
