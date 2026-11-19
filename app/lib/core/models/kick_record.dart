import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/shot_params.dart';

/// One kick: who took it, which of that side's kicks it was, the shot and its
/// outcome. A match is the list of its kick records, which is also how the
/// keeper reads a player's habits.
final class KickRecord {
  const KickRecord({
    required this.side,
    required this.round,
    required this.params,
    required this.outcome,
  }) : assert(round >= 1);

  factory KickRecord.fromJson(Map<String, Object?> json) {
    return KickRecord(
      side: readEnum<MatchSide>(MatchSide.values, json, 'side'),
      round: readInt(json, 'round', min: 1),
      params: ShotParams.fromJson(jsonMap(json['params'], 'params')),
      outcome: ShotOutcome.fromJson(jsonMap(json['outcome'], 'outcome')),
    );
  }

  /// The side that took the kick.
  final MatchSide side;

  /// 1-based count of this side's kicks, continuing through sudden death.
  final int round;

  final ShotParams params;
  final ShotOutcome outcome;

  bool get isGoal => outcome.isGoal;

  Map<String, Object?> toJson() => <String, Object?>{
        'side': side.name,
        'round': round,
        'params': params.toJson(),
        'outcome': outcome.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      other is KickRecord &&
      other.side == side &&
      other.round == round &&
      other.params == params &&
      other.outcome == outcome;

  @override
  int get hashCode => Object.hash(side, round, params, outcome);

  @override
  String toString() => 'KickRecord($side, round $round, $outcome)';
}
