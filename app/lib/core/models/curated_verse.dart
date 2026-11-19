import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/verse_ref.dart';

/// The game moments a verse card can appear at.
enum VerseMoment { miss, goal, selah, win, daily }

/// A bundled verse and the moments it suits. The text per language is bundled
/// separately; this is the language-independent entry.
final class CuratedVerse {
  CuratedVerse({
    required this.id,
    required this.ref,
    required Set<VerseMoment> moments,
  })  : assert(moments.isNotEmpty),
        moments = Set<VerseMoment>.unmodifiable(moments);

  factory CuratedVerse.fromJson(Map<String, Object?> json) {
    final List<Object?> raw = jsonList(json['moments'], 'moments');
    final Set<VerseMoment> moments = <VerseMoment>{
      for (final Object? m in raw)
        readEnum<VerseMoment>(VerseMoment.values, <String, Object?>{'m': m}, 'm'),
    };
    if (moments.isEmpty) {
      throw const FormatException('"moments" must not be empty');
    }
    return CuratedVerse(
      id: readString(json, 'id'),
      ref: VerseRef.parse(readString(json, 'ref')),
      moments: moments,
    );
  }

  final String id;
  final VerseRef ref;
  final Set<VerseMoment> moments;

  bool suits(VerseMoment moment) => moments.contains(moment);

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'ref': ref.toString(),
        'moments': <String>[
          for (final VerseMoment m in VerseMoment.values)
            if (moments.contains(m)) m.name,
        ],
      };

  @override
  bool operator ==(Object other) =>
      other is CuratedVerse &&
      other.id == id &&
      other.ref == ref &&
      other.moments.length == moments.length &&
      other.moments.containsAll(moments);

  @override
  int get hashCode => Object.hash(id, ref, moments.length);
}
