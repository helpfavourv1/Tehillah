import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/shot_params.dart';
import 'package:tehillah/game/geometry/keeper_motion.dart';
import 'package:tehillah/game/geometry/kick_timeline.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/game/geometry/shot_trajectory.dart';
import 'package:tehillah/game/tuning.dart';

const List<({String name, double w, double h})> _screens = <({String name, double w, double h})>[
  (name: 'Redmi A5 portrait', w: 360, h: 800),
  (name: 'phone portrait', w: 412, h: 915),
  (name: 'small portrait', w: 320, h: 480),
  (name: 'phone landscape', w: 915, h: 412),
  (name: 'short landscape', w: 800, h: 360),
  (name: 'square', w: 600, h: 600),
  (name: 'tablet landscape', w: 1280, h: 800),
];

void main() {
  group('PitchProjection', () {
    for (final ({String name, double w, double h}) s in _screens) {
      test('${s.name}: goal, spot and shooter are all on screen', () {
        final PitchProjection p = PitchProjection.fit(s.w, s.h);
        final ScreenRect g = p.goalRect;
        expect(g.left, greaterThanOrEqualTo(0));
        expect(g.right, lessThanOrEqualTo(s.w));
        expect(g.top, greaterThanOrEqualTo(s.h * Tuning.topMarginFrac - 0.5));
        expect(g.bottom, lessThan(s.h));
        expect(g.right - g.left, lessThanOrEqualTo(s.w * Tuning.goalWidthFrac + 0.5));
        final ScreenPoint ball = p.project(0, Tuning.ballRadius, Tuning.spotDistance)!;
        expect(ball.y, inInclusiveRange(0, s.h));
        final ScreenPoint feet = p.project(0, 0, Tuning.runUpStartZ)!;
        expect(feet.y, lessThanOrEqualTo(s.h * Tuning.feetMaxFrac + 0.5));
        final ScreenPoint head = p.project(0, Tuning.shooterHeight, Tuning.runUpStartZ)!;
        expect(head.y, greaterThan(0));
      });
    }

    test('the goal is centred and the posts are symmetric', () {
      final PitchProjection p = PitchProjection.fit(360, 800);
      final ScreenRect g = p.goalRect;
      expect((g.left + g.right) / 2, closeTo(180, 0.001));
    });

    test('nearer things are bigger and lower on screen', () {
      final PitchProjection p = PitchProjection.fit(360, 800);
      final ScreenPoint far = p.project(0, 0, 0)!;
      final ScreenPoint near = p.project(0, 0, 10)!;
      expect(near.scale, greaterThan(far.scale));
      expect(near.y, greaterThan(far.y));
    });

    test('points at or behind the camera are not projected', () {
      final PitchProjection p = PitchProjection.fit(360, 800);
      expect(p.project(0, 0, Tuning.cameraZ), isNull);
      expect(p.project(0, 0, Tuning.cameraZ + 5), isNull);
      expect(p.scaleAt(Tuning.cameraZ - Tuning.nearPlane / 2), isNull);
      expect(p.projectClamped(0, 0, Tuning.cameraZ + 5).scale.isFinite, isTrue);
    });

    test('goalPlaneAt inverts the projection at the goal line', () {
      final PitchProjection p = PitchProjection.fit(412, 915);
      final ScreenPoint s = p.project(1.7, 1.2, 0)!;
      final ({double x, double y}) back = p.goalPlaneAt(s.x, s.y);
      expect(back.x, closeTo(1.7, 1e-9));
      expect(back.y, closeTo(1.2, 1e-9));
    });

    test('zones tile the goal mouth with row 0 at the bottom', () {
      final PitchProjection p = PitchProjection.fit(360, 800);
      final ScreenRect g = p.goalRect;
      final ScreenRect bottomLeft = p.zoneRect(0, 0, columns: 3, rows: 2);
      final ScreenRect topRight = p.zoneRect(2, 1, columns: 3, rows: 2);
      expect(bottomLeft.left, closeTo(g.left, 1e-9));
      expect(bottomLeft.bottom, closeTo(g.bottom, 1e-9));
      expect(topRight.right, closeTo(g.right, 1e-9));
      expect(topRight.top, closeTo(g.top, 1e-9));
      expect(bottomLeft.top, closeTo(topRight.bottom, 1e-9));
    });

    test('a degenerate canvas does not throw or return NaN', () {
      final PitchProjection p = PitchProjection.fit(0, 0);
      expect(p.k.isFinite && p.k >= 1, isTrue);
      expect(p.goalRect.left.isFinite, isTrue);
    });
  });

  group('ShotTrajectory.targetFor', () {
    ShotParams shot(double d, double e, {double p = 0.7, double c = 0}) =>
        ShotParams(direction: d, elevation: e, power: p, curve: c);

    test('a goal ends inside the frame for every aim', () {
      for (double d = -1; d <= 1; d += 0.25) {
        for (double e = 0; e <= 1; e += 0.25) {
          final GoalPoint t = ShotTrajectory.targetFor(shot(d, e), ShotResult.goal);
          expect(t.x.abs(), lessThan(Tuning.halfGoal), reason: '$d $e');
          expect(t.y, inExclusiveRange(0, Tuning.goalHeight), reason: '$d $e');
        }
      }
    });

    test('a save ends inside the frame too', () {
      final GoalPoint t = ShotTrajectory.targetFor(shot(0.9, 0.9), ShotResult.saved);
      expect(t.x.abs(), lessThan(Tuning.halfGoal));
      expect(t.y, lessThan(Tuning.goalHeight));
    });

    test('a post hit lands on a post or the crossbar', () {
      final GoalPoint side = ShotTrajectory.targetFor(shot(0.95, 0.3), ShotResult.post);
      expect(side.x, Tuning.halfGoal);
      final GoalPoint left = ShotTrajectory.targetFor(shot(-0.95, 0.3), ShotResult.post);
      expect(left.x, -Tuning.halfGoal);
      final GoalPoint bar = ShotTrajectory.targetFor(shot(0.1, 0.95), ShotResult.post);
      expect(bar.y, Tuning.goalHeight);
      expect(bar.x.abs(), lessThan(Tuning.halfGoal));
    });

    test('a wide shot ends outside the posts on the aimed side', () {
      final GoalPoint r = ShotTrajectory.targetFor(shot(1, 0.4), ShotResult.wide);
      expect(r.x, greaterThan(Tuning.halfGoal));
      final GoalPoint l = ShotTrajectory.targetFor(shot(-1, 0.4), ShotResult.wide);
      expect(l.x, lessThan(-Tuning.halfGoal));
      final GoalPoint c = ShotTrajectory.targetFor(shot(0, 0.4), ShotResult.wide);
      expect(c.x.abs(), greaterThan(Tuning.halfGoal));
    });

    test('a high shot ends above the bar', () {
      final GoalPoint t = ShotTrajectory.targetFor(shot(0.2, 1), ShotResult.high);
      expect(t.y, greaterThan(Tuning.goalHeight));
    });

    test('flight time falls as power rises', () {
      expect(ShotTrajectory.flightSeconds(0), closeTo(Tuning.slowFlightSeconds, 1e-9));
      expect(ShotTrajectory.flightSeconds(1), closeTo(Tuning.fastFlightSeconds, 1e-9));
      expect(ShotTrajectory.flightSeconds(0.5),
          inExclusiveRange(Tuning.fastFlightSeconds, Tuning.slowFlightSeconds));
      expect(ShotTrajectory.flightSeconds(7), closeTo(Tuning.fastFlightSeconds, 1e-9));
      expect(ShotTrajectory.flightSeconds(-3), closeTo(Tuning.slowFlightSeconds, 1e-9));
    });
  });

  group('ShotTrajectory paths', () {
    const ShotParams straight = ShotParams(direction: 0.5, elevation: 0.5, power: 0.8, curve: 0);
    const ShotParams curved = ShotParams(direction: 0.5, elevation: 0.5, power: 0.8, curve: 1);

    test('flight starts on the spot and ends at the target', () {
      const GoalPoint target = (x: 1.5, y: 1.0);
      final WorldPoint a = ShotTrajectory.flightAt(straight, target, 0);
      expect(a.z, Tuning.spotDistance);
      expect(a.x, 0);
      expect(a.y, closeTo(Tuning.ballRadius, 1e-9));
      final WorldPoint b = ShotTrajectory.flightAt(curved, target, 1);
      expect(b.z, closeTo(0, 1e-9));
      expect(b.x, closeTo(target.x, 1e-9));
      expect(b.y, closeTo(target.y, 1e-9));
    });

    test('progress outside 0..1 is clamped', () {
      const GoalPoint target = (x: 1.5, y: 1.0);
      expect(ShotTrajectory.flightAt(straight, target, -5).z, Tuning.spotDistance);
      expect(ShotTrajectory.flightAt(straight, target, 5).z, closeTo(0, 1e-9));
    });

    test('curve bends the middle of the path but not the ends', () {
      const GoalPoint target = (x: 0, y: 1);
      final WorldPoint mid = ShotTrajectory.flightAt(curved, target, 0.5);
      final WorldPoint flat = ShotTrajectory.flightAt(straight, target, 0.5);
      expect(mid.x - flat.x, closeTo(Tuning.curveBulge, 1e-9));
      const ShotParams left = ShotParams(direction: 0, elevation: 0.5, power: 0.8, curve: -1);
      expect(ShotTrajectory.flightAt(left, target, 0.5).x, closeTo(-Tuning.curveBulge, 1e-9));
    });

    test('a lofted ball rises above the straight line', () {
      const GoalPoint target = (x: 0, y: 1);
      const ShotParams low = ShotParams(direction: 0, elevation: 0, power: 0.8, curve: 0);
      const ShotParams lob = ShotParams(direction: 0, elevation: 1, power: 0.8, curve: 0);
      expect(ShotTrajectory.flightAt(lob, target, 0.5).y,
          greaterThan(ShotTrajectory.flightAt(low, target, 0.5).y));
    });

    test('after contact the ball starts at the target for every result', () {
      for (final ShotResult r in ShotResult.values) {
        const GoalPoint target = (x: 1.2, y: 1.1);
        final WorldPoint p = ShotTrajectory.afterAt(r, target, 0);
        expect(p.z, closeTo(0, 1e-9), reason: '$r');
        expect(p.x, closeTo(target.x, 1e-9), reason: '$r');
        expect(p.y, closeTo(target.y, 1e-9), reason: '$r');
      }
    });

    test('a goal goes into the net, a post and a save come back', () {
      const GoalPoint target = (x: 1.2, y: 1.1);
      expect(ShotTrajectory.afterAt(ShotResult.goal, target, 2).z, closeTo(-Tuning.netDepth, 1e-9));
      expect(ShotTrajectory.afterAt(ShotResult.post, target, 2).z, greaterThan(0));
      expect(ShotTrajectory.afterAt(ShotResult.saved, target, 2).z, greaterThan(0));
      expect(ShotTrajectory.afterAt(ShotResult.wide, target, 2).z, lessThan(-Tuning.netDepth));
    });

    test('the ball never sinks below the grass', () {
      const GoalPoint target = (x: -1.2, y: 0.4);
      for (final ShotResult r in ShotResult.values) {
        for (double s = 0; s <= 5; s += 0.25) {
          expect(ShotTrajectory.afterAt(r, target, s).y, greaterThanOrEqualTo(Tuning.ballRadius));
        }
      }
    });

    test('negative time is treated as zero', () {
      const GoalPoint target = (x: 0, y: 1);
      expect(ShotTrajectory.afterAt(ShotResult.goal, target, -1).z, closeTo(0, 1e-9));
    });
  });

  group('KeeperMotion', () {
    test('the keeper starts at rest', () {
      for (final KeeperDive d in KeeperDive.values) {
        final KeeperPose p = KeeperMotion.poseAt(d, 0);
        expect(p.x, KeeperMotion.rest.x);
        expect(p.y, KeeperMotion.rest.y);
        expect(p.tilt, 0);
        expect(p.stretch, 0);
      }
    });

    test('every dive ends at its place', () {
      for (final KeeperDive d in KeeperDive.values) {
        final KeeperPose p = KeeperMotion.poseAt(d, Tuning.keeperDiveSeconds * 2);
        final GoalPoint end = KeeperMotion.diveTarget(d);
        expect(p.x, closeTo(end.x, 1e-9), reason: '$d');
        expect(p.y, closeTo(end.y, 1e-9), reason: '$d');
        expect(p.stretch, closeTo(1, 1e-9));
      }
    });

    test('left leans left, right leans right, centre stays upright', () {
      expect(KeeperMotion.poseAt(KeeperDive.leftLow, 1).tilt, lessThan(0));
      expect(KeeperMotion.poseAt(KeeperDive.rightHigh, 1).tilt, greaterThan(0));
      expect(KeeperMotion.poseAt(KeeperDive.centerHigh, 1).tilt, 0);
    });

    test('high dives end higher than low dives', () {
      expect(KeeperMotion.diveTarget(KeeperDive.leftHigh).y,
          greaterThan(KeeperMotion.diveTarget(KeeperDive.leftLow).y));
    });

    test('a save reaches the ball, not the dive place', () {
      const GoalPoint ball = (x: 1.9, y: 1.3);
      final KeeperPose p = KeeperMotion.poseAt(KeeperDive.rightHigh, 1, reachTo: ball);
      expect(p.x, closeTo(ball.x, 1e-9));
      expect(p.y, closeTo(ball.y, 1e-9));
    });

    test('the dive moves steadily outwards', () {
      double last = -1;
      for (double t = 0; t <= Tuning.keeperDiveSeconds; t += 0.05) {
        final double x = KeeperMotion.poseAt(KeeperDive.rightLow, t).x;
        expect(x, greaterThanOrEqualTo(last));
        last = x;
      }
    });

    test('negative time is the standing pose', () {
      expect(KeeperMotion.poseAt(KeeperDive.leftLow, -1).x, 0);
      expect(KeeperMotion.standing.stretch, 0);
    });
  });

  group('KickTimeline', () {
    test('stages come in order and add up', () {
      final KickTimeline t = KickTimeline(flightSeconds: 0.6);
      expect(t.phaseAt(0), KickPhase.runUp);
      expect(t.phaseAt(t.strikeAt), KickPhase.strike);
      expect(t.phaseAt(t.flightStart), KickPhase.flight);
      expect(t.phaseAt(t.contactAt), KickPhase.reaction);
      expect(t.phaseAt(t.reactionEnd), KickPhase.settle);
      expect(t.phaseAt(t.total), KickPhase.done);
      expect(t.total,
          closeTo(Tuning.runUpSeconds + Tuning.strikeSeconds + 0.6 + Tuning.reactionSeconds + Tuning.settleSeconds, 1e-9));
    });

    test('flight progress is 0 before and 1 after', () {
      final KickTimeline t = KickTimeline(flightSeconds: 0.5);
      expect(t.flightProgress(0), 0);
      expect(t.flightProgress(t.flightStart + 0.25), closeTo(0.5, 1e-9));
      expect(t.flightProgress(100), 1);
    });

    test('the keeper goes with the strike, contact time is counted from the goal line', () {
      final KickTimeline t = KickTimeline(flightSeconds: 0.5);
      expect(t.keeperSeconds(0), 0);
      expect(t.keeperSeconds(t.flightStart + 0.2), closeTo(0.2, 1e-9));
      expect(t.sinceContact(t.contactAt - 0.1), 0);
      expect(t.sinceContact(t.contactAt + 0.3), closeTo(0.3, 1e-9));
    });

    test('reduce motion skips the run-up and keeps the flight', () {
      final KickTimeline t = KickTimeline(flightSeconds: 0.5, reduceMotion: true);
      expect(t.runUp, 0);
      expect(t.phaseAt(0), KickPhase.strike);
      expect(t.runUpProgress(0), 1);
      expect(t.flightStart, Tuning.strikeSeconds);
      expect(t.contactAt - t.flightStart, 0.5);
    });

    test('isDone', () {
      final KickTimeline t = KickTimeline(flightSeconds: 0.5);
      expect(t.isDone(t.total - 0.01), isFalse);
      expect(t.isDone(t.total), isTrue);
    });
  });
}
