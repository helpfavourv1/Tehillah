import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/language_codes.dart';
import 'package:tehillah/core/models/verse_ref.dart';

DateTime _readTime(Map<String, Object?> json, String key) {
  final DateTime? t = DateTime.tryParse(readString(json, key));
  if (t == null) {
    throw FormatException('"$key" is not a date and time');
  }
  return t.toUtc();
}

String _readLanguage(Map<String, Object?> json) {
  final String language = readString(json, 'language');
  if (!LanguageCodes.isSupported(language)) {
    throw FormatException('unsupported language "$language"');
  }
  return language;
}

/// A saved verse in the reader. The reference is canonical; the language says
/// which Bible it was saved in.
final class Bookmark {
  Bookmark({required this.ref, required this.language, required DateTime createdAt})
      : createdAt = createdAt.toUtc();

  factory Bookmark.fromJson(Map<String, Object?> json) => Bookmark(
        ref: VerseRef.parse(readString(json, 'ref')),
        language: _readLanguage(json),
        createdAt: _readTime(json, 'createdAt'),
      );

  final VerseRef ref;
  final String language;
  final DateTime createdAt;

  Map<String, Object?> toJson() => <String, Object?>{
        'ref': ref.toString(),
        'language': language,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is Bookmark &&
      other.ref == ref &&
      other.language == language &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(ref, language, createdAt);
}

/// Highlight colors, named by meaning of the token, not by hex value.
enum HighlightColor { sun, leaf, sky, rose }

/// A highlighted verse in the reader.
final class Highlight {
  Highlight({
    required this.ref,
    required this.language,
    required this.color,
    required DateTime createdAt,
  }) : createdAt = createdAt.toUtc();

  factory Highlight.fromJson(Map<String, Object?> json) => Highlight(
        ref: VerseRef.parse(readString(json, 'ref')),
        language: _readLanguage(json),
        color: readEnum<HighlightColor>(HighlightColor.values, json, 'color'),
        createdAt: _readTime(json, 'createdAt'),
      );

  final VerseRef ref;
  final String language;
  final HighlightColor color;
  final DateTime createdAt;

  Highlight copyWith({HighlightColor? color}) => Highlight(
        ref: ref,
        language: language,
        color: color ?? this.color,
        createdAt: createdAt,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'ref': ref.toString(),
        'language': language,
        'color': color.name,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      other is Highlight &&
      other.ref == ref &&
      other.language == language &&
      other.color == color &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(ref, language, color, createdAt);
}
