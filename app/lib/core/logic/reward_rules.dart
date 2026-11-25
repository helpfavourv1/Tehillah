import 'package:tehillah/core/logic/date_key.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/progress.dart';

/// What a rewarded ad can buy. Every one is opt-in, none is required for any
/// unlock, and all of them stay available after Remove Ads (the ad is the
/// price, not money).
enum RewardKind { extraSelah, streakRescue, extraStones, retryMatch }

/// The rules for each reward: when it may be offered and what it grants.
abstract final class RewardRules {
  /// Stones a rewarded ad adds to one Sling and Stone round.
  static const int extraStones = 3;

  /// One extra Selah pause per match, before the first kick.
  static bool canOfferExtraSelah(MatchConfig config) => config.bonusSelah == 0;

  static MatchConfig withExtraSelah(MatchConfig config) =>
      config.copyWith(bonusSelah: MatchConfig.maxBonusSelah);

  /// The day a rewarded ad could restore, or null. Exactly one missed day is
  /// restorable: yesterday has no result and was not restored, the day before
  /// it counts, and no day has been restored yet in this calendar week
  /// (Monday to Sunday).
  static String? restorableDay(Progress progress, String todayKey) {
    final String yesterday = DateKey.addDays(todayKey, -1);
    final String before = DateKey.addDays(todayKey, -2);
    bool counts(String k) =>
        progress.dailyHistory.containsKey(k) || progress.rescuedDays.contains(k);
    if (counts(todayKey) || counts(yesterday) || !counts(before)) {
      return null;
    }
    final int week = _weekOf(todayKey);
    for (final String rescued in progress.rescuedDays) {
      if (_weekOf(rescued) == week) {
        return null;
      }
    }
    return yesterday;
  }

  /// Marks the restorable day as played. Returns [progress] unchanged when
  /// there is nothing to restore.
  static Progress restoreStreak(Progress progress, String todayKey) {
    final String? day = restorableDay(progress, todayKey);
    if (day == null) {
      return progress;
    }
    return progress.copyWith(rescuedDays: <String>{...progress.rescuedDays, day});
  }

  /// The whole-week number of a date, counting from Monday 1970-01-05.
  static int _weekOf(String key) => DateKey.daysBetween('1970-01-05', key) ~/ 7;
}
