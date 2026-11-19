import 'package:tehillah/core/models/json_util.dart';

/// Additive changes a ball or a piece of gear makes to the match numbers.
/// Every value is a fraction (0.15 means 15 percent) and zero means no change.
/// `modifiers.dart` in the logic layer adds a ball and a gear item together and
/// turns the sum into the numbers the shot resolver uses.
final class StatMods {
  const StatMods({
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
    this.selahCharges = 0,
    this.timingBarSpeed = 0,
    this.resetSpeed = 0,
    this.reboundChance = 0,
  });

  factory StatMods.fromJson(Map<String, Object?> json) {
    double d(String key) => json.containsKey(key)
        ? readDouble(json, key, min: -1, max: 1)
        : 0;
    return StatMods(
      aimForgiveness: d('aimForgiveness'),
      power: d('power'),
      powerWindow: d('powerWindow'),
      powerConsistency: d('powerConsistency'),
      curveRange: d('curveRange'),
      curveOvershoot: d('curveOvershoot'),
      pathSteadiness: d('pathSteadiness'),
      lowShot: d('lowShot'),
      highShot: d('highShot'),
      nerveGain: d('nerveGain'),
      nerveRecovery: d('nerveRecovery'),
      selahDuration: d('selahDuration'),
      selahCharges: json.containsKey('selahCharges')
          ? readInt(json, 'selahCharges', min: -9, max: 9)
          : 0,
      timingBarSpeed: d('timingBarSpeed'),
      resetSpeed: d('resetSpeed'),
      reboundChance: d('reboundChance'),
    );
  }

  /// Wider forgiveness lets a mistimed or off-line shot still land on target.
  final double aimForgiveness;

  /// Change to the strength of every strike.
  final double power;

  /// Change to the width of the power range that counts as a good strike.
  final double powerWindow;

  /// Less random variation in power from kick to kick.
  final double powerConsistency;

  /// Change to how much a shot can bend.
  final double curveRange;

  /// Extra overshoot when a shot is bent to the extreme.
  final double curveOvershoot;

  /// A steadier flight path under a flick.
  final double pathSteadiness;

  /// Quality of shots along the ground.
  final double lowShot;

  /// Quality of shots in the upper half of the goal.
  final double highShot;

  /// Change to how fast the nerve meter rises.
  final double nerveGain;

  /// Change to how fast Selah steadies the nerve meter.
  final double nerveRecovery;

  /// Change to how long Selah lasts.
  final double selahDuration;

  /// Change to the number of Selah pauses per match.
  final int selahCharges;

  /// Change to the speed of the timing bar (negative is slower and easier).
  final double timingBarSpeed;

  /// Change to how quickly the aim resets between kicks.
  final double resetSpeed;

  /// Chance change on collecting a rebound after a post.
  final double reboundChance;

  static const StatMods none = StatMods();

  StatMods operator +(StatMods other) {
    return StatMods(
      aimForgiveness: aimForgiveness + other.aimForgiveness,
      power: power + other.power,
      powerWindow: powerWindow + other.powerWindow,
      powerConsistency: powerConsistency + other.powerConsistency,
      curveRange: curveRange + other.curveRange,
      curveOvershoot: curveOvershoot + other.curveOvershoot,
      pathSteadiness: pathSteadiness + other.pathSteadiness,
      lowShot: lowShot + other.lowShot,
      highShot: highShot + other.highShot,
      nerveGain: nerveGain + other.nerveGain,
      nerveRecovery: nerveRecovery + other.nerveRecovery,
      selahDuration: selahDuration + other.selahDuration,
      selahCharges: selahCharges + other.selahCharges,
      timingBarSpeed: timingBarSpeed + other.timingBarSpeed,
      resetSpeed: resetSpeed + other.resetSpeed,
      reboundChance: reboundChance + other.reboundChance,
    );
  }

  /// Only non-zero values are written, so saved data stays small.
  Map<String, Object?> toJson() {
    final Map<String, Object?> out = <String, Object?>{};
    void put(String key, num value) {
      if (value != 0) {
        out[key] = value;
      }
    }

    put('aimForgiveness', aimForgiveness);
    put('power', power);
    put('powerWindow', powerWindow);
    put('powerConsistency', powerConsistency);
    put('curveRange', curveRange);
    put('curveOvershoot', curveOvershoot);
    put('pathSteadiness', pathSteadiness);
    put('lowShot', lowShot);
    put('highShot', highShot);
    put('nerveGain', nerveGain);
    put('nerveRecovery', nerveRecovery);
    put('selahDuration', selahDuration);
    put('selahCharges', selahCharges);
    put('timingBarSpeed', timingBarSpeed);
    put('resetSpeed', resetSpeed);
    put('reboundChance', reboundChance);
    return out;
  }

  @override
  bool operator ==(Object other) =>
      other is StatMods && mapsEqual(toJson(), other.toJson());

  @override
  int get hashCode => hashMap(toJson());

  @override
  String toString() => 'StatMods(${toJson()})';
}
