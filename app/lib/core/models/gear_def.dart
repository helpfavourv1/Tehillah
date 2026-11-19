import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/stat_mods.dart';

/// Effects that are rules rather than numbers.
enum GearSpecial {
  /// No special rule.
  none,

  /// Reveals the keeper's dive tendency after two kicks (Belt of Truth).
  revealTendency,

  /// Once per match a shot that hits the post becomes a goal (Shield of Faith).
  postToGoalOnce,

  /// Selah never fully empties (Helmet of Salvation).
  selahFloor,
}

/// One piece of keeper gear from the Armor of God. One item per match.
final class GearDef {
  const GearDef({
    required this.id,
    required this.armorKey,
    required this.unlockLamps,
    required this.mods,
    this.special = GearSpecial.none,
  }) : assert(unlockLamps >= 0);

  factory GearDef.fromJson(Map<String, Object?> json) {
    return GearDef(
      id: readString(json, 'id'),
      armorKey: readString(json, 'armorKey'),
      unlockLamps: readInt(json, 'unlockLamps', min: 0),
      mods: StatMods.fromJson(jsonMap(json['mods'], 'mods')),
      special: readEnum<GearSpecial>(GearSpecial.values, json, 'special'),
    );
  }

  final String id;

  /// Localization key for the item name.
  final String armorKey;

  /// Lamps (stages cleared) needed to unlock the item.
  final int unlockLamps;

  final StatMods mods;
  final GearSpecial special;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'armorKey': armorKey,
        'unlockLamps': unlockLamps,
        'mods': mods.toJson(),
        'special': special.name,
      };

  @override
  bool operator ==(Object other) =>
      other is GearDef &&
      other.id == id &&
      other.armorKey == armorKey &&
      other.unlockLamps == unlockLamps &&
      other.mods == mods &&
      other.special == special;

  @override
  int get hashCode => Object.hash(id, armorKey, unlockLamps, mods, special);
}
