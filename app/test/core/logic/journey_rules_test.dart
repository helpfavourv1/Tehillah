import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/catalog/stage_catalog.dart';
import 'package:tehillah/core/logic/progression_rules.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/models/stage_def.dart';

Progress withStars(Map<String, int> stars) {
  Progress p = Progress.empty().copyWith(matchStars: stars);
  p = p.copyWith(lamps: ProgressionRules.lampsEarned(p));
  return p;
}

Map<String, int> allRounds(StageDef s, int stars, {int upTo = 4}) => <String, int>{
      for (int r = 0; r < upTo; r++) s.opponents[r].id: stars,
    };

void main() {
  final StageDef s1 = StageCatalog.stages[0];
  final StageDef s2 = StageCatalog.stages[1];

  test('a new career has only stage 1 open and starts at its round 1', () {
    final Progress p = Progress.empty();
    expect(ProgressionRules.stageUnlocked(p, 1), isTrue);
    expect(ProgressionRules.stageUnlocked(p, 2), isFalse);
    final next = ProgressionRules.nextJourneyMatch(p)!;
    expect(next.stage.id, 1);
    expect(next.round, 1);
  });

  test('rounds open one at a time', () {
    Progress p = Progress.empty();
    expect(ProgressionRules.roundUnlocked(p, s1, 1), isTrue);
    expect(ProgressionRules.roundUnlocked(p, s1, 2), isFalse);
    p = withStars(<String, int>{s1.opponents[0].id: 1});
    expect(ProgressionRules.roundUnlocked(p, s1, 2), isTrue);
    expect(ProgressionRules.roundUnlocked(p, s1, 3), isFalse);
    expect(ProgressionRules.roundUnlocked(p, s1, 0), isFalse);
    expect(ProgressionRules.roundUnlocked(p, s1, 5), isFalse);
  });

  test('clearing a stage opens the next and moves the continue point', () {
    final Progress p = withStars(allRounds(s1, 1));
    expect(p.lamps, contains(1));
    expect(ProgressionRules.stageUnlocked(p, 2), isTrue);
    expect(ProgressionRules.roundUnlocked(p, s2, 1), isTrue);
    final next = ProgressionRules.nextJourneyMatch(p)!;
    expect(next.stage.id, 2);
    expect(next.round, 1);
  });

  test('a round in a locked stage is never open', () {
    expect(ProgressionRules.roundUnlocked(Progress.empty(), s2, 1), isFalse);
  });

  test('stage stars and rounds cleared are counted', () {
    final Progress p = withStars(<String, int>{
      s1.opponents[0].id: 3,
      s1.opponents[1].id: 2,
      s1.opponents[2].id: 0,
    });
    expect(ProgressionRules.stageStars(p, s1), 5);
    expect(ProgressionRules.roundsCleared(p, s1), 2);
  });

  test('suggested round: first without a star, then first below three, then 1', () {
    expect(ProgressionRules.suggestedRound(Progress.empty(), s1), 1);
    expect(
      ProgressionRules.suggestedRound(withStars(<String, int>{s1.opponents[0].id: 1}), s1),
      2,
    );
    expect(
      ProgressionRules.suggestedRound(
        withStars(<String, int>{
          s1.opponents[0].id: 3,
          s1.opponents[1].id: 3,
          s1.opponents[2].id: 2,
          s1.opponents[3].id: 3,
        }),
        s1,
      ),
      3,
    );
    expect(ProgressionRules.suggestedRound(withStars(allRounds(s1, 3)), s1), 1);
  });

  test('with every stage cleared there is nothing to continue', () {
    final Map<String, int> all = <String, int>{
      for (final StageDef s in StageCatalog.stages) ...allRounds(s, 1),
    };
    expect(ProgressionRules.nextJourneyMatch(withStars(all)), isNull);
  });
}
