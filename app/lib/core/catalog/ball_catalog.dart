import 'package:tehillah/core/models/ball_def.dart';
import 'package:tehillah/core/models/stat_mods.dart';

/// The nine fruit-of-the-Spirit balls. Numbers are tuning starting points that
/// the seeded balance simulation (batch p2b) adjusts.
abstract final class BallCatalog {
  static const List<BallDef> all = <BallDef>[
    BallDef(
      id: 'love',
      fruitKey: 'fruitLove',
      unlockLamps: 0,
      mods: StatMods(aimForgiveness: 0.15, power: -0.05),
    ),
    BallDef(
      id: 'joy',
      fruitKey: 'fruitJoy',
      unlockLamps: 1,
      mods: StatMods(curveRange: 0.20, curveOvershoot: 0.15),
    ),
    BallDef(
      id: 'peace',
      fruitKey: 'fruitPeace',
      unlockLamps: 2,
      mods: StatMods(nerveGain: -0.20, power: -0.03),
    ),
    BallDef(
      id: 'patience',
      fruitKey: 'fruitPatience',
      unlockLamps: 3,
      mods: StatMods(timingBarSpeed: -0.20, nerveRecovery: -0.15),
    ),
    BallDef(
      id: 'kindness',
      fruitKey: 'fruitKindness',
      unlockLamps: 4,
      mods: StatMods(reboundChance: 0.25, aimForgiveness: -0.08),
    ),
    BallDef(
      id: 'goodness',
      fruitKey: 'fruitGoodness',
      unlockLamps: 6,
      mods: StatMods(pathSteadiness: 0.20, curveRange: -0.15),
    ),
    BallDef(
      id: 'faithfulness',
      fruitKey: 'fruitFaithfulness',
      unlockLamps: 8,
      mods: StatMods(powerConsistency: 0.30),
    ),
    BallDef(
      id: 'gentleness',
      fruitKey: 'fruitGentleness',
      unlockLamps: 9,
      mods: StatMods(lowShot: 0.15, highShot: -0.15),
    ),
    BallDef(
      id: 'selfControl',
      fruitKey: 'fruitSelfControl',
      unlockLamps: 10,
      mods: StatMods(selahDuration: 0.30, selahCharges: -1),
    ),
  ];

  static BallDef? byId(String id) {
    for (final BallDef ball in all) {
      if (ball.id == id) {
        return ball;
      }
    }
    return null;
  }
}
