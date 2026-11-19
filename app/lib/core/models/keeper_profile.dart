import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/shot_outcome.dart';

/// How good a keeper is and where the keeper likes to go. This is the
/// difficulty data that `keeper_ai` reads.
final class KeeperProfile {
  KeeperProfile({
    required this.reaction,
    required this.reach,
    required this.habitReading,
    required Map<KeeperDive, double> tendency,
  })  : assert(reaction >= 0 && reaction <= 1),
        assert(reach >= 0 && reach <= 1),
        assert(habitReading >= 0 && habitReading <= 1),
        tendency = Map<KeeperDive, double>.unmodifiable(tendency);

  factory KeeperProfile.fromJson(Map<String, Object?> json) {
    final Map<String, Object?> raw = jsonMap(json['tendency'], 'tendency');
    final Map<KeeperDive, double> tendency = <KeeperDive, double>{};
    double total = 0;
    for (final KeeperDive dive in KeeperDive.values) {
      final double weight = readDouble(raw, dive.name, min: 0);
      tendency[dive] = weight;
      total += weight;
    }
    if (total <= 0) {
      throw const FormatException('"tendency" must have a positive total');
    }
    return KeeperProfile(
      reaction: readDouble(json, 'reaction', min: 0, max: 1),
      reach: readDouble(json, 'reach', min: 0, max: 1),
      habitReading: readDouble(json, 'habitReading', min: 0, max: 1),
      tendency: tendency,
    );
  }

  /// How quickly the keeper reacts, 0 (slow) to 1 (instant).
  final double reaction;

  /// How far the keeper can stretch, 0 to 1.
  final double reach;

  /// How strongly the keeper learns from the player's earlier kicks, 0 to 1.
  final double habitReading;

  /// Relative weight of each dive when the keeper has nothing to go on.
  final Map<KeeperDive, double> tendency;

  KeeperProfile copyWith({
    double? reaction,
    double? reach,
    double? habitReading,
    Map<KeeperDive, double>? tendency,
  }) {
    return KeeperProfile(
      reaction: reaction ?? this.reaction,
      reach: reach ?? this.reach,
      habitReading: habitReading ?? this.habitReading,
      tendency: tendency ?? this.tendency,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'reaction': reaction,
        'reach': reach,
        'habitReading': habitReading,
        'tendency': <String, Object?>{
          for (final KeeperDive dive in KeeperDive.values)
            dive.name: tendency[dive] ?? 0,
        },
      };

  @override
  bool operator ==(Object other) =>
      other is KeeperProfile &&
      other.reaction == reaction &&
      other.reach == reach &&
      other.habitReading == habitReading &&
      mapsEqual(other.tendency, tendency);

  @override
  int get hashCode =>
      Object.hash(reaction, reach, habitReading, hashMap(tendency));
}
