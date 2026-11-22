import 'dart:convert';

import 'package:tehillah/core/logic/seeded_rng.dart';
import 'package:tehillah/core/models/curated_verse.dart';
import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/language_codes.dart';
import 'package:tehillah/core/models/verse.dart';
import 'package:tehillah/core/models/verse_ref.dart';

/// The bundled curated verses: `curated.json` (id, ref, moments) plus one
/// `{lang}.json` per language (id to text). Works fully offline.
final class VerseRepository {
  VerseRepository._(this._verses, this._byId, this._texts, this._translationIds);

  /// Parses the asset files. Throws [FormatException] if any file is damaged,
  /// if a language lacks a text for any curated verse, or if a language file
  /// carries an id that is not curated, so a bad bundle fails in tests and
  /// never reaches a verse card.
  factory VerseRepository.parse({
    required String curatedJson,
    required Map<String, String> textJsonByLanguage,
  }) {
    final Map<String, Object?> curated = jsonMap(jsonDecode(curatedJson), 'curated.json');
    readInt(curated, 'schemaVersion', min: 1, max: 1);
    final List<CuratedVerse> verses = <CuratedVerse>[
      for (final Object? item in jsonList(curated['verses'], 'verses'))
        CuratedVerse.fromJson(jsonMap(item, 'verse')),
    ];
    if (verses.isEmpty) {
      throw const FormatException('no curated verses');
    }
    final Map<String, CuratedVerse> byId = <String, CuratedVerse>{};
    for (final CuratedVerse v in verses) {
      if (byId.containsKey(v.id)) {
        throw FormatException('duplicate verse id "${v.id}"');
      }
      byId[v.id] = v;
    }
    final Map<String, Map<String, String>> texts = <String, Map<String, String>>{};
    final Map<String, String> translations = <String, String>{};
    for (final MapEntry<String, String> entry in textJsonByLanguage.entries) {
      if (!LanguageCodes.isSupported(entry.key)) {
        throw FormatException('unsupported language "${entry.key}"');
      }
      final Map<String, Object?> file = jsonMap(jsonDecode(entry.value), '${entry.key}.json');
      readInt(file, 'schemaVersion', min: 1, max: 1);
      if (readString(file, 'language') != entry.key) {
        throw FormatException('${entry.key}.json is for another language');
      }
      translations[entry.key] = readString(file, 'translationId');
      final Map<String, Object?> raw = jsonMap(file['texts'], 'texts');
      final Map<String, String> map = <String, String>{};
      for (final MapEntry<String, Object?> t in raw.entries) {
        if (!byId.containsKey(t.key)) {
          throw FormatException('${entry.key}.json has unknown verse "${t.key}"');
        }
        final Object? text = t.value;
        if (text is! String || text.trim().isEmpty) {
          throw FormatException('${entry.key}.json has an empty text for "${t.key}"');
        }
        map[t.key] = text;
      }
      for (final String id in byId.keys) {
        if (!map.containsKey(id)) {
          throw FormatException('${entry.key}.json lacks "$id"');
        }
      }
      texts[entry.key] = map;
    }
    final List<CuratedVerse> ordered = List<CuratedVerse>.of(verses)
      ..sort((CuratedVerse a, CuratedVerse b) => a.ref.compareTo(b.ref));
    return VerseRepository._(
      List<CuratedVerse>.unmodifiable(ordered),
      Map<String, CuratedVerse>.unmodifiable(byId),
      texts,
      translations,
    );
  }

  final List<CuratedVerse> _verses;
  final Map<String, CuratedVerse> _byId;
  final Map<String, Map<String, String>> _texts;
  final Map<String, String> _translationIds;

  /// Every curated verse in canonical order.
  List<CuratedVerse> get verses => _verses;

  bool hasLanguage(String language) => _texts.containsKey(language);

  Verse? _build(CuratedVerse v, String language) {
    final String? text = _texts[language]?[v.id];
    if (text == null) {
      return null;
    }
    return Verse(
      ref: v.ref,
      text: text,
      language: language,
      translationId: _translationIds[language]!,
    );
  }

  Verse? byId(String id, String language) {
    final CuratedVerse? v = _byId[id];
    return v == null ? null : _build(v, language);
  }

  /// The curated id of a reference, or null if it is not a curated verse.
  String? idFor(VerseRef ref) {
    for (final CuratedVerse v in _verses) {
      if (v.ref == ref) {
        return v.id;
      }
    }
    return null;
  }

  Verse? byRef(VerseRef ref, String language) {
    for (final CuratedVerse v in _verses) {
      if (v.ref == ref) {
        return _build(v, language);
      }
    }
    return null;
  }

  /// One verse for a game moment. The same seed always gives the same verse, so
  /// a Daily Bread card is identical for everyone that day. Ids in [recent] are
  /// skipped unless that would leave nothing to show.
  Verse? forMoment(
    VerseMoment moment,
    String language, {
    required int seed,
    Set<String> recent = const <String>{},
  }) {
    if (!hasLanguage(language)) {
      return null;
    }
    List<CuratedVerse> pool = <CuratedVerse>[
      for (final CuratedVerse v in _verses)
        if (v.suits(moment)) v,
    ]..sort((CuratedVerse a, CuratedVerse b) => a.id.compareTo(b.id));
    if (pool.isEmpty) {
      return null;
    }
    final List<CuratedVerse> fresh = <CuratedVerse>[
      for (final CuratedVerse v in pool)
        if (!recent.contains(v.id)) v,
    ];
    if (fresh.isNotEmpty) {
      pool = fresh;
    }
    final int index = SeededRng(seed).fork('verse:${moment.name}').nextInt(pool.length);
    return _build(pool[index], language);
  }

  /// The Verse library list in canonical order, optionally for one moment.
  List<Verse> library(String language, {VerseMoment? moment}) {
    return <Verse>[
      for (final CuratedVerse v in _verses)
        if (moment == null || v.suits(moment))
          if (_build(v, language) case final Verse built) built,
    ];
  }
}
