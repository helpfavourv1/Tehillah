import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/logic/mode_rules.dart';
import 'package:tehillah/core/logic/progression_rules.dart';
import 'package:tehillah/core/logic/sling_rules.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/models/shot_params.dart';

ShotParams aimAt(SlingTarget t, double seconds) => ShotParams(
      direction: t.xAt(seconds).clamp(-1.0, 1.0),
      elevation: t.y,
      power: 0.8,
      curve: 0,
    );

const ShotParams miss = ShotParams(direction: 0, elevation: 1, power: 0.5, curve: 0);

void main() {
  group('SlingRules', () {
    test('start gives 7 stones and 5 targets, same for the same seed', () {
      final SlingState a = SlingRules.start(11);
      expect(a.stonesLeft, 7);
      expect(a.targets, hasLength(5));
      expect(a.finished, isFalse);
      expect(SlingRules.start(11).targets.first.centerX, a.targets.first.centerX);
    });

    test('a stone aimed at a target hits it', () {
      final SlingState s = SlingRules.start(3);
      final SlingState n = SlingRules.throwStone(s, shot: aimAt(s.targets[4], 0), seconds: 0);
      expect(n.hit, contains(4));
      expect(n.stonesLeft, 6);
      expect(n.last!.isHit, isTrue);
    });

    test('a stone at the top edge misses and costs a stone', () {
      final SlingState s = SlingRules.start(3);
      final SlingState n = SlingRules.throwStone(s, shot: miss, seconds: 0);
      expect(n.hits, 0);
      expect(n.stonesLeft, 6);
      expect(n.thrown, 1);
      expect(n.last!.isHit, isFalse);
    });

    test('a target cannot be hit twice', () {
      final SlingState s = SlingRules.start(3);
      final SlingState a = SlingRules.throwStone(s, shot: aimAt(s.targets[4], 0), seconds: 0);
      final SlingState b = SlingRules.throwStone(a, shot: aimAt(s.targets[4], 0), seconds: 0);
      expect(b.last!.hitIndex, isNot(4));
      expect(b.hit, contains(4));
    });

    test('the round finishes when stones run out', () {
      SlingState s = SlingRules.start(3);
      for (int i = 0; i < 7; i++) {
        s = SlingRules.throwStone(s, shot: miss, seconds: 0);
      }
      expect(s.finished, isTrue);
      expect(s.stars, 0);
      expect(s.canOfferExtraStones, isTrue);
    });

    test('hitting every target finishes with three stars and stones left', () {
      SlingState s = SlingRules.start(3);
      final List<SlingTarget> targets = s.targets;
      for (int i = 4; i >= 0 && !s.finished; i--) {
        s = SlingRules.throwStone(s, shot: aimAt(targets[i], 0), seconds: 0);
      }
      expect(s.allHit, isTrue);
      expect(s.finished, isTrue);
      expect(s.stars, 3);
      expect(s.stonesLeft, 2);
      expect(s.canOfferExtraStones, isFalse);
    });

    test('a throw after the round ends is a state error', () {
      SlingState s = SlingRules.start(3);
      for (int i = 0; i < 7; i++) {
        s = SlingRules.throwStone(s, shot: miss, seconds: 0);
      }
      expect(() => SlingRules.throwStone(s, shot: miss, seconds: 0), throwsStateError);
    });

    test('a negative time is rejected', () {
      expect(
        () => SlingRules.throwStone(SlingRules.start(3), shot: miss, seconds: -1),
        throwsArgumentError,
      );
    });

    test('extra stones are added once, and only after a round that ended short', () {
      final SlingState fresh = SlingRules.start(3);
      expect(identical(SlingRules.addExtraStones(fresh), fresh), isTrue);
      SlingState s = fresh;
      for (int i = 0; i < 7; i++) {
        s = SlingRules.throwStone(s, shot: miss, seconds: 0);
      }
      final SlingState more = SlingRules.addExtraStones(s);
      expect(more.stonesLeft, 3);
      expect(more.finished, isFalse);
      expect(more.bonusApplied, isTrue);
      SlingState end = more;
      for (int i = 0; i < 3; i++) {
        end = SlingRules.throwStone(end, shot: miss, seconds: 0);
      }
      expect(end.canOfferExtraStones, isFalse);
      expect(identical(SlingRules.addExtraStones(end), end), isTrue);
    });
  });

  group('Jericho and Sling progression', () {
    test('rounds advance in order and finish the run', () {
      Progress p = Progress.empty();
      expect(ProgressionRules.nextJerichoRound(p), 1);
      for (int r = 1; r <= ModeRules.jerichoRounds; r++) {
        p = ProgressionRules.recordJericho(p, round: r, won: true);
      }
      expect(p.jerichoCleared, 0);
      expect(p.jerichoCompletions, 1);
    });

    test('a win records the round', () {
      final Progress p = ProgressionRules.recordJericho(Progress.empty(), round: 1, won: true);
      expect(p.jerichoCleared, 1);
      expect(ProgressionRules.nextJerichoRound(p), 2);
    });

    test('a loss sends the run back to round 1', () {
      Progress p = ProgressionRules.recordJericho(Progress.empty(), round: 1, won: true);
      p = ProgressionRules.recordJericho(p, round: 2, won: false);
      expect(p.jerichoCleared, 0);
      expect(p.jerichoCompletions, 0);
    });

    test('out-of-order rounds are ignored', () {
      final Progress p = Progress.empty();
      expect(ProgressionRules.recordJericho(p, round: 3, won: true), p);
      expect(ProgressionRules.recordJericho(p, round: 8, won: true), p);
    });

    test('recordSling counts plays and keeps the best', () {
      Progress p = ProgressionRules.recordSling(Progress.empty(), stars: 2);
      p = ProgressionRules.recordSling(p, stars: 1);
      expect(p.slingPlays, 2);
      expect(p.slingBest, 2);
      p = ProgressionRules.recordSling(p, stars: 9);
      expect(p.slingBest, 3);
    });
  });
}
