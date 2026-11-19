import 'package:tehillah/core/models/json_util.dart';

/// The strategy choice made before a match: one ball and at most one piece of
/// keeper gear. Gear is optional because none is unlocked at the start.
final class Loadout {
  const Loadout({required this.ballId, this.gearId});

  factory Loadout.fromJson(Map<String, Object?> json) {
    final Object? gear = json['gearId'];
    if (gear != null && (gear is! String || gear.isEmpty)) {
      throw const FormatException('"gearId" must be a non-empty string or null');
    }
    return Loadout(ballId: readString(json, 'ballId'), gearId: gear as String?);
  }

  /// The ball every player starts with.
  static const Loadout starter = Loadout(ballId: 'love');

  final String ballId;
  final String? gearId;

  Loadout copyWith({String? ballId, String? gearId, bool clearGear = false}) {
    return Loadout(
      ballId: ballId ?? this.ballId,
      gearId: clearGear ? null : (gearId ?? this.gearId),
    );
  }

  Map<String, Object?> toJson() =>
      <String, Object?>{'ballId': ballId, 'gearId': gearId};

  @override
  bool operator ==(Object other) =>
      other is Loadout && other.ballId == ballId && other.gearId == gearId;

  @override
  int get hashCode => Object.hash(ballId, gearId);

  @override
  String toString() => 'Loadout($ballId, $gearId)';
}
