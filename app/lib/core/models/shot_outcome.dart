import 'package:tehillah/core/models/json_util.dart';

/// How a kick ended.
enum ShotResult { goal, saved, post, wide, high }

/// Where the keeper stood or dived, as seen by the shooter.
enum DiveSide { left, center, right }

/// The six places a keeper can go: three sides, each low or high.
enum KeeperDive {
  leftLow(DiveSide.left, false),
  leftHigh(DiveSide.left, true),
  centerLow(DiveSide.center, false),
  centerHigh(DiveSide.center, true),
  rightLow(DiveSide.right, false),
  rightHigh(DiveSide.right, true);

  const KeeperDive(this.side, this.high);

  final DiveSide side;
  final bool high;
}

/// The result of one kick together with what the keeper did.
final class ShotOutcome {
  const ShotOutcome(this.result, this.keeperDive);

  factory ShotOutcome.fromJson(Map<String, Object?> json) {
    return ShotOutcome(
      readEnum<ShotResult>(ShotResult.values, json, 'result'),
      readEnum<KeeperDive>(KeeperDive.values, json, 'dive'),
    );
  }

  final ShotResult result;
  final KeeperDive keeperDive;

  bool get isGoal => result == ShotResult.goal;

  Map<String, Object?> toJson() => <String, Object?>{
        'result': result.name,
        'dive': keeperDive.name,
      };

  @override
  bool operator ==(Object other) =>
      other is ShotOutcome &&
      other.result == result &&
      other.keeperDive == keeperDive;

  @override
  int get hashCode => Object.hash(result, keeperDive);

  @override
  String toString() => 'ShotOutcome($result, $keeperDive)';
}
