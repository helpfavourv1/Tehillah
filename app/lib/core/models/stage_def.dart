import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/opponent_def.dart';

/// One Journey stage: a themed place with one opponent for each round.
final class StageDef {
  StageDef({
    required this.id,
    required this.nameKey,
    required this.difficulty,
    required this.wind,
    required this.isBoss,
    required List<OpponentDef> opponents,
  })  : assert(id >= 1),
        assert(difficulty >= 0 && difficulty <= 1),
        assert(wind >= -1 && wind <= 1),
        assert(opponents.isNotEmpty),
        opponents = List<OpponentDef>.unmodifiable(opponents);

  factory StageDef.fromJson(Map<String, Object?> json) {
    final List<Object?> raw = jsonList(json['opponents'], 'opponents');
    if (raw.isEmpty) {
      throw const FormatException('"opponents" must not be empty');
    }
    return StageDef(
      id: readInt(json, 'id', min: 1),
      nameKey: readString(json, 'nameKey'),
      difficulty: readDouble(json, 'difficulty', min: 0, max: 1),
      wind: readDouble(json, 'wind', min: -1, max: 1),
      isBoss: readBool(json, 'isBoss'),
      opponents: <OpponentDef>[
        for (final Object? o in raw)
          OpponentDef.fromJson(jsonMap(o, 'opponent')),
      ],
    );
  }

  /// 1 to 12, in Journey order.
  final int id;

  /// Localization key for the stage name (the text lives in the ARB files).
  final String nameKey;

  /// 0 (gentle) to 1 (hardest); the base of the keepers' strength.
  final double difficulty;

  /// Crosswind, -1 (strong from the left) to 1 (strong from the right).
  final double wind;

  final bool isBoss;

  /// One opponent per round, in round order.
  final List<OpponentDef> opponents;

  int get rounds => opponents.length;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'nameKey': nameKey,
        'difficulty': difficulty,
        'wind': wind,
        'isBoss': isBoss,
        'opponents': <Object?>[for (final OpponentDef o in opponents) o.toJson()],
      };

  @override
  bool operator ==(Object other) =>
      other is StageDef &&
      other.id == id &&
      other.nameKey == nameKey &&
      other.difficulty == difficulty &&
      other.wind == wind &&
      other.isBoss == isBoss &&
      listsEqual(other.opponents, opponents);

  @override
  int get hashCode =>
      Object.hash(id, nameKey, difficulty, wind, isBoss, Object.hashAll(opponents));
}
