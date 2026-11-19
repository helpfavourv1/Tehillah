import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/stat_mods.dart';

/// One of the nine fruit-of-the-Spirit balls: a benefit and a small trade-off,
/// unlocked by play and never sold.
final class BallDef {
  const BallDef({
    required this.id,
    required this.fruitKey,
    required this.unlockLamps,
    required this.mods,
  }) : assert(unlockLamps >= 0);

  factory BallDef.fromJson(Map<String, Object?> json) {
    return BallDef(
      id: readString(json, 'id'),
      fruitKey: readString(json, 'fruitKey'),
      unlockLamps: readInt(json, 'unlockLamps', min: 0),
      mods: StatMods.fromJson(jsonMap(json['mods'], 'mods')),
    );
  }

  final String id;

  /// Localization key for the fruit name.
  final String fruitKey;

  /// Lamps (stages cleared) needed to unlock the ball.
  final int unlockLamps;

  final StatMods mods;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'fruitKey': fruitKey,
        'unlockLamps': unlockLamps,
        'mods': mods.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      other is BallDef &&
      other.id == id &&
      other.fruitKey == fruitKey &&
      other.unlockLamps == unlockLamps &&
      other.mods == mods;

  @override
  int get hashCode => Object.hash(id, fruitKey, unlockLamps, mods);
}
