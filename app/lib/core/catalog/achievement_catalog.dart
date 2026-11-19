import 'package:tehillah/core/models/achievement_def.dart';

/// The nine fruit achievements. Thresholds are starting values.
abstract final class AchievementCatalog {
  static const List<AchievementDef> all = <AchievementDef>[
    AchievementDef(id: 'love', fruitKey: 'fruitLove', rule: AchievementRule.matchesWon, threshold: 10),
    AchievementDef(id: 'joy', fruitKey: 'fruitJoy', rule: AchievementRule.goals, threshold: 50),
    AchievementDef(id: 'peace', fruitKey: 'fruitPeace', rule: AchievementRule.cleanSheets, threshold: 3),
    AchievementDef(id: 'patience', fruitKey: 'fruitPatience', rule: AchievementRule.suddenDeathWins, threshold: 3),
    AchievementDef(id: 'kindness', fruitKey: 'fruitKindness', rule: AchievementRule.keeperSaves, threshold: 10),
    AchievementDef(id: 'goodness', fruitKey: 'fruitGoodness', rule: AchievementRule.lampsEarned, threshold: 6),
    AchievementDef(id: 'faithfulness', fruitKey: 'fruitFaithfulness', rule: AchievementRule.dailyStreak, threshold: 7),
    AchievementDef(id: 'gentleness', fruitKey: 'fruitGentleness', rule: AchievementRule.threeStarMatches, threshold: 10),
    AchievementDef(id: 'selfControl', fruitKey: 'fruitSelfControl', rule: AchievementRule.goalStreak, threshold: 9),
  ];

  static AchievementDef? byId(String id) {
    for (final AchievementDef a in all) {
      if (a.id == id) {
        return a;
      }
    }
    return null;
  }
}
