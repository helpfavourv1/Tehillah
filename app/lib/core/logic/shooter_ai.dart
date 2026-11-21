import 'package:tehillah/core/logic/seeded_rng.dart';
import 'package:tehillah/core/models/keeper_profile.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/shot_params.dart';

/// Chooses the kicks of the computer-controlled side, and the keeper that
/// stands in for the player's own goal when the player is not the keeper.
abstract final class ShooterAi {
  static const double _baseAim = 0.40;
  static const double _aimGain = 0.50;
  static const double _aimNoise = 0.45;

  /// One kick for an opponent of the given [difficulty] (0 to 1). Weak
  /// opponents aim loosely and often shoot at the middle; strong ones place the
  /// ball near the corners.
  static ShotParams choose({required double difficulty, required SeededRng rng}) {
    final double sideRoll = rng.nextDouble();
    final double aimDraw = rng.nextGaussian();
    final double heightRoll = rng.nextDouble();
    final double elevationRoll = rng.nextDouble();
    final double powerRoll = rng.nextDouble();

    final double side = sideRoll < 0.5 ? -1 : 1;
    double magnitude = _baseAim + _aimGain * difficulty;
    magnitude += aimDraw * (_aimNoise * (1 - difficulty) + 0.04);
    magnitude = magnitude < 0 ? 0 : (magnitude > 1.1 ? 1.1 : magnitude);
    final bool high = heightRoll < 0.35;
    final double elevation =
        high ? 0.65 + 0.25 * elevationRoll : 0.15 + 0.25 * elevationRoll;
    final double direction = side * magnitude;
    return ShotParams(
      direction: direction > 1 ? 1 : (direction < -1 ? -1 : direction),
      elevation: elevation,
      power: 0.55 + 0.30 * powerRoll,
      curve: 0,
    );
  }

  /// The keeper that defends the player's goal when the computer takes the
  /// kicks. It is weaker against stronger opponents, so a hard opponent scores
  /// more often.
  static KeeperProfile defender(double difficulty) {
    final double skill = 0.85 - 0.65 * difficulty;
    return KeeperProfile(
      reaction: skill,
      reach: skill,
      habitReading: 0,
      tendency: <KeeperDive, double>{
        for (final KeeperDive d in KeeperDive.values) d: 1 / 6,
      },
    );
  }
}
