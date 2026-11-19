import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/language_codes.dart';
import 'package:tehillah/core/models/verse_ref.dart';

/// One verse in one language, as shown on a verse card.
final class Verse {
  const Verse({
    required this.ref,
    required this.text,
    required this.language,
    required this.translationId,
  });

  factory Verse.fromJson(Map<String, Object?> json) {
    final String language = readString(json, 'language');
    if (!LanguageCodes.isSupported(language)) {
      throw FormatException('unsupported language "$language"');
    }
    return Verse(
      ref: VerseRef.fromJson(json),
      text: readString(json, 'text'),
      language: language,
      translationId: readString(json, 'translationId'),
    );
  }

  /// The canonical key, not the language's own numbering.
  final VerseRef ref;
  final String text;
  final String language;
  final String translationId;

  Map<String, Object?> toJson() => <String, Object?>{
        'ref': ref.toString(),
        'text': text,
        'language': language,
        'translationId': translationId,
      };

  @override
  bool operator ==(Object other) =>
      other is Verse &&
      other.ref == ref &&
      other.text == text &&
      other.language == language &&
      other.translationId == translationId;

  @override
  int get hashCode => Object.hash(ref, text, language, translationId);
}
