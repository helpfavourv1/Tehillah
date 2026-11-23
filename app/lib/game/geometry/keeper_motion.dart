import 'dart:math' as math;

import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/game/geometry/shot_trajectory.dart';
import 'package:tehillah/game/tuning.dart';

/// Where the keeper's body is, and how it is leaning, at one moment.
final class KeeperPose {
  const KeeperPose({
    required this.x,
    required this.y,
    required this.tilt,
    required this.stretch,
  });

  /// Across the goal, in metres, and the height of the body's centre.
  final double x;
  final double y;

  /// Lean in radians; positive leans towards +x.
  final double tilt;

  /// 0 standing, 1 fully extended.
  final double stretch;
}

/// The keeper's dive, as a pure function of time. The keeper chooses one of six
/// places; when the shot is saved the dive ends at the ball instead, so the
/// hands meet it.
abstract final class KeeperMotion {
  static const GoalPoint rest = (x: 0, y: Tuning.keeperRestY);

  /// The body centre at the end of a dive to [dive].
  static GoalPoint diveTarget(KeeperDive dive) {
    final double x = switch (dive.side) {
      DiveSide.left => -Tuning.keeperReachX,
      DiveSide.center => 0,
      DiveSide.right => Tuning.keeperReachX,
    };
    return (x: x, y: dive.high ? Tuning.keeperHighY : Tuning.keeperLowY);
  }

  /// The pose [seconds] after the dive starts. [reachTo] replaces the end point
  /// (a save, where the ball is).
  static KeeperPose poseAt(KeeperDive dive, double seconds, {GoalPoint? reachTo}) {
    final GoalPoint end = reachTo ?? diveTarget(dive);
    final double u = math.min(math.max(seconds / Tuning.keeperDiveSeconds, 0), 1);
    final double e = 1 - (1 - u) * (1 - u);
    final double sideSign = end.x < -0.01 ? -1 : (end.x > 0.01 ? 1 : 0);
    final double leap = 0.25 * math.sin(math.pi * e);
    return KeeperPose(
      x: rest.x + (end.x - rest.x) * e,
      y: rest.y + (end.y - rest.y) * e + leap,
      tilt: sideSign * Tuning.keeperMaxTilt * e,
      stretch: e,
    );
  }

  /// The standing pose.
  static KeeperPose get standing => poseAt(KeeperDive.centerLow, 0);
}
