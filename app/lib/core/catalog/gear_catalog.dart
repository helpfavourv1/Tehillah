import 'package:tehillah/core/models/gear_def.dart';
import 'package:tehillah/core/models/stat_mods.dart';

/// The six pieces of the Armor of God. One item can be worn per match.
abstract final class GearCatalog {
  static const List<GearDef> all = <GearDef>[
    GearDef(
      id: 'beltOfTruth',
      armorKey: 'armorBeltOfTruth',
      unlockLamps: 1,
      mods: StatMods.none,
      special: GearSpecial.revealTendency,
    ),
    GearDef(
      id: 'shoesOfReadiness',
      armorKey: 'armorShoesOfReadiness',
      unlockLamps: 2,
      mods: StatMods(resetSpeed: 0.25, aimForgiveness: -0.08),
    ),
    GearDef(
      id: 'shieldOfFaith',
      armorKey: 'armorShieldOfFaith',
      unlockLamps: 4,
      mods: StatMods(powerWindow: -0.10),
      special: GearSpecial.postToGoalOnce,
    ),
    GearDef(
      id: 'breastplateOfRighteousness',
      armorKey: 'armorBreastplateOfRighteousness',
      unlockLamps: 6,
      mods: StatMods(nerveGain: -0.25, nerveRecovery: -0.15),
    ),
    GearDef(
      id: 'helmetOfSalvation',
      armorKey: 'armorHelmetOfSalvation',
      unlockLamps: 8,
      mods: StatMods(power: -0.10),
      special: GearSpecial.selahFloor,
    ),
    GearDef(
      id: 'swordOfTheSpirit',
      armorKey: 'armorSwordOfTheSpirit',
      unlockLamps: 10,
      mods: StatMods(lowShot: 0.20, highShot: -0.15),
    ),
  ];

  static GearDef? byId(String id) {
    for (final GearDef gear in all) {
      if (gear.id == id) {
        return gear;
      }
    }
    return null;
  }
}
