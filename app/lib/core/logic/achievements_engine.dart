import 'package:tehillah/core/catalog/achievement_catalog.dart';
import 'package:tehillah/core/logic/progression_rules.dart';
import 'package:tehillah/core/models/achievement_def.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/models/progress_stats.dart';

/// The nine fruit achievements. Each is a local milestone read from the saved
/// statistics.
abstract final class AchievementsEngine {
  /// The current value of the count an achievement watches.
  static int valueOf(AchievementRule rule, Progress progress) {
    final ProgressStats s = progress.stats;
    switch (rule) {
      case AchievementRule.matchesWon:
        return s.matchesWon;
      case AchievementRule.goals:
        return s.goals;
      case AchievementRule.cleanSheets:
        return s.cleanSheets;
      case AchievementRule.suddenDeathWins:
        return s.suddenDeathWins;
      case AchievementRule.keeperSaves:
        return s.keeperSaves;
      case AchievementRule.lampsEarned:
        return progress.lamps.length;
      case AchievementRule.dailyStreak:
        return ProgressionRules.longestDailyStreak(progress);
      case AchievementRule.threeStarMatches:
        return s.threeStarMatches;
      case AchievementRule.goalStreak:
        return s.bestGoalStreak;
    }
  }

  /// Ids of achievements now reached that the player does not hold yet, in
  /// catalog order.
  static List<String> evaluate(Progress progress) {
    return <String>[
      for (final AchievementDef def in AchievementCatalog.all)
        if (!progress.achievements.contains(def.id) &&
            valueOf(def.rule, progress) >= def.threshold)
          def.id,
    ];
  }
}
