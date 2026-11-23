import 'dart:math' as math;

import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/shot_params.dart';
import 'package:tehillah/game/tuning.dart';

/// A point in the goal plane, in metres: `x` across (0 is the centre) and `y`
/// up from the grass.
typedef GoalPoint = ({double x, double y});

/// A world point: `x` across, `y` up, `z` from the goal line towards the
/// shooter.
typedef WorldPoint = ({double x, double y, double z});

/// The path of the ball. The match rules decide the result; this only draws it,
/// so the picture always agrees with the rules: a goal ends inside the frame,
/// a post ends on the post or bar, a miss ends outside, a save ends in the
/// keeper's hands. All functions are pure.
abstract final class ShotTrajectory {
  /// Where the ball reaches the goal plane for [result].
  static GoalPoint targetFor(ShotParams params, ShotResult result) {
    final double sign = params.direction < 0 ? -1 : 1;
    final double aimX = params.direction * Tuning.halfGoal;
    final double aimY = params.elevation * Tuning.goalHeight;
    final double insideX = _clamp(aimX, -Tuning.halfGoal * 0.9, Tuning.halfGoal * 0.9);
    final double insideY = _clamp(aimY, 0.15, Tuning.goalHeight * 0.9);
    switch (result) {
      case ShotResult.goal:
      case ShotResult.saved:
        return (x: insideX, y: insideY);
      case ShotResult.post:
        if (params.direction.abs() >= params.elevation) {
          return (
            x: sign * Tuning.halfGoal,
            y: _clamp(aimY, 0.3, Tuning.goalHeight - 0.3),
          );
        }
        return (x: insideX, y: Tuning.goalHeight);
      case ShotResult.wide:
        return (
          x: sign * (Tuning.halfGoal + 0.9 + params.direction.abs() * 0.6),
          y: _clamp(aimY, 0.2, Tuning.goalHeight),
        );
      case ShotResult.high:
        return (x: insideX, y: Tuning.goalHeight + 0.7 + params.elevation * 0.5);
    }
  }

  /// Seconds from the strike to the goal line.
  static double flightSeconds(double power) {
    final double p = _clamp(power, 0, 1);
    return Tuning.slowFlightSeconds +
        (Tuning.fastFlightSeconds - Tuning.slowFlightSeconds) * p;
  }

  /// The ball at progress [t] (0 at the spot, 1 at the goal plane).
  static WorldPoint flightAt(ShotParams params, GoalPoint target, double t) {
    final double u = _clamp(t, 0, 1);
    final double bulge = params.curve * Tuning.curveBulge * math.sin(math.pi * u);
    final double arc =
        (Tuning.arcBase + Tuning.arcLift * params.elevation) * 4 * u * (1 - u);
    return (
      x: target.x * u + bulge,
      y: Tuning.ballRadius + (target.y - Tuning.ballRadius) * u + arc,
      z: Tuning.spotDistance * (1 - u),
    );
  }

  /// The ball [seconds] after reaching the goal plane at [target].
  static WorldPoint afterAt(ShotResult result, GoalPoint target, double seconds) {
    final double s = math.max(seconds, 0);
    double ease(double over) {
      final double u = _clamp(s / over, 0, 1);
      return 1 - (1 - u) * (1 - u);
    }

    final double fall = Tuning.fallHalfG * s * s;
    final double outward = target.x < 0 ? -1 : 1;
    switch (result) {
      case ShotResult.goal:
        return (
          x: target.x * (1 + 0.04 * ease(0.35)),
          y: math.max(Tuning.ballRadius, target.y - fall),
          z: -Tuning.netDepth * ease(0.35),
        );
      case ShotResult.saved:
        return (
          x: target.x + outward * 1.2 * ease(0.8),
          y: math.max(Tuning.ballRadius, target.y - fall),
          z: 3 * ease(0.8),
        );
      case ShotResult.post:
        return (
          x: target.x + outward * 2.5 * ease(0.8),
          y: math.max(Tuning.ballRadius, target.y + s - fall),
          z: 4 * ease(0.8),
        );
      case ShotResult.wide:
      case ShotResult.high:
        return (
          x: target.x + outward * 0.8 * ease(0.8),
          y: math.max(Tuning.ballRadius, target.y - fall * 0.5),
          z: -9 * ease(0.9),
        );
    }
  }

  static double _clamp(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);
}
