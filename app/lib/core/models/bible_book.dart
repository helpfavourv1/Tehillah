import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/verse_ref.dart';

/// A book of an installed Bible with the verse count of each chapter, in that
/// language's own numbering. The displayed book name is a localization lookup
/// by [osisId], not stored here.
final class BibleBook {
  BibleBook({required this.osisId, required List<int> chapterVerseCounts})
      : assert(osisBookIds.contains(osisId)),
        assert(chapterVerseCounts.isNotEmpty),
        chapterVerseCounts = List<int>.unmodifiable(chapterVerseCounts);

  factory BibleBook.fromJson(Map<String, Object?> json) {
    final String id = readString(json, 'osisId');
    if (!osisBookIds.contains(id)) {
      throw FormatException('"$id" is not a book');
    }
    final List<Object?> raw = jsonList(json['chapterVerseCounts'], 'chapterVerseCounts');
    if (raw.isEmpty) {
      throw const FormatException('"chapterVerseCounts" must not be empty');
    }
    return BibleBook(
      osisId: id,
      chapterVerseCounts: <int>[
        for (final Object? c in raw)
          if (c is int && c >= 0) c else throw const FormatException('bad verse count'),
      ],
    );
  }

  final String osisId;

  /// Index 0 is chapter 1.
  final List<int> chapterVerseCounts;

  int get chapters => chapterVerseCounts.length;

  /// Position in the canon, 0 to 65.
  int get order => osisBookIds.indexOf(osisId);

  /// Verses in the 1-based [chapter], or 0 if there is no such chapter.
  int versesIn(int chapter) =>
      chapter >= 1 && chapter <= chapters ? chapterVerseCounts[chapter - 1] : 0;

  Map<String, Object?> toJson() => <String, Object?>{
        'osisId': osisId,
        'chapterVerseCounts': chapterVerseCounts,
      };

  @override
  bool operator ==(Object other) =>
      other is BibleBook &&
      other.osisId == osisId &&
      listsEqual(other.chapterVerseCounts, chapterVerseCounts);

  @override
  int get hashCode => Object.hash(osisId, Object.hashAll(chapterVerseCounts));
}
