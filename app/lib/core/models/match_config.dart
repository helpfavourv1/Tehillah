import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/loadout.dart';
import 'package:tehillah/core/models/opponent_def.dart';

/// The seven ways to play.
enum MatchMode {
  journey,
  friendly,
  watchman,
  slingAndStone,
  jericho,
  sevenDays,
  dailyBread,
}

/// Everything needed to play a match again exactly: the same config and the
/// same sequence of shots always give the same result.
final class MatchConfig {
  const MatchConfig({
    required this.mode,
    required this.opponent,
    required this.loadout,
    required this.seed,
    required this.difficulty,
    this.stageId,
    this.round = 1,
    this.kicksPerSide = 5,
    this.wind = 0,
    this.bonusSelah = 0,
  })  : assert(kicksPerSide >= 1),
        assert(round >= 1),
        assert(difficulty >= 0 && difficulty <= 1),
        assert(wind >= -1 && wind <= 1),
        assert(bonusSelah >= 0 && bonusSelah <= maxBonusSelah);

  /// The most extra Selah pauses a rewarded ad can add to one match.
  static const int maxBonusSelah = 1;

  factory MatchConfig.fromJson(Map<String, Object?> json) {
    final Object? stage = json['stageId'];
    if (stage != null && (stage is! int || stage < 1)) {
      throw const FormatException('"stageId" must be a positive integer or null');
    }
    return MatchConfig(
      mode: readEnum<MatchMode>(MatchMode.values, json, 'mode'),
      opponent: OpponentDef.fromJson(jsonMap(json['opponent'], 'opponent')),
      loadout: Loadout.fromJson(jsonMap(json['loadout'], 'loadout')),
      seed: readInt(json, 'seed'),
      difficulty: readDouble(json, 'difficulty', min: 0, max: 1),
      stageId: stage as int?,
      round: readInt(json, 'round', min: 1),
      kicksPerSide: readInt(json, 'kicksPerSide', min: 1, max: 20),
      wind: readDouble(json, 'wind', min: -1, max: 1),
      bonusSelah: json.containsKey('bonusSelah')
          ? readInt(json, 'bonusSelah', min: 0, max: maxBonusSelah)
          : 0,
    );
  }

  final MatchMode mode;
  final OpponentDef opponent;
  final Loadout loadout;

  /// Seeds every random decision in the match.
  final int seed;

  /// 0 to 1, taken from the stage or set by the mode.
  final double difficulty;

  /// The Journey stage, or null for modes that are not part of a stage.
  final int? stageId;

  /// The round within the stage or mode, starting at 1.
  final int round;

  final int kicksPerSide;

  /// Crosswind, -1 to 1.
  final double wind;

  /// Extra Selah pauses earned from an opt-in rewarded ad before the match.
  final int bonusSelah;

  MatchConfig copyWith({
    MatchMode? mode,
    OpponentDef? opponent,
    Loadout? loadout,
    int? seed,
    double? difficulty,
    int? stageId,
    int? round,
    int? kicksPerSide,
    double? wind,
    int? bonusSelah,
  }) {
    return MatchConfig(
      mode: mode ?? this.mode,
      opponent: opponent ?? this.opponent,
      loadout: loadout ?? this.loadout,
      seed: seed ?? this.seed,
      difficulty: difficulty ?? this.difficulty,
      stageId: stageId ?? this.stageId,
      round: round ?? this.round,
      kicksPerSide: kicksPerSide ?? this.kicksPerSide,
      wind: wind ?? this.wind,
      bonusSelah: bonusSelah ?? this.bonusSelah,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'mode': mode.name,
        'opponent': opponent.toJson(),
        'loadout': loadout.toJson(),
        'seed': seed,
        'difficulty': difficulty,
        'stageId': stageId,
        'round': round,
        'kicksPerSide': kicksPerSide,
        'wind': wind,
        'bonusSelah': bonusSelah,
      };

  @override
  bool operator ==(Object other) =>
      other is MatchConfig &&
      other.mode == mode &&
      other.opponent == opponent &&
      other.loadout == loadout &&
      other.seed == seed &&
      other.difficulty == difficulty &&
      other.stageId == stageId &&
      other.round == round &&
      other.kicksPerSide == kicksPerSide &&
      other.wind == wind &&
      other.bonusSelah == bonusSelah;

  @override
  int get hashCode => Object.hash(
        mode,
        opponent,
        loadout,
        seed,
        difficulty,
        stageId,
        round,
        kicksPerSide,
        wind,
        bonusSelah,
      );
}
