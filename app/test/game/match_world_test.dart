import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/models/kick_record.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/shot_params.dart';
import 'package:tehillah/game/geometry/keeper_motion.dart';
import 'package:tehillah/game/geometry/kick_timeline.dart';
import 'package:tehillah/game/geometry/shot_trajectory.dart';
import 'package:tehillah/game/match_world.dart';
import 'package:tehillah/game/tuning.dart';

KickRecord kick(
  ShotResult result, {
  KeeperDive dive = KeeperDive.leftLow,
  MatchSide side = MatchSide.player,
  ShotParams params = const ShotParams(direction: 0.5, elevation: 0.4, power: 0.8, curve: 0),
}) {
  return KickRecord(side: side, round: 1, params: params, outcome: ShotOutcome(result, dive));
}

/// Steps the world in 60 fps frames for [seconds].
void advance(MatchWorld w, double seconds) {
  double left = seconds;
  while (left > 1e-9) {
    final double dt = left < 1 / 60 ? left : 1 / 60;
    w.update(dt);
    left -= dt;
  }
}

void main() {
  group('MatchWorld idle', () {
    test('ball on the spot, keeper standing, shooter waiting', () {
      final MatchWorld w = MatchWorld();
      expect(w.isPlaying, isFalse);
      expect(w.ballPosition, (x: 0.0, y: Tuning.ballRadius, z: Tuning.spotDistance));
      expect(w.keeperPose.stretch, 0);
      expect(w.shooter, (x: Tuning.shooterX, z: Tuning.runUpStartZ, swing: 0.0));
      expect(w.netRipple, 0);
      expect(w.contact, isNull);
      expect(w.ballBehindGoalLine, isFalse);
      expect(w.phase, KickPhase.done);
    });

    test('idle shooter is the one set for the next kick', () {
      final MatchWorld w = MatchWorld()..idleShooter = MatchSide.opponent;
      expect(w.shooterSide, MatchSide.opponent);
    });

    test('update with nothing playing is harmless', () {
      final MatchWorld w = MatchWorld();
      expect(() => advance(w, 1), returnsNormally);
    });
  });

  group('MatchWorld playing a kick', () {
    test('runs through every phase and calls back exactly once', () {
      final MatchWorld w = MatchWorld();
      int finished = 0;
      w.onKickFinished = () => finished++;
      w.play(kick(ShotResult.goal));
      final List<KickPhase> seen = <KickPhase>[];
      for (int i = 0; i < 600 && w.isPlaying; i++) {
        w.update(1 / 60);
        if (w.isPlaying && (seen.isEmpty || seen.last != w.phase)) {
          seen.add(w.phase);
        }
      }
      expect(seen, <KickPhase>[
        KickPhase.runUp,
        KickPhase.strike,
        KickPhase.flight,
        KickPhase.reaction,
        KickPhase.settle,
      ]);
      expect(finished, 1);
      expect(w.isPlaying, isFalse);
      advance(w, 2);
      expect(finished, 1);
    });

    test('everything returns to waiting when the kick ends', () {
      final MatchWorld w = MatchWorld();
      w.play(kick(ShotResult.saved));
      advance(w, 10);
      expect(w.ballPosition.z, Tuning.spotDistance);
      expect(w.keeperPose.stretch, 0);
      expect(w.shooter.z, Tuning.runUpStartZ);
    });

    test('the ball waits on the spot until the strike, then flies and reaches the goal line', () {
      final MatchWorld w = MatchWorld();
      final KickRecord r = kick(ShotResult.goal);
      w.play(r);
      final KickTimeline t = w.script!.timeline;
      advance(w, t.flightStart - 0.02);
      expect(w.ballPosition.z, Tuning.spotDistance);
      advance(w, 0.02 + t.contactAt - t.flightStart - 0.05);
      expect(w.ballPosition.z, inExclusiveRange(0, Tuning.spotDistance));
      advance(w, 0.1);
      expect(w.ballPosition.z, lessThanOrEqualTo(0));
      expect(w.contact, isNotNull);
    });

    test('every result ends where the rules say', () {
      for (final ShotResult result in ShotResult.values) {
        final MatchWorld w = MatchWorld();
        final KickRecord r = kick(result, params: const ShotParams(direction: 0.9, elevation: 0.3, power: 0.9, curve: 0));
        w.play(r);
        advance(w, w.script!.timeline.contactAt + 0.01);
        final GoalPoint target = ShotTrajectory.targetFor(r.params, result);
        expect(w.contact, target, reason: '$result');
        final WorldPoint b = w.ballPosition;
        expect(b.x, closeTo(target.x, 0.1), reason: '$result');
        switch (result) {
          case ShotResult.goal:
            expect(target.x.abs(), lessThan(Tuning.halfGoal));
          case ShotResult.wide:
            expect(target.x.abs(), greaterThan(Tuning.halfGoal));
          case ShotResult.high:
            expect(target.y, greaterThan(Tuning.goalHeight));
          case ShotResult.post:
          case ShotResult.saved:
            break;
        }
      }
    });

    test('the keeper dives with the strike to the place chosen', () {
      final MatchWorld w = MatchWorld();
      w.play(kick(ShotResult.goal, dive: KeeperDive.rightHigh));
      advance(w, w.script!.timeline.flightStart - 0.01);
      expect(w.keeperPose.stretch, 0);
      advance(w, 0.01 + Tuning.keeperDiveSeconds + 0.05);
      final KeeperPose pose = w.keeperPose;
      final GoalPoint end = KeeperMotion.diveTarget(KeeperDive.rightHigh);
      expect(pose.x, closeTo(end.x, 1e-6));
      expect(pose.y, closeTo(end.y, 1e-6));
    });

    test('on a save the keeper ends at the ball', () {
      final MatchWorld w = MatchWorld();
      final KickRecord r = kick(ShotResult.saved, dive: KeeperDive.rightHigh);
      w.play(r);
      advance(w, w.script!.timeline.contactAt);
      final GoalPoint target = ShotTrajectory.targetFor(r.params, ShotResult.saved);
      expect(w.keeperPose.x, closeTo(target.x, 1e-6));
      expect(w.keeperPose.y, closeTo(target.y, 1e-6));
    });

    test('the kit is by who is kicking', () {
      final MatchWorld w = MatchWorld();
      w.play(kick(ShotResult.goal, side: MatchSide.opponent));
      expect(w.shooterSide, MatchSide.opponent);
    });

    test('the shooter runs up, then the leg swings', () {
      final MatchWorld w = MatchWorld();
      w.play(kick(ShotResult.goal));
      final KickTimeline t = w.script!.timeline;
      advance(w, t.runUp / 2);
      expect(w.shooter.z, inExclusiveRange(Tuning.strikeZ, Tuning.runUpStartZ));
      expect(w.shooter.swing, 0);
      advance(w, t.runUp / 2 + Tuning.strikeSeconds / 2);
      expect(w.shooter.swing, closeTo(0.5, 0.15));
      advance(w, Tuning.strikeSeconds);
      expect(w.shooter.swing, 1);
      expect(w.shooter.z, closeTo(Tuning.strikeZ, 1e-9));
    });

    test('the ball is behind the line, under the frame, only after a goal or miss', () {
      final MatchWorld w = MatchWorld();
      w.play(kick(ShotResult.goal));
      advance(w, w.script!.timeline.contactAt + 0.5);
      expect(w.ballBehindGoalLine, isTrue);
      final MatchWorld s = MatchWorld();
      s.play(kick(ShotResult.saved));
      advance(s, s.script!.timeline.contactAt + 0.5);
      expect(s.ballBehindGoalLine, isFalse);
    });

    test('the ball spins faster for a harder kick', () {
      final MatchWorld soft = MatchWorld();
      soft.play(kick(ShotResult.goal, params: const ShotParams(direction: 0, elevation: 0.4, power: 0, curve: 0)));
      advance(soft, soft.script!.timeline.contactAt);
      final MatchWorld hard = MatchWorld();
      hard.play(kick(ShotResult.goal, params: const ShotParams(direction: 0, elevation: 0.4, power: 1, curve: 0)));
      advance(hard, hard.script!.timeline.contactAt);
      expect(hard.ballSpin, greaterThan(soft.ballSpin));
    });
  });

  group('MatchWorld control', () {
    test('skip finishes on the next update', () {
      final MatchWorld w = MatchWorld();
      int finished = 0;
      w.onKickFinished = () => finished++;
      w.play(kick(ShotResult.goal));
      advance(w, 0.1);
      w.skip();
      expect(finished, 0);
      w.update(1 / 60);
      expect(finished, 1);
      expect(w.isPlaying, isFalse);
    });

    test('skip with nothing playing does nothing', () {
      final MatchWorld w = MatchWorld();
      expect(w.skip, returnsNormally);
    });

    test('reset drops the kick without calling back', () {
      final MatchWorld w = MatchWorld();
      int finished = 0;
      w.onKickFinished = () => finished++;
      w.play(kick(ShotResult.goal));
      advance(w, 0.3);
      w.reset();
      expect(w.isPlaying, isFalse);
      advance(w, 5);
      expect(finished, 0);
    });

    test('playing a new kick replaces the one on screen without a callback', () {
      final MatchWorld w = MatchWorld();
      int finished = 0;
      w.onKickFinished = () => finished++;
      w.play(kick(ShotResult.goal));
      advance(w, 0.3);
      w.play(kick(ShotResult.wide));
      expect(w.elapsed, 0);
      expect(w.script!.result, ShotResult.wide);
      expect(finished, 0);
    });

    test('a huge frame time advances only a tenth of a second', () {
      final MatchWorld w = MatchWorld();
      w.play(kick(ShotResult.goal));
      w.update(30);
      expect(w.elapsed, closeTo(0.1, 1e-9));
      w.update(-5);
      expect(w.elapsed, closeTo(0.1, 1e-9));
    });
  });

  group('MatchWorld effects and Reduce Motion', () {
    test('the net shakes after a goal and settles', () {
      final MatchWorld w = MatchWorld();
      w.play(kick(ShotResult.goal));
      advance(w, w.script!.timeline.contactAt - 0.05);
      expect(w.netRipple, 0);
      advance(w, 0.1);
      expect(w.netRipple, greaterThan(0.8));
      advance(w, Tuning.netRippleSeconds + 0.1);
      expect(w.netRipple, 0);
    });

    test('only a goal shakes the net', () {
      for (final ShotResult r in <ShotResult>[
        ShotResult.saved,
        ShotResult.post,
        ShotResult.wide,
        ShotResult.high,
      ]) {
        final MatchWorld w = MatchWorld();
        w.play(kick(r));
        advance(w, w.script!.timeline.contactAt + 0.1);
        expect(w.netRipple, 0, reason: '$r');
      }
    });

    test('Reduce Motion skips the run-up and the net shake but keeps the flight', () {
      final MatchWorld w = MatchWorld()..reduceMotion = true;
      w.play(kick(ShotResult.goal));
      expect(w.script!.timeline.runUp, 0);
      expect(w.shooter.z, closeTo(Tuning.strikeZ, 1e-9));
      advance(w, w.script!.timeline.contactAt + 0.1);
      expect(w.netRipple, 0);
      expect(w.script!.timeline.contactAt - w.script!.timeline.flightStart,
          closeTo(ShotTrajectory.flightSeconds(0.8), 1e-9));
    });
  });
}
