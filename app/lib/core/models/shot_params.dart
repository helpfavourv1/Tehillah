import 'package:tehillah/core/models/json_util.dart';

/// What every input scheme produces for one kick. All values are normalized.
final class ShotParams {
  const ShotParams({
    required this.direction,
    required this.elevation,
    required this.power,
    required this.curve,
  })  : assert(direction >= -1 && direction <= 1),
        assert(elevation >= 0 && elevation <= 1),
        assert(power >= 0 && power <= 1),
        assert(curve >= -1 && curve <= 1);

  factory ShotParams.fromJson(Map<String, Object?> json) {
    return ShotParams(
      direction: readDouble(json, 'direction', min: -1, max: 1),
      elevation: readDouble(json, 'elevation', min: 0, max: 1),
      power: readDouble(json, 'power', min: 0, max: 1),
      curve: readDouble(json, 'curve', min: -1, max: 1),
    );
  }

  /// Horizontal aim across the goal: -1 is the left post, 0 the centre, 1 the
  /// right post (left and right as seen by the shooter).
  final double direction;

  /// Vertical aim: 0 along the ground, 1 under the crossbar.
  final double elevation;

  /// Strike strength, 0 to 1.
  final double power;

  /// Sideways bend: -1 bends left, 1 bends right, 0 is straight.
  final double curve;

  ShotParams copyWith({
    double? direction,
    double? elevation,
    double? power,
    double? curve,
  }) {
    return ShotParams(
      direction: direction ?? this.direction,
      elevation: elevation ?? this.elevation,
      power: power ?? this.power,
      curve: curve ?? this.curve,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'direction': direction,
        'elevation': elevation,
        'power': power,
        'curve': curve,
      };

  @override
  bool operator ==(Object other) =>
      other is ShotParams &&
      other.direction == direction &&
      other.elevation == elevation &&
      other.power == power &&
      other.curve == curve;

  @override
  int get hashCode => Object.hash(direction, elevation, power, curve);

  @override
  String toString() =>
      'ShotParams(direction: $direction, elevation: $elevation, power: $power, curve: $curve)';
}
