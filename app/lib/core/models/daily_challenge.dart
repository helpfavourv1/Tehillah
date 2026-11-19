import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/opponent_def.dart';

final RegExp _dateKey = RegExp(r'^\d{4}-\d{2}-\d{2}$');

/// Today's Daily Bread challenge. It is a pure function of the date, so every
/// player gets the same one; `daily_seed` builds it.
final class DailyChallenge {
  DailyChallenge({
    required this.dateKey,
    required this.seed,
    required this.opponent,
    required this.difficulty,
    required this.wind,
    this.kicksPerSide = 5,
  })  : assert(_dateKey.hasMatch(dateKey)),
        assert(difficulty >= 0 && difficulty <= 1),
        assert(wind >= -1 && wind <= 1),
        assert(kicksPerSide >= 1);

  factory DailyChallenge.fromJson(Map<String, Object?> json) {
    final String key = readString(json, 'dateKey');
    if (!_dateKey.hasMatch(key)) {
      throw const FormatException('"dateKey" must look like 2026-11-19');
    }
    return DailyChallenge(
      dateKey: key,
      seed: readInt(json, 'seed'),
      opponent: OpponentDef.fromJson(jsonMap(json['opponent'], 'opponent')),
      difficulty: readDouble(json, 'difficulty', min: 0, max: 1),
      wind: readDouble(json, 'wind', min: -1, max: 1),
      kicksPerSide: readInt(json, 'kicksPerSide', min: 1, max: 20),
    );
  }

  /// `YYYY-MM-DD` in the player's local calendar day.
  final String dateKey;
  final int seed;
  final OpponentDef opponent;
  final double difficulty;
  final double wind;
  final int kicksPerSide;

  Map<String, Object?> toJson() => <String, Object?>{
        'dateKey': dateKey,
        'seed': seed,
        'opponent': opponent.toJson(),
        'difficulty': difficulty,
        'wind': wind,
        'kicksPerSide': kicksPerSide,
      };

  @override
  bool operator ==(Object other) =>
      other is DailyChallenge &&
      other.dateKey == dateKey &&
      other.seed == seed &&
      other.opponent == opponent &&
      other.difficulty == difficulty &&
      other.wind == wind &&
      other.kicksPerSide == kicksPerSide;

  @override
  int get hashCode =>
      Object.hash(dateKey, seed, opponent, difficulty, wind, kicksPerSide);
}

/// What the player did on one Daily Bread day.
final class DailyRecord {
  const DailyRecord({required this.dateKey, required this.won, required this.goals})
      : assert(goals >= 0);

  factory DailyRecord.fromJson(Map<String, Object?> json) {
    final String key = readString(json, 'dateKey');
    if (!_dateKey.hasMatch(key)) {
      throw const FormatException('"dateKey" must look like 2026-11-19');
    }
    return DailyRecord(
      dateKey: key,
      won: readBool(json, 'won'),
      goals: readInt(json, 'goals', min: 0),
    );
  }

  final String dateKey;
  final bool won;
  final int goals;

  Map<String, Object?> toJson() =>
      <String, Object?>{'dateKey': dateKey, 'won': won, 'goals': goals};

  @override
  bool operator ==(Object other) =>
      other is DailyRecord &&
      other.dateKey == dateKey &&
      other.won == won &&
      other.goals == goals;

  @override
  int get hashCode => Object.hash(dateKey, won, goals);
}
