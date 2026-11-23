import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:tehillah/core/models/kick_record.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/game/geometry/keeper_motion.dart';
import 'package:tehillah/game/geometry/kick_timeline.dart';
import 'package:tehillah/game/geometry/shot_trajectory.dart';
import 'package:tehillah/game/tuning.dart';

/// Where the shooter is and how far the kicking leg has swung.
typedef ShooterState = ({double x, double z, double swing});

/// One kick being played: the rules' record plus the pictures derived from it.
final class KickScript {
  KickScript({required this.record, required bool reduceMotion})
      : target = ShotTrajectory.targetFor(record.params, record.outcome.result),
        timeline = KickTimeline(
          flightSeconds: ShotTrajectory.flightSeconds(record.params.power),
          reduceMotion: reduceMotion,
        );

  final KickRecord record;
  final GoalPoint target;
  final KickTimeline timeline;

  ShotResult get result => record.outcome.result;
}

/// The scene's state: which kick is playing and where everything is at this
/// moment. Components only read from here, so the whole sequence can be tested
/// without drawing anything. The match rules have already decided the result by
/// the time [play] is called; this just shows it.
class MatchWorld extends Component {
  /// Called once when a kick's animation has finished.
  void Function()? onKickFinished;

  /// Skip decorative motion: the run-up, net ripple and effects.
  bool reduceMotion = false;

  /// How many marks the ball carries (1 to 9, one per fruit).
  int ballMarks = 1;

  /// Who stands at the ball between kicks.
  MatchSide idleShooter = MatchSide.player;

  KickScript? _script;
  double _elapsed = 0;

  bool get isPlaying => _script != null;

  KickScript? get script => _script;

  double get elapsed => _elapsed;

  /// Starts showing [record]. A kick already on screen is dropped without
  /// calling [onKickFinished].
  void play(KickRecord record) {
    _script = KickScript(record: record, reduceMotion: reduceMotion);
    _elapsed = 0;
  }

  /// Jumps to the end of the kick on screen; it finishes on the next update.
  void skip() {
    final KickScript? s = _script;
    if (s != null) {
      _elapsed = s.timeline.total;
    }
  }

  /// Puts everything back to waiting, without calling [onKickFinished].
  void reset() {
    _script = null;
    _elapsed = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final KickScript? s = _script;
    if (s == null) {
      return;
    }
    _elapsed += math.min(math.max(dt, 0), 0.1);
    if (s.timeline.isDone(_elapsed)) {
      final void Function()? done = onKickFinished;
      _script = null;
      _elapsed = 0;
      done?.call();
    }
  }

  KickPhase get phase {
    final KickScript? s = _script;
    return s == null ? KickPhase.done : s.timeline.phaseAt(_elapsed);
  }

  /// Who is taking the kick now, or next.
  MatchSide get shooterSide => _script?.record.side ?? idleShooter;

  /// The ball: on the spot, in flight, or after contact.
  WorldPoint get ballPosition {
    final KickScript? s = _script;
    if (s == null) {
      return (x: 0, y: Tuning.ballRadius, z: Tuning.spotDistance);
    }
    final double flight = s.timeline.flightProgress(_elapsed);
    if (_elapsed < s.timeline.flightStart) {
      return (x: 0, y: Tuning.ballRadius, z: Tuning.spotDistance);
    }
    if (_elapsed < s.timeline.contactAt) {
      return ShotTrajectory.flightAt(s.record.params, s.target, flight);
    }
    return ShotTrajectory.afterAt(s.result, s.target, s.timeline.sinceContact(_elapsed));
  }

  /// True once the ball is behind the goal line, in the net or beyond.
  bool get ballBehindGoalLine => ballPosition.z < 0;

  /// How far the ball has spun, in radians, for the marks on it.
  double get ballSpin {
    final KickScript? s = _script;
    if (s == null) {
      return 0;
    }
    return s.timeline.flightProgress(_elapsed) * math.pi * (2 + 4 * s.record.params.power);
  }

  /// The keeper: standing until the strike, then diving to the place the rules
  /// chose, or to the ball when it was saved.
  KeeperPose get keeperPose {
    final KickScript? s = _script;
    if (s == null) {
      return KeeperMotion.standing;
    }
    return KeeperMotion.poseAt(
      s.record.outcome.keeperDive,
      s.timeline.keeperSeconds(_elapsed),
      reachTo: s.result == ShotResult.saved ? s.target : null,
    );
  }

  /// The shooter: waiting behind the ball, running up, then striking.
  ShooterState get shooter {
    final KickScript? s = _script;
    if (s == null) {
      return (x: Tuning.shooterX, z: Tuning.runUpStartZ, swing: 0);
    }
    final KickTimeline t = s.timeline;
    final double run = t.runUpProgress(_elapsed);
    final double eased = run * run * (3 - 2 * run);
    final double z = Tuning.runUpStartZ + (Tuning.strikeZ - Tuning.runUpStartZ) * eased;
    double swing = 0;
    if (_elapsed >= t.strikeAt) {
      swing = math.min((_elapsed - t.strikeAt) / Tuning.strikeSeconds, 1);
    }
    return (x: Tuning.shooterX, z: z, swing: swing);
  }

  /// Seconds since the ball reached the goal plane, 0 before.
  double get sinceContact {
    final KickScript? s = _script;
    return s == null ? 0 : s.timeline.sinceContact(_elapsed);
  }

  /// The net's shaking, 1 at the moment of a goal and fading to 0. Always 0
  /// under Reduce Motion or for anything but a goal.
  double get netRipple {
    final KickScript? s = _script;
    if (s == null || reduceMotion || s.result != ShotResult.goal) {
      return 0;
    }
    final double since = s.timeline.sinceContact(_elapsed);
    if (_elapsed < s.timeline.contactAt) {
      return 0;
    }
    return math.max(1 - since / Tuning.netRippleSeconds, 0);
  }

  /// Where the ball met the goal plane, once it has.
  GoalPoint? get contact {
    final KickScript? s = _script;
    if (s == null || _elapsed < s.timeline.contactAt) {
      return null;
    }
    return s.target;
  }
}
