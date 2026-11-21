import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/catalog/stage_catalog.dart';
import 'package:tehillah/core/logic/achievements_engine.dart';
import 'package:tehillah/core/logic/daily_seed.dart';
import 'package:tehillah/core/logic/mode_rules.dart';
import 'package:tehillah/core/logic/progression_rules.dart';
import 'package:tehillah/core/models/daily_challenge.dart';
import 'package:tehillah/core/models/kick_record.dart';
import 'package:tehillah/core/models/loadout.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/match_state.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/models/progress_stats.dart';

import '../../support/match_helpers.dart';

MatchSummary _summary({
  required int player,
  required int opponent,
  int kicksEach = 5,
  List<bool>? playerKicks,
  MatchConfig? config,
}) {
  final List<bool> goals = playerKicks ??
      <bool>[for (int i = 0; i < kicksEach; i++) i < player];
  final List<KickRecord> history = <KickRecord>[
    for (int i = 0; i < goals.length; i++) kickRecord(MatchSide.player, i + 1, goal: goals[i]),
    for (int i = 0; i < kicksEach; i++) kickRecord(MatchSide.opponent, i + 1, goal: i < opponent),
  ];
  return MatchSummary(
    config: config ?? configFor(),
    finalState: stateOf(
      playerScore: player,
      opponentScore: opponent,
      playerKicks: goals.length,
      opponentKicks: kicksEach,
    ),
    history: history,
  );
}

void main() {
  group('stars', () {
    test('a loss earns none', () {
      expect(ProgressionRules.stars(_summary(player: 2, opponent: 3)), 0);
    });

    test('a win earns one; conceding at most one adds one; flawless adds one', () {
      expect(ProgressionRules.stars(_summary(player: 3, opponent: 2)), 1);
      expect(ProgressionRules.stars(_summary(player: 4, opponent: 1, playerKicks: <bool>[true, true, false, true, true])), 2);
      expect(ProgressionRules.stars(_summary(player: 5, opponent: 0)), 3);
    });

    test('Watchman is flawless when nothing is conceded', () {
      final MatchSummary s = _summary(
        player: 3, opponent: 0, config: configFor(mode: MatchMode.watchman));
      expect(ProgressionRules.stars(s), 3);
    });
  });

  group('recording a match', () {
    test('statistics move and the goal streak carries across matches', () {
      Progress p = Progress();
      p = ProgressionRules.recordMatch(p, _summary(player: 5, opponent: 1));
      expect(p.stats.matchesPlayed, 1);
      expect(p.stats.matchesWon, 1);
      expect(p.stats.goals, 5);
      expect(p.stats.currentGoalStreak, 5);
      expect(p.stats.bestGoalStreak, 5);
      p = ProgressionRules.recordMatch(p, _summary(player: 3, opponent: 2,
          playerKicks: <bool>[true, true, true, false, false]));
      expect(p.stats.currentGoalStreak, 0);
      expect(p.stats.bestGoalStreak, 8);
    });

    test('clean sheets, sudden-death wins and three-star matches are counted', () {
      Progress p = ProgressionRules.recordMatch(Progress(), _summary(player: 5, opponent: 0));
      expect(p.stats.cleanSheets, 1);
      expect(p.stats.threeStarMatches, 1);
      final MatchSummary sd = MatchSummary(
        config: configFor(),
        finalState: stateOf(playerScore: 5, opponentScore: 4, playerKicks: 6, opponentKicks: 6),
        history: <KickRecord>[kickRecord(MatchSide.player, 1, goal: true)],
      );
      p = ProgressionRules.recordMatch(p, sd);
      expect(p.stats.suddenDeathWins, 1);
    });

    test('Watchman counts saves and no goals', () {
      final MatchConfig c = configFor(mode: MatchMode.watchman);
      final MatchSummary s = MatchSummary(
        config: c,
        finalState: stateOf(playerScore: 2, opponentScore: 1, playerKicks: 5, opponentKicks: 5, firstSide: MatchSide.opponent),
        history: <KickRecord>[
          kickRecord(MatchSide.opponent, 1, goal: false),
          kickRecord(MatchSide.player, 1, goal: true),
          kickRecord(MatchSide.opponent, 2, goal: false),
          kickRecord(MatchSide.opponent, 3, goal: true),
        ],
      );
      expect(s.saves, 2);
      expect(s.playerGoals, 0);
      final Progress p = ProgressionRules.recordMatch(Progress(), s);
      expect(p.stats.keeperSaves, 2);
      expect(p.stats.goals, 0);
      expect(p.stats.currentGoalStreak, 0);
    });

    test('Journey keeps the best stars and earns a lamp when all four rounds are won', () {
      Progress p = Progress();
      for (int round = 1; round <= 4; round++) {
        final MatchConfig c = ModeRules.journey(
          stage: StageCatalog.stages[0], round: round, loadout: Loadout.starter, seed: round);
        p = ProgressionRules.recordMatch(p, _summary(player: 3, opponent: 2, config: c));
        expect(p.lamps.contains(1), round == 4);
      }
      expect(p.starsFor(StageCatalog.stages[0].opponents[0].id), 1);
      final MatchConfig again = ModeRules.journey(
        stage: StageCatalog.stages[0], round: 1, loadout: Loadout.starter, seed: 9);
      p = ProgressionRules.recordMatch(p, _summary(player: 5, opponent: 0, config: again));
      expect(p.starsFor(StageCatalog.stages[0].opponents[0].id), 3);
      p = ProgressionRules.recordMatch(p, _summary(player: 2, opponent: 3, config: again));
      expect(p.starsFor(StageCatalog.stages[0].opponents[0].id), 3);
    });

    test('other modes never touch stars or lamps', () {
      final Progress p = ProgressionRules.recordMatch(Progress(), _summary(player: 5, opponent: 0));
      expect(p.matchStars, isEmpty);
      expect(p.lamps, isEmpty);
    });
  });

  group('daily and Seven Days', () {
    final DailyChallenge today = DailySeed.forKey('2026-11-19');

    test('only the first Daily Bread result of a day counts', () {
      Progress p = ProgressionRules.recordDaily(Progress(), today, won: false, goals: 2);
      p = ProgressionRules.recordDaily(p, today, won: true, goals: 5);
      expect(p.dailyHistory['2026-11-19']!.won, isFalse);
      expect(p.dailyHistory.length, 1);
    });

    test('streaks count consecutive days only', () {
      Progress p = Progress();
      for (final String k in <String>['2026-11-10', '2026-11-11', '2026-11-12', '2026-11-14', '2026-11-15']) {
        p = ProgressionRules.recordDaily(p, DailySeed.forKey(k), won: true, goals: 3);
      }
      expect(ProgressionRules.longestDailyStreak(p), 3);
      expect(ProgressionRules.currentDailyStreak(p, '2026-11-15'), 2);
      expect(ProgressionRules.currentDailyStreak(p, '2026-11-16'), 2);
      expect(ProgressionRules.currentDailyStreak(p, '2026-11-17'), 0);
      expect(ProgressionRules.longestDailyStreak(Progress()), 0);
    });

    test('Seven Days starts on the first result and records won days', () {
      Progress p = ProgressionRules.recordSevenDays(Progress(), todayKey: '2026-11-10', won: true);
      expect(p.sevenDaysStart, '2026-11-10');
      expect(p.sevenDaysDone, <int>{1});
      p = ProgressionRules.recordSevenDays(p, todayKey: '2026-11-12', won: false);
      expect(p.sevenDaysDone, <int>{1});
      p = ProgressionRules.recordSevenDays(p, todayKey: '2026-11-13', won: true);
      expect(p.sevenDaysDone, <int>{1, 4});
      final Progress late = ProgressionRules.recordSevenDays(p, todayKey: '2026-11-20', won: true);
      expect(late.sevenDaysDone, <int>{1, 4});
    });
  });

  group('unlocks', () {
    test('a new career has the starter ball and the open modes only', () {
      final Set<String> u = ProgressionRules.unlocksFor(Progress());
      expect(u, contains('ball:love'));
      expect(u, containsAll(<String>['mode:journey', 'mode:dailyBread']));
      expect(u, isNot(contains('mode:friendly')));
      expect(u.where((String id) => id.startsWith('ball:')).length, 1);
    });

    test('lamps open balls, gear and modes', () {
      final Set<String> u = ProgressionRules.unlocksFor(Progress(lamps: <int>{1, 2, 3, 4, 5, 6}));
      expect(u, containsAll(<String>['mode:friendly', 'mode:watchman', 'mode:jericho', 'mode:slingAndStone']));
      expect(u.where((String id) => id.startsWith('ball:')).length, greaterThan(3));
    });

    test('lampsEarned needs all four rounds of a stage', () {
      final stage = StageCatalog.stages[1];
      final Progress p = Progress(matchStars: <String, int>{
        for (final o in stage.opponents.take(3)) o.id: 1,
      });
      expect(ProgressionRules.lampsEarned(p), isEmpty);
      final Progress full = Progress(matchStars: <String, int>{
        for (final o in stage.opponents) o.id: 1,
      });
      expect(ProgressionRules.lampsEarned(full), <int>{2});
    });
  });

  group('achievements', () {
    test('a new career has none', () {
      expect(AchievementsEngine.evaluate(Progress()), isEmpty);
    });

    test('each fruit appears when its count is reached and only once', () {
      final Progress p = Progress(
        stats: const ProgressStats(matchesWon: 10, goals: 49, bestGoalStreak: 9),
      );
      expect(AchievementsEngine.evaluate(p), <String>['love', 'selfControl']);
      final Progress held = p.copyWith(achievements: <String>{'love', 'selfControl'});
      expect(AchievementsEngine.evaluate(held), isEmpty);
      final Progress more = held.copyWith(stats: const ProgressStats(goals: 50));
      expect(AchievementsEngine.evaluate(more), <String>['joy']);
    });

    test('daily streak and lamps feed their fruit', () {
      Progress p = Progress(lamps: <int>{1, 2, 3, 4, 5, 6});
      expect(AchievementsEngine.evaluate(p), <String>['goodness']);
      for (int d = 1; d <= 7; d++) {
        p = ProgressionRules.recordDaily(
          p, DailySeed.forKey('2026-11-${(10 + d).toString().padLeft(2, '0')}'), won: true, goals: 3);
      }
      expect(AchievementsEngine.evaluate(p), contains('faithfulness'));
    });
  });
}
