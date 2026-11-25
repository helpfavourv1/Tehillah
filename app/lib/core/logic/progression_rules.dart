import 'package:tehillah/core/catalog/ball_catalog.dart';
import 'package:tehillah/core/catalog/gear_catalog.dart';
import 'package:tehillah/core/catalog/stage_catalog.dart';
import 'package:tehillah/core/logic/date_key.dart';
import 'package:tehillah/core/logic/mode_rules.dart';
import 'package:tehillah/core/models/ball_def.dart';
import 'package:tehillah/core/models/daily_challenge.dart';
import 'package:tehillah/core/models/gear_def.dart';
import 'package:tehillah/core/models/kick_record.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/match_state.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/models/progress_stats.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/stage_def.dart';

/// The facts about a finished match that the career needs.
final class MatchSummary {
  const MatchSummary({
    required this.config,
    required this.finalState,
    required this.history,
  });

  final MatchConfig config;
  final MatchState finalState;
  final List<KickRecord> history;

  bool get playerWon => finalState.playerScore > finalState.opponentScore;

  bool get isWatchman => config.mode == MatchMode.watchman;

  /// Goals the player scored with their own kicks (none in Watchman, where the
  /// computer takes the player's kicks).
  int get playerGoals => isWatchman
      ? 0
      : history.where((KickRecord k) => k.side == MatchSide.player && k.isGoal).length;

  /// Opponent kicks the player saved as keeper in Watchman.
  int get saves => !isWatchman
      ? 0
      : history
          .where((KickRecord k) =>
              k.side == MatchSide.opponent &&
              k.outcome.result == ShotResult.saved)
          .length;

  int get conceded => finalState.opponentScore;

  bool get wentToSuddenDeath =>
      finalState.playerKicks > finalState.kicksPerSide ||
      finalState.opponentKicks > finalState.kicksPerSide;
}

/// Stars, lamps, unlocks and career statistics. Pure functions over [Progress].
abstract final class ProgressionRules {
  /// Stars for a match, 0 to 3: one for a win, one more for conceding at most
  /// one goal, and one more for a flawless performance (every kick scored, or
  /// no goal conceded as the keeper in Watchman).
  static int stars(MatchSummary summary) {
    if (!summary.playerWon) {
      return 0;
    }
    int stars = 1;
    if (summary.conceded <= 1) {
      stars += 1;
    }
    final MatchState s = summary.finalState;
    final bool flawless = summary.isWatchman
        ? summary.conceded == 0
        : s.playerScore == s.playerKicks && s.playerKicks >= 3;
    if (flawless) {
      stars += 1;
    }
    return stars;
  }

  /// The Journey stages whose four rounds all have at least one star.
  static Set<int> lampsEarned(Progress progress) {
    final Set<int> lamps = <int>{};
    for (final StageDef stage in StageCatalog.stages) {
      if (stage.opponents.every((o) => progress.starsFor(o.id) >= 1)) {
        lamps.add(stage.id);
      }
    }
    return lamps;
  }

  /// Records a finished match: statistics always; stars and lamps for Journey.
  static Progress recordMatch(Progress progress, MatchSummary summary) {
    final ProgressStats old = progress.stats;
    int streak = old.currentGoalStreak;
    int best = old.bestGoalStreak;
    if (!summary.isWatchman) {
      for (final KickRecord k in summary.history) {
        if (k.side != MatchSide.player) {
          continue;
        }
        if (k.isGoal) {
          streak += 1;
          if (streak > best) {
            best = streak;
          }
        } else {
          streak = 0;
        }
      }
    }
    final int stars = ProgressionRules.stars(summary);
    final ProgressStats stats = old.copyWith(
      matchesPlayed: old.matchesPlayed + 1,
      matchesWon: old.matchesWon + (summary.playerWon ? 1 : 0),
      goals: old.goals + summary.playerGoals,
      cleanSheets:
          old.cleanSheets + (summary.playerWon && summary.conceded == 0 ? 1 : 0),
      suddenDeathWins: old.suddenDeathWins +
          (summary.playerWon && summary.wentToSuddenDeath ? 1 : 0),
      keeperSaves: old.keeperSaves + summary.saves,
      threeStarMatches: old.threeStarMatches + (stars == 3 ? 1 : 0),
      currentGoalStreak: streak,
      bestGoalStreak: best,
    );

    Progress next = progress.copyWith(stats: stats);
    final int? stageId = summary.config.stageId;
    if (summary.config.mode == MatchMode.journey && stageId != null) {
      final String key = summary.config.opponent.id;
      final int kept = stars > progress.starsFor(key) ? stars : progress.starsFor(key);
      next = next.copyWith(
        matchStars: <String, int>{...next.matchStars, key: kept},
      );
      next = next.copyWith(lamps: lampsEarned(next));
    }
    return next;
  }

  /// Records a Daily Bread result. Only the first result of a day counts.
  static Progress recordDaily(
    Progress progress,
    DailyChallenge challenge, {
    required bool won,
    required int goals,
  }) {
    if (progress.dailyHistory.containsKey(challenge.dateKey)) {
      return progress;
    }
    return progress.copyWith(
      dailyHistory: <String, DailyRecord>{
        ...progress.dailyHistory,
        challenge.dateKey:
            DailyRecord(dateKey: challenge.dateKey, won: won, goals: goals),
      },
    );
  }

  /// Records one day of Seven Days. The first call starts the week.
  static Progress recordSevenDays(
    Progress progress, {
    required String todayKey,
    required bool won,
  }) {
    final String start = progress.sevenDaysStart ?? todayKey;
    final int? day = ModeRules.sevenDaysDay(start, todayKey);
    if (day == null) {
      return progress;
    }
    return progress.copyWith(
      sevenDaysStart: start,
      sevenDaysDone: won ? <int>{...progress.sevenDaysDone, day} : progress.sevenDaysDone,
    );
  }

  /// The Jericho round the player is on (1 to 7).
  static int nextJerichoRound(Progress progress) => progress.jerichoCleared + 1;

  /// Records a Jericho round. Rounds must be played in order; anything else is
  /// ignored. A loss sends the run back to round 1. Winning round 7 completes
  /// the run and starts a new one.
  static Progress recordJericho(Progress progress, {required int round, required bool won}) {
    if (round != nextJerichoRound(progress) || round > ModeRules.jerichoRounds) {
      return progress;
    }
    if (!won) {
      return progress.copyWith(jerichoCleared: 0);
    }
    if (round == ModeRules.jerichoRounds) {
      return progress.copyWith(
        jerichoCleared: 0,
        jerichoCompletions: progress.jerichoCompletions + 1,
      );
    }
    return progress.copyWith(jerichoCleared: round);
  }

  /// Records a finished Sling and Stone round: counts the play, keeps the best.
  static Progress recordSling(Progress progress, {required int stars}) {
    final int s = stars < 0 ? 0 : (stars > 3 ? 3 : stars);
    return progress.copyWith(
      slingPlays: progress.slingPlays + 1,
      slingBest: s > progress.slingBest ? s : progress.slingBest,
    );
  }

  /// Whether [key] counts toward a Daily Bread streak: it has a result, or a
  /// rewarded ad restored it.
  static bool _dayCounts(Progress progress, String key) =>
      progress.dailyHistory.containsKey(key) || progress.rescuedDays.contains(key);

  /// The longest run of consecutive days with a Daily Bread result or a
  /// restored day.
  static int longestDailyStreak(Progress progress) {
    final List<String> keys = <String>{
      ...progress.dailyHistory.keys,
      ...progress.rescuedDays,
    }.toList()
      ..sort();
    int best = 0;
    int run = 0;
    String? previous;
    for (final String key in keys) {
      run = previous != null && DateKey.daysBetween(previous, key) == 1 ? run + 1 : 1;
      if (run > best) {
        best = run;
      }
      previous = key;
    }
    return best;
  }

  /// The streak that is still alive on [todayKey]: consecutive days ending
  /// today, or yesterday if today is not played yet.
  static int currentDailyStreak(Progress progress, String todayKey) {
    String cursor = _dayCounts(progress, todayKey) ? todayKey : DateKey.addDays(todayKey, -1);
    int run = 0;
    while (_dayCounts(progress, cursor)) {
      run += 1;
      cursor = DateKey.addDays(cursor, -1);
    }
    return run;
  }

  /// Ids of everything unlocked: `ball:<id>`, `gear:<id>`, `mode:<name>`.
  static Set<String> unlocksFor(Progress progress) {
    final int lamps = progress.lamps.length;
    final Set<String> ids = <String>{};
    for (final BallDef ball in BallCatalog.all) {
      if (ball.unlockLamps <= lamps) {
        ids.add('ball:${ball.id}');
      }
    }
    for (final GearDef gear in GearCatalog.all) {
      if (gear.unlockLamps <= lamps) {
        ids.add('gear:${gear.id}');
      }
    }
    for (final MatchMode mode in MatchMode.values) {
      if (ModeRules.isUnlocked(mode, progress)) {
        ids.add('mode:${mode.name}');
      }
    }
    return ids;
  }
}
