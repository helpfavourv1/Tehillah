import 'package:tehillah/core/models/bible_book.dart';
import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/language_codes.dart';
import 'package:tehillah/core/models/verse_ref.dart';

/// A downloaded Bible for one language. The file shape is
/// `{schemaVersion, language, translationId, source, license, books}` where
/// `books` maps an OSIS id to a list of chapters, each a list of verse strings
/// (verse 1 is index 0). Verse numbers here are the language's own numbering.
final class BiblePack {
  BiblePack._({
    required this.schemaVersion,
    required this.language,
    required this.translationId,
    required this.source,
    required this.license,
    required Map<String, List<List<String>>> books,
  }) : _books = books;

  static const int currentSchemaVersion = 1;

  factory BiblePack.fromJson(Map<String, Object?> json) {
    final int schema = readInt(json, 'schemaVersion', min: 1);
    if (schema > currentSchemaVersion) {
      throw FormatException('pack schema $schema is newer than this app understands');
    }
    final String language = readString(json, 'language');
    if (!LanguageCodes.isSupported(language)) {
      throw FormatException('unsupported language "$language"');
    }
    final Map<String, Object?> rawBooks = jsonMap(json['books'], 'books');
    final Map<String, List<List<String>>> books = <String, List<List<String>>>{};
    for (final MapEntry<String, Object?> entry in rawBooks.entries) {
      if (!osisBookIds.contains(entry.key)) {
        throw FormatException('"${entry.key}" is not a book');
      }
      final List<Object?> chapters = jsonList(entry.value, entry.key);
      if (chapters.isEmpty) {
        throw FormatException('"${entry.key}" has no chapters');
      }
      books[entry.key] = List<List<String>>.unmodifiable(<List<String>>[
        for (final Object? chapter in chapters)
          List<String>.unmodifiable(<String>[
            for (final Object? verse in jsonList(chapter, entry.key))
              if (verse is String) verse else throw FormatException('"${entry.key}" has a non-text verse'),
          ]),
      ]);
    }
    if (books.isEmpty) {
      throw const FormatException('"books" must not be empty');
    }
    return BiblePack._(
      schemaVersion: schema,
      language: language,
      translationId: readString(json, 'translationId'),
      source: readString(json, 'source'),
      license: readString(json, 'license'),
      books: Map<String, List<List<String>>>.unmodifiable(books),
    );
  }

  final int schemaVersion;
  final String language;
  final String translationId;

  /// Where the text came from.
  final String source;

  /// The exact notice text shown beside the pack and on the licenses screen.
  final String license;

  final Map<String, List<List<String>>> _books;

  /// Books present in the pack, in canonical order.
  List<BibleBook> get books => <BibleBook>[
        for (final String id in osisBookIds)
          if (_books.containsKey(id))
            BibleBook(
              osisId: id,
              chapterVerseCounts: <int>[
                for (final List<String> c in _books[id]!) c.length,
              ],
            ),
      ];

  bool hasBook(String osisId) => _books.containsKey(osisId);

  /// The verses of a 1-based chapter, or null if the pack lacks it.
  List<String>? chapter(String osisId, int chapter) {
    final List<List<String>>? chapters = _books[osisId];
    if (chapters == null || chapter < 1 || chapter > chapters.length) {
      return null;
    }
    return chapters[chapter - 1];
  }

  /// One verse in this pack's own numbering, or null if it is absent.
  String? verse(String osisId, int chapter, int verse) {
    final List<String>? verses = this.chapter(osisId, chapter);
    if (verses == null || verse < 1 || verse > verses.length) {
      return null;
    }
    return verses[verse - 1];
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'schemaVersion': schemaVersion,
        'language': language,
        'translationId': translationId,
        'source': source,
        'license': license,
        'books': <String, Object?>{
          for (final String id in osisBookIds)
            if (_books.containsKey(id)) id: _books[id],
        },
      };
}
