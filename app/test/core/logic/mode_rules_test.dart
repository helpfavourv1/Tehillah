import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/catalog/stage_catalog.dart';
import 'package:tehillah/core/logic/daily_seed.dart';
import 'package:tehillah/core/logic/mode_rules.dart';
import 'package:tehillah/core/logic/modifiers.dart';
import 'package:tehillah/core/models/daily_challenge.dart';
import 'package:tehillah/core/models/loadout.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/opponent_def.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/models/shot_params.dart';

void main() {
  final OpponentDef opp = StageCatalog.stages[4].opponents[1];

  test('modes unlock after the stages the blueprint names', () {
    final Progress none = Progress();
    expect(ModeRules.isUnlocked(MatchMode.journey, none), isTrue);
    expect(ModeRules.isUnlocked(MatchMode.dailyBread, none), isTrue);
    expect(ModeRules.isUnlocked(MatchMode.friendly, none), isFalse);
    expect(ModeRules.isUnlocked(MatchMode.friendly, Progress(lamps: <int>{1})), isTrue);
    expect(ModeRules.isUnlocked(MatchMode.watchman, Progress(lamps: <int>{1, 2})), isFalse);
    expect(ModeRules.isUnlocked(MatchMode.watchman, Progress(lamps: <int>{3})), isTrue);
    expect(ModeRules.isUnlocked(MatchMode.jericho, Progress(lamps: <int>{5})), isTrue);
    expect(ModeRules.isUnlocked(MatchMode.slingAndStone, Progress(lamps: <int>{6})), isTrue);
  });

  test('Seven Days opens after the first Daily Bread', () {
    expect(ModeRules.isUnlocked(MatchMode.sevenDays, Progress()), isFalse);
    final Progress p = Progress(dailyHistory: <String, DailyRecord>{
      '2026-11-19': const DailyRecord(dateKey: '2026-11-19', won: true, goals: 4),
    });
    expect(ModeRules.isUnlocked(MatchMode.sevenDays, p), isTrue);
  });

  test('journey config copies the stage and the round\'s opponent', () {
    final c = ModeRules.journey(
      stage: StageCatalog.stages[2], round: 3, loadout: Loadout.starter, seed: 9);
    expect(c.mode, MatchMode.journey);
    expect(c.stageId, 3);
    expect(c.round, 3);
    expect(c.opponent, StageCatalog.stages[2].opponents[2]);
    expect(c.difficulty, StageCatalog.stages[2].difficulty);
    expect(() => ModeRules.journey(
      stage: StageCatalog.stages[2], round: 5, loadout: Loadout.starter, seed: 1), throwsRangeError);
  });

  test('friendly and watchman take difficulty from the opponent', () {
    final MatchConfig f = ModeRules.friendly(opponent: opp, loadout: Loadout.starter, seed: 1);
    expect(f.difficulty, closeTo(ModeRules.difficultyOf(opp), 1e-12));
    expect(f.mode, MatchMode.friendly);
    expect(ModeRules.watchman(opponent: opp, loadout: Loadout.starter, seed: 1).mode, MatchMode.watchman);
    expect(ModeRules.difficultyOf(opp), inInclusiveRange(0, 1));
  });

  test('Jericho gets harder each of its seven rounds', () {
    double last = -1;
    for (int r = 1; r <= ModeRules.jerichoRounds; r++) {
      final MatchConfig c = ModeRules.jericho(opponent: opp, round: r, loadout: Loadout.starter, seed: r);
      expect(c.difficulty, greaterThanOrEqualTo(last));
      last = c.difficulty;
    }
    expect(() => ModeRules.jericho(opponent: opp, round: 8, loadout: Loadout.starter, seed: 1), throwsRangeError);
    expect(() => ModeRules.jericho(opponent: opp, round: 0, loadout: Loadout.starter, seed: 1), throwsRangeError);
  });

  test('Seven Days has a theme for each day and counts days from the start', () {
    for (int d = 1; d <= 7; d++) {
      final MatchConfig c = ModeRules.sevenDays(day: d, opponent: opp, loadout: Loadout.starter, seed: d);
      expect(c.kicksPerSide, ModeRules.sevenDaysThemes[d - 1].kicks);
      expect(c.difficulty, lessThanOrEqualTo(1));
    }
    expect(() => ModeRules.sevenDays(day: 8, opponent: opp, loadout: Loadout.starter, seed: 1), throwsRangeError);
    expect(ModeRules.sevenDaysDay('2026-11-10', '2026-11-10'), 1);
    expect(ModeRules.sevenDaysDay('2026-11-10', '2026-11-16'), 7);
    expect(ModeRules.sevenDaysDay('2026-11-10', '2026-11-17'), isNull);
    expect(ModeRules.sevenDaysDay('2026-11-10', '2026-11-09'), isNull);
  });

  test('Daily Bread always uses the starter loadout and the challenge seed', () {
    final DailyChallenge ch = DailySeed.forKey('2026-11-19');
    final MatchConfig c = ModeRules.daily(ch);
    expect(c.loadout, Loadout.starter);
    expect(c.seed, ch.seed);
    expect(c.opponent, ch.opponent);
  });

  test('allOpponents lists every stage opponent in order', () {
    expect(ModeRules.allOpponents().length, 12 * StageCatalog.roundsPerStage);
  });

  group('Sling and Stone', () {
    test('targets are the same for the same seed and differ across seeds', () {
      final a = SlingAndStone.targetsFor(5);
      final b = SlingAndStone.targetsFor(5);
      expect(a.length, SlingAndStone.targets);
      expect(a.map((t) => t.centerX).toList(), b.map((t) => t.centerX).toList());
      expect(SlingAndStone.targetsFor(6).first.centerX, isNot(a.first.centerX));
    });

    test('a target slides within its amplitude', () {
      final SlingTarget t = SlingAndStone.targetsFor(3).first;
      for (double s = 0; s < 20; s += 0.37) {
        expect((t.xAt(s) - t.centerX).abs(), lessThanOrEqualTo(t.amplitude + 1e-9));
      }
    });

    test('a stone aimed at the target hits and one aimed far away misses', () {
      final SlingTarget t = SlingAndStone.targetsFor(3).first;
      final double x = t.xAt(0);
      final ShotParams onIt = ShotParams(
        direction: x.clamp(-1.0, 1.0), elevation: t.y.clamp(0.0, 1.0), power: 0.7, curve: 0);
      expect(SlingAndStone.hits(shot: onIt, target: t, seconds: 0, mods: Modifiers.none), isTrue);
      final ShotParams away = ShotParams(
        direction: x > 0 ? -1.0 : 1.0, elevation: 0.1, power: 0.7, curve: 0);
      expect(SlingAndStone.hits(shot: away, target: t, seconds: 0, mods: Modifiers.none), isFalse);
    });

    test('aim forgiveness widens the hit area and stars follow hits', () {
      final SlingTarget t = SlingAndStone.targetsFor(3).first;
      final double x = t.xAt(0);
      final ShotParams near = ShotParams(
        direction: (x + t.radius * 1.3).clamp(-1.0, 1.0), elevation: t.y.clamp(0.0, 1.0), power: 0.7, curve: 0);
      expect(SlingAndStone.hits(shot: near, target: t, seconds: 0, mods: Modifiers.none), isFalse);
      expect(SlingAndStone.hits(shot: near, target: t, seconds: 0, mods: const Modifiers(aimForgiveness: 0.4)), isTrue);
      expect(<int>[0, 2, 3, 4, 5].map(SlingAndStone.stars).toList(), <int>[0, 0, 1, 2, 3]);
    });
  });
}
