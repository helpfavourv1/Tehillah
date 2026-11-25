import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/logic/match_rules.dart';
import 'package:tehillah/core/logic/modifiers.dart';
import 'package:tehillah/core/logic/progression_rules.dart';
import 'package:tehillah/core/logic/rating_rules.dart';
import 'package:tehillah/core/logic/reward_rules.dart';
import 'package:tehillah/core/logic/update_rules.dart';
import 'package:tehillah/core/models/daily_challenge.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/match_state.dart';
import 'package:tehillah/core/models/progress.dart';

import '../../support/match_helpers.dart';

Progress played(Iterable<String> days, {Iterable<String> rescued = const <String>[]}) => Progress(
      dailyHistory: <String, DailyRecord>{
        for (final String d in days) d: DailyRecord(dateKey: d, won: true, goals: 3),
      },
      rescuedDays: rescued.toSet(),
    );

void main() {
  group('extra Selah', () {
    test('adds one pause before the first kick', () {
      final MatchConfig base = configFor();
      final MatchState plain = MatchRules.start(base, Modifiers.none);
      final MatchState boosted = MatchRules.start(RewardRules.withExtraSelah(base), Modifiers.none);
      expect(boosted.selahCharges, plain.selahCharges + 1);
    });

    test('is offered once per match', () {
      final MatchConfig base = configFor();
      expect(RewardRules.canOfferExtraSelah(base), isTrue);
      expect(RewardRules.canOfferExtraSelah(RewardRules.withExtraSelah(base)), isFalse);
    });

    test('survives the match config round trip, and old saves read as zero', () {
      final MatchConfig boosted = RewardRules.withExtraSelah(configFor());
      expect(MatchConfig.fromJson(boosted.toJson()), boosted);
      final Map<String, Object?> old = configFor().toJson()..remove('bonusSelah');
      expect(MatchConfig.fromJson(old).bonusSelah, 0);
    });

    test('cannot exceed the cap', () {
      final Map<String, Object?> j = configFor().toJson()..['bonusSelah'] = 2;
      expect(() => MatchConfig.fromJson(j), throwsFormatException);
    });
  });

  group('streak rescue', () {
    test('offers exactly the one missed day', () {
      final Progress p = played(<String>['2026-11-20', '2026-11-21']);
      expect(RewardRules.restorableDay(p, '2026-11-23'), '2026-11-22');
    });

    test('nothing to restore when today or yesterday is already played', () {
      expect(RewardRules.restorableDay(played(<String>['2026-11-22']), '2026-11-23'), isNull);
      expect(RewardRules.restorableDay(played(<String>['2026-11-23']), '2026-11-23'), isNull);
    });

    test('two missed days cannot be restored', () {
      expect(RewardRules.restorableDay(played(<String>['2026-11-20']), '2026-11-23'), isNull);
    });

    test('a streak with no history cannot be restored', () {
      expect(RewardRules.restorableDay(Progress.empty(), '2026-11-23'), isNull);
    });

    test('restoring keeps the streak alive and counts toward the longest', () {
      Progress p = played(<String>['2026-11-19', '2026-11-20', '2026-11-21']);
      expect(ProgressionRules.currentDailyStreak(p, '2026-11-23'), 0);
      p = RewardRules.restoreStreak(p, '2026-11-23');
      expect(p.rescuedDays, <String>{'2026-11-22'});
      expect(ProgressionRules.currentDailyStreak(p, '2026-11-23'), 4);
      expect(ProgressionRules.longestDailyStreak(p), 4);
    });

    test('restoring when there is nothing to restore changes nothing', () {
      final Progress p = played(<String>['2026-11-23']);
      expect(identical(RewardRules.restoreStreak(p, '2026-11-23'), p), isTrue);
    });

    test('only once per calendar week (Monday to Sunday)', () {
      // 2026-11-23 is a Monday. Day 24 missed on the 25th, restored; the 26th is
      // missed on the 27th in the same week, so a second restore is refused.
      Progress p = played(<String>['2026-11-23']);
      expect(RewardRules.restorableDay(p, '2026-11-25'), '2026-11-24');
      p = RewardRules.restoreStreak(p, '2026-11-25');
      p = p.copyWith(dailyHistory: <String, DailyRecord>{
        ...p.dailyHistory,
        '2026-11-25': const DailyRecord(dateKey: '2026-11-25', won: true, goals: 1),
      });
      expect(RewardRules.restorableDay(p, '2026-11-27'), isNull);
    });

    test('a new week allows another', () {
      Progress p = played(<String>['2026-11-23'], rescued: <String>['2026-11-24']);
      p = p.copyWith(dailyHistory: <String, DailyRecord>{
        ...p.dailyHistory,
        '2026-11-30': const DailyRecord(dateKey: '2026-11-30', won: true, goals: 1),
      });
      expect(RewardRules.restorableDay(p, '2026-12-02'), '2026-12-01');
    });

    test('extra stones is three', () {
      expect(RewardRules.extraStones, 3);
    });
  });

  group('rating prompt', () {
    test('only once, only after a stage win', () {
      final Progress fresh = Progress.empty();
      expect(RatingRules.shouldPrompt(fresh, won: true, stageCleared: true), isTrue);
      expect(RatingRules.shouldPrompt(fresh, won: false, stageCleared: true), isFalse);
      expect(RatingRules.shouldPrompt(fresh, won: true, stageCleared: false), isFalse);
      expect(
        RatingRules.shouldPrompt(fresh.copyWith(ratingPromptShown: true), won: true, stageCleared: true),
        isFalse,
      );
    });
  });

  group('update prompt', () {
    test('only when the store has a newer build the user has not dismissed', () {
      bool ask(int current, int latest, int dismissed) => UpdateRules.shouldPrompt(
            currentBuild: current,
            latestBuild: latest,
            dismissedBuild: dismissed,
          );
      expect(ask(1, 2, 0), isTrue);
      expect(ask(2, 2, 0), isFalse);
      expect(ask(3, 2, 0), isFalse);
      expect(ask(1, 0, 0), isFalse);
      expect(ask(1, 2, 2), isFalse);
      expect(ask(1, 3, 2), isTrue);
    });
  });
}
