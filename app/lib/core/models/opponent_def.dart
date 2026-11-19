import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/keeper_profile.dart';

/// A fictional opponent: a name, a team and a goalkeeper. No real player, club
/// or badge appears anywhere.
final class OpponentDef {
  const OpponentDef({
    required this.id,
    required this.name,
    required this.team,
    required this.keeper,
  });

  factory OpponentDef.fromJson(Map<String, Object?> json) {
    return OpponentDef(
      id: readString(json, 'id'),
      name: readString(json, 'name'),
      team: readString(json, 'team'),
      keeper: KeeperProfile.fromJson(jsonMap(json['keeper'], 'keeper')),
    );
  }

  /// Stable identifier, for example `s03r2`.
  final String id;
  final String name;
  final String team;
  final KeeperProfile keeper;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'name': name,
        'team': team,
        'keeper': keeper.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      other is OpponentDef &&
      other.id == id &&
      other.name == name &&
      other.team == team &&
      other.keeper == keeper;

  @override
  int get hashCode => Object.hash(id, name, team, keeper);
}
