import 'package:tehillah/core/models/json_util.dart';

/// Running totals that the fruit achievements and the career read. All local.
final class ProgressStats {
  const ProgressStats({
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.goals = 0,
    this.cleanSheets = 0,
    this.suddenDeathWins = 0,
    this.keeperSaves = 0,
    this.threeStarMatches = 0,
    this.currentGoalStreak = 0,
    this.bestGoalStreak = 0,
  });

  factory ProgressStats.fromJson(Map<String, Object?> json) {
    int n(String key) => json.containsKey(key) ? readInt(json, key, min: 0) : 0;
    return ProgressStats(
      matchesPlayed: n('matchesPlayed'),
      matchesWon: n('matchesWon'),
      goals: n('goals'),
      cleanSheets: n('cleanSheets'),
      suddenDeathWins: n('suddenDeathWins'),
      keeperSaves: n('keeperSaves'),
      threeStarMatches: n('threeStarMatches'),
      currentGoalStreak: n('currentGoalStreak'),
      bestGoalStreak: n('bestGoalStreak'),
    );
  }

  final int matchesPlayed;
  final int matchesWon;
  final int goals;

  /// Matches won without conceding.
  final int cleanSheets;
  final int suddenDeathWins;

  /// Saves made as the keeper in Watchman.
  final int keeperSaves;
  final int threeStarMatches;
  final int currentGoalStreak;
  final int bestGoalStreak;

  ProgressStats copyWith({
    int? matchesPlayed,
    int? matchesWon,
    int? goals,
    int? cleanSheets,
    int? suddenDeathWins,
    int? keeperSaves,
    int? threeStarMatches,
    int? currentGoalStreak,
    int? bestGoalStreak,
  }) {
    return ProgressStats(
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      matchesWon: matchesWon ?? this.matchesWon,
      goals: goals ?? this.goals,
      cleanSheets: cleanSheets ?? this.cleanSheets,
      suddenDeathWins: suddenDeathWins ?? this.suddenDeathWins,
      keeperSaves: keeperSaves ?? this.keeperSaves,
      threeStarMatches: threeStarMatches ?? this.threeStarMatches,
      currentGoalStreak: currentGoalStreak ?? this.currentGoalStreak,
      bestGoalStreak: bestGoalStreak ?? this.bestGoalStreak,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'matchesPlayed': matchesPlayed,
        'matchesWon': matchesWon,
        'goals': goals,
        'cleanSheets': cleanSheets,
        'suddenDeathWins': suddenDeathWins,
        'keeperSaves': keeperSaves,
        'threeStarMatches': threeStarMatches,
        'currentGoalStreak': currentGoalStreak,
        'bestGoalStreak': bestGoalStreak,
      };

  @override
  bool operator ==(Object other) =>
      other is ProgressStats &&
      other.matchesPlayed == matchesPlayed &&
      other.matchesWon == matchesWon &&
      other.goals == goals &&
      other.cleanSheets == cleanSheets &&
      other.suddenDeathWins == suddenDeathWins &&
      other.keeperSaves == keeperSaves &&
      other.threeStarMatches == threeStarMatches &&
      other.currentGoalStreak == currentGoalStreak &&
      other.bestGoalStreak == bestGoalStreak;

  @override
  int get hashCode => Object.hash(
        matchesPlayed,
        matchesWon,
        goals,
        cleanSheets,
        suddenDeathWins,
        keeperSaves,
        threeStarMatches,
        currentGoalStreak,
        bestGoalStreak,
      );
}
