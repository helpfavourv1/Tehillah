import 'package:tehillah/core/logic/modifiers.dart';
import 'package:tehillah/core/logic/seeded_rng.dart';
import 'package:tehillah/core/models/gear_def.dart';
import 'package:tehillah/core/models/keeper_profile.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/shot_params.dart';

/// What one resolved kick produced.
final class ShotResolution {
  const ShotResolution(this.outcome, {this.shieldUsed = false});

  final ShotOutcome outcome;

  /// True when the Shield of Faith turned a post into a goal. The match engine
  /// then stops offering the shield for the rest of the match.
  final bool shieldUsed;
}

/// Where a shot is aimed or lands, on the same six-cell grid as the keeper's
/// dives.
abstract final class GoalGrid {
  /// Boundary between the left or right third and the centre third.
  static const double sideEdge = 1 / 3;

  /// Height at which a shot counts as "high".
  static const double highEdge = 0.5;

  static DiveSide sideOf(double x) {
    if (x < -sideEdge) {
      return DiveSide.left;
    }
    if (x > sideEdge) {
      return DiveSide.right;
    }
    return DiveSide.center;
  }

  static bool isHigh(double y) => y >= highEdge;

  /// The dive that covers the cell holding ([x], [y]) exactly.
  static KeeperDive diveFor(double x, double y) {
    final bool high = isHigh(y);
    switch (sideOf(x)) {
      case DiveSide.left:
        return high ? KeeperDive.leftHigh : KeeperDive.leftLow;
      case DiveSide.center:
        return high ? KeeperDive.centerHigh : KeeperDive.centerLow;
      case DiveSide.right:
        return high ? KeeperDive.rightHigh : KeeperDive.rightLow;
    }
  }
}

/// Decides how a kick ends. A pure function of the shot, the keeper's dive, the
/// match numbers and the random generator, so a replay gives the same result.
///
/// The generator is always read five times, whatever the result, so the number
/// of draws never depends on the branch taken.
abstract final class ShotResolver {
  static const double _idealPower = 0.78;
  static const double _powerHalfWindow = 0.18;
  static const double _baseNoise = 0.045;
  static const double _nerveNoise = 0.10;
  static const double _powerNoise = 0.5;
  static const double _curveShift = 0.30;
  static const double _windShift = 0.15;
  static const double _slackPerForgiveness = 0.25;
  static const double _postBand = 0.05;
  static const double _baseSaveFloor = 0.05;
  static const double _baseSaveSlope = 1.20;
  static const double _powerSaveDrop = 0.25;
  static const double _cornerSaveDrop = 0.25;
  static const double _baseRebound = 0.10;
  static const double _reboundGain = 0.40;

  /// How well a dive covers a shot cell: [sideDistance] is 0 to 2 cells away
  /// sideways and [heightDiffers] is true when one is low and the other high.
  static double coverage(int sideDistance, bool heightDiffers) {
    switch (sideDistance) {
      case 0:
        return heightDiffers ? 0.75 : 1.0;
      case 1:
        return heightDiffers ? 0.35 : 0.55;
      default:
        return 0.10;
    }
  }

  static double _clamp(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);

  static int _sideIndex(DiveSide side) => side.index;

  /// Resolves one kick.
  ///
  /// [nerve] is the shooter's nerve (0 to 1), [wind] the crosswind (-1 to 1),
  /// [keeper] the keeper's skill, and [postToGoalAvailable] whether the Shield
  /// of Faith is still unused.
  static ShotResolution resolve({
    required ShotParams params,
    required KeeperDive dive,
    required Modifiers mods,
    required double nerve,
    required double wind,
    required KeeperProfile keeper,
    required SeededRng rng,
    bool postToGoalAvailable = false,
  }) {
    final double powerDraw = rng.nextGaussian();
    final double xDraw = rng.nextGaussian();
    final double yDraw = rng.nextGaussian();
    final double saveRoll = rng.nextDouble();
    final double reboundRoll = rng.nextDouble();

    final double consistency = _clamp(mods.powerConsistency, 0, 0.9);
    final double steadiness = _clamp(mods.pathSteadiness, 0, 0.9);
    final double power = _clamp(
      params.power * (1 + mods.power) + powerDraw * 0.05 * (1 - consistency),
      0,
      1,
    );
    final double window = _powerHalfWindow * (1 + mods.powerWindow);
    final double excess = _max0((power - _idealPower).abs() - window);

    double sigma = _baseNoise + _nerveNoise * nerve * nerve + _powerNoise * excess;
    sigma *= 1 - 0.5 * steadiness;
    final double heightFactor =
        params.elevation < GoalGrid.highEdge ? 1 - mods.lowShot : 1 - mods.highShot;
    sigma *= _clamp(heightFactor, 0.5, 1.5);

    double shift = params.curve * _curveShift * (1 + mods.curveRange);
    if (params.curve.abs() > 0.85) {
      final double over = (params.curve.abs() - 0.85) / 0.15;
      shift += (params.curve < 0 ? -1 : 1) * mods.curveOvershoot * 0.25 * over;
    }
    shift += wind * _windShift * (1 - 0.5 * steadiness);

    final double x = params.direction + shift + xDraw * sigma;
    final double y = params.elevation + yDraw * sigma * 0.8;

    final double slack = _slackPerForgiveness * _clamp(mods.aimForgiveness, 0, 0.5);
    final double ax = _max0(x.abs() - slack);
    final double ay = y > 1 ? _max0(y - slack) : (y < 0 ? 0 : y);

    if (ax > 1 + _postBand) {
      return ShotResolution(ShotOutcome(ShotResult.wide, dive));
    }
    if (ay > 1 + _postBand) {
      return ShotResolution(ShotOutcome(ShotResult.high, dive));
    }
    if (ax > 1 - _postBand || ay > 1 - _postBand) {
      final double reboundChance =
          _clamp(_baseRebound + _reboundGain * mods.reboundChance, 0, 0.9);
      if (reboundRoll < reboundChance) {
        return ShotResolution(ShotOutcome(ShotResult.goal, dive));
      }
      if (postToGoalAvailable && mods.special == GearSpecial.postToGoalOnce) {
        return ShotResolution(
          ShotOutcome(ShotResult.goal, dive),
          shieldUsed: true,
        );
      }
      return ShotResolution(ShotOutcome(ShotResult.post, dive));
    }

    final double landingX = x < 0 ? -_max0(x.abs() - slack) : _max0(x.abs() - slack);
    final DiveSide shotSide = GoalGrid.sideOf(landingX);
    final bool shotHigh = GoalGrid.isHigh(ay);
    final int sideDistance =
        (_sideIndex(dive.side) - _sideIndex(shotSide)).abs();
    final double cover = coverage(sideDistance, dive.high != shotHigh);

    final double skill = 0.6 * keeper.reaction + 0.4 * keeper.reach;
    final double base = _clamp(_baseSaveFloor + _baseSaveSlope * skill, 0, 1);
    final double powerFactor = 1 - _powerSaveDrop * power * power;
    final double corner = _clamp((ax - 0.5) / 0.5, 0, 1);
    final double cornerFactor =
        1 - _cornerSaveDrop * corner * (1 - 0.5 * keeper.reach);
    final double saveChance = base * cover * powerFactor * cornerFactor;
    return ShotResolution(
      ShotOutcome(saveRoll < saveChance ? ShotResult.saved : ShotResult.goal, dive),
    );
  }

  static double _max0(double v) => v > 0 ? v : 0;
}
