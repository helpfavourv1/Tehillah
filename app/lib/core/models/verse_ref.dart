import 'package:tehillah/core/models/json_util.dart';

/// OSIS identifiers of the 66 books in canonical order. Every verse key in the
/// app, the curated list and the packs uses these.
const List<String> osisBookIds = <String>[
  'Gen', 'Exod', 'Lev', 'Num', 'Deut', 'Josh', 'Judg', 'Ruth', '1Sam', '2Sam',
  '1Kgs', '2Kgs', '1Chr', '2Chr', 'Ezra', 'Neh', 'Esth', 'Job', 'Ps', 'Prov',
  'Eccl', 'Song', 'Isa', 'Jer', 'Lam', 'Ezek', 'Dan', 'Hos', 'Joel', 'Amos',
  'Obad', 'Jonah', 'Mic', 'Nah', 'Hab', 'Zeph', 'Hag', 'Zech', 'Mal', 'Matt',
  'Mark', 'Luke', 'John', 'Acts', 'Rom', '1Cor', '2Cor', 'Gal', 'Eph', 'Phil',
  'Col', '1Thess', '2Thess', '1Tim', '2Tim', 'Titus', 'Phlm', 'Heb', 'Jas',
  '1Pet', '2Pet', '1John', '2John', '3John', 'Jude', 'Rev',
];

/// A verse in the canonical (English) numbering, written `Book.chapter.verse`,
/// for example `Ps.23.1`. Each language maps this key to its own numbering
/// through its verse-number map.
final class VerseRef implements Comparable<VerseRef> {
  const VerseRef(this.book, this.chapter, this.verse)
      : assert(chapter >= 1),
        assert(verse >= 1);

  /// Parses `Ps.23.1`. Throws a [FormatException] for anything else.
  factory VerseRef.parse(String text) {
    final List<String> parts = text.split('.');
    if (parts.length != 3 || !osisBookIds.contains(parts[0])) {
      throw FormatException('"$text" is not a verse reference');
    }
    final int? chapter = int.tryParse(parts[1]);
    final int? verse = int.tryParse(parts[2]);
    if (chapter == null || verse == null || chapter < 1 || verse < 1) {
      throw FormatException('"$text" is not a verse reference');
    }
    return VerseRef(parts[0], chapter, verse);
  }

  factory VerseRef.fromJson(Map<String, Object?> json) =>
      VerseRef.parse(readString(json, 'ref'));

  final String book;
  final int chapter;
  final int verse;

  /// Position of the book in the canon, 0 to 65.
  int get bookIndex => osisBookIds.indexOf(book);

  Map<String, Object?> toJson() => <String, Object?>{'ref': toString()};

  @override
  int compareTo(VerseRef other) {
    final int byBook = bookIndex.compareTo(other.bookIndex);
    if (byBook != 0) {
      return byBook;
    }
    final int byChapter = chapter.compareTo(other.chapter);
    return byChapter != 0 ? byChapter : verse.compareTo(other.verse);
  }

  @override
  bool operator ==(Object other) =>
      other is VerseRef &&
      other.book == book &&
      other.chapter == chapter &&
      other.verse == verse;

  @override
  int get hashCode => Object.hash(book, chapter, verse);

  @override
  String toString() => '$book.$chapter.$verse';
}
