import 'package:tehillah/core/catalog/ball_catalog.dart';
import 'package:tehillah/core/catalog/gear_catalog.dart';
import 'package:tehillah/core/models/ball_def.dart';
import 'package:tehillah/core/models/gear_def.dart';
import 'package:tehillah/core/models/loadout.dart';
import 'package:tehillah/core/models/stat_mods.dart';

/// The numbers the match logic reads, made by adding the chosen ball and gear.
/// Every field is a fraction where zero means "no change", except
/// [selahCharges], which is the total number of Selah pauses.
final class Modifiers {
  const Modifiers({
    this.aimForgiveness = 0,
    this.power = 0,
    this.powerWindow = 0,
    this.powerConsistency = 0,
    this.curveRange = 0,
    this.curveOvershoot = 0,
    this.pathSteadiness = 0,
    this.lowShot = 0,
    this.highShot = 0,
    this.nerveGain = 0,
    this.nerveRecovery = 0,
    this.selahDuration = 0,
    this.selahCharges = baseSelahCharges,
    this.timingBarSpeed = 0,
    this.resetSpeed = 0,
    this.reboundChance = 0,
    this.special = GearSpecial.none,
  });

  /// A match with no ball and no gear bonus.
  static const Modifiers none = Modifiers();

  /// Selah pauses per match before any ball or gear changes it.
  static const int baseSelahCharges = 3;

  /// Adds the loadout's ball and gear. Throws [ArgumentError] for an id that is
  /// not in the catalogs, so a corrupt save cannot silently play as "no ball".
  factory Modifiers.fromLoadout(Loadout loadout) {
    final BallDef? ball = BallCatalog.byId(loadout.ballId);
    if (ball == null) {
      throw ArgumentError.value(loadout.ballId, 'ballId', 'unknown ball');
    }
    final String? gearId = loadout.gearId;
    final GearDef? gear = gearId == null ? null : GearCatalog.byId(gearId);
    if (gearId != null && gear == null) {
      throw ArgumentError.value(gearId, 'gearId', 'unknown gear');
    }
    final StatMods a = ball.mods;
    final StatMods b = gear?.mods ?? StatMods.none;
    return Modifiers(
      aimForgiveness: a.aimForgiveness + b.aimForgiveness,
      power: a.power + b.power,
      powerWindow: a.powerWindow + b.powerWindow,
      powerConsistency: a.powerConsistency + b.powerConsistency,
      curveRange: a.curveRange + b.curveRange,
      curveOvershoot: a.curveOvershoot + b.curveOvershoot,
      pathSteadiness: a.pathSteadiness + b.pathSteadiness,
      lowShot: a.lowShot + b.lowShot,
      highShot: a.highShot + b.highShot,
      nerveGain: a.nerveGain + b.nerveGain,
      nerveRecovery: a.nerveRecovery + b.nerveRecovery,
      selahDuration: a.selahDuration + b.selahDuration,
      selahCharges:
          (baseSelahCharges + a.selahCharges + b.selahCharges).clamp(0, 99),
      timingBarSpeed: a.timingBarSpeed + b.timingBarSpeed,
      resetSpeed: a.resetSpeed + b.resetSpeed,
      reboundChance: a.reboundChance + b.reboundChance,
      special: gear?.special ?? GearSpecial.none,
    );
  }

  final double aimForgiveness;
  final double power;
  final double powerWindow;
  final double powerConsistency;
  final double curveRange;
  final double curveOvershoot;
  final double pathSteadiness;
  final double lowShot;
  final double highShot;
  final double nerveGain;
  final double nerveRecovery;
  final double selahDuration;

  /// Total Selah pauses this match.
  final int selahCharges;
  final double timingBarSpeed;
  final double resetSpeed;
  final double reboundChance;
  final GearSpecial special;
}
