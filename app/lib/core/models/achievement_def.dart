import 'package:tehillah/core/models/json_util.dart';

/// What an achievement counts. `achievements_engine` reads the matching value
/// from the saved statistics.
enum AchievementRule {
  matchesWon,
  goals,
  cleanSheets,
  suddenDeathWins,
  keeperSaves,
  lampsEarned,
  dailyStreak,
  threeStarMatches,
  goalStreak,
}

/// One of the nine fruit achievements: a local milestone, stored on the device
/// only.
final class AchievementDef {
  const AchievementDef({
    required this.id,
    required this.fruitKey,
    required this.rule,
    required this.threshold,
  }) : assert(threshold >= 1);

  factory AchievementDef.fromJson(Map<String, Object?> json) {
    return AchievementDef(
      id: readString(json, 'id'),
      fruitKey: readString(json, 'fruitKey'),
      rule: readEnum<AchievementRule>(AchievementRule.values, json, 'rule'),
      threshold: readInt(json, 'threshold', min: 1),
    );
  }

  final String id;

  /// Localization key for the fruit the achievement is named after.
  final String fruitKey;
  final AchievementRule rule;

  /// The count at which the achievement unlocks.
  final int threshold;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'fruitKey': fruitKey,
        'rule': rule.name,
        'threshold': threshold,
      };

  @override
  bool operator ==(Object other) =>
      other is AchievementDef &&
      other.id == id &&
      other.fruitKey == fruitKey &&
      other.rule == rule &&
      other.threshold == threshold;

  @override
  int get hashCode => Object.hash(id, fruitKey, rule, threshold);
}
