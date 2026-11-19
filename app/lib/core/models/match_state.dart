import 'package:tehillah/core/models/json_util.dart';
import 'package:tehillah/core/models/match_side.dart';

/// An immutable snapshot of a match between kicks. The side to kick and the
/// sudden-death flag are derived from the counts, so they can never disagree
/// with them.
final class MatchState {
  const MatchState({
    required this.playerScore,
    required this.opponentScore,
    required this.playerKicks,
    required this.opponentKicks,
    required this.kicksPerSide,
    required this.firstSide,
    required this.nerve,
    required this.selahCharges,
  })  : assert(playerScore >= 0 && playerScore <= playerKicks),
        assert(opponentScore >= 0 && opponentScore <= opponentKicks),
        assert(kicksPerSide >= 1),
        assert(nerve >= 0 && nerve <= 1),
        assert(selahCharges >= 0),
        assert(
          playerKicks - opponentKicks == 0 ||
              (firstSide == MatchSide.player
                  ? playerKicks - opponentKicks == 1
                  : opponentKicks - playerKicks == 1),
        );

  factory MatchState.initial({
    required int kicksPerSide,
    required MatchSide firstSide,
    required int selahCharges,
  }) {
    return MatchState(
      playerScore: 0,
      opponentScore: 0,
      playerKicks: 0,
      opponentKicks: 0,
      kicksPerSide: kicksPerSide,
      firstSide: firstSide,
      nerve: 0,
      selahCharges: selahCharges,
    );
  }

  factory MatchState.fromJson(Map<String, Object?> json) {
    final int playerKicks = readInt(json, 'playerKicks', min: 0);
    final int opponentKicks = readInt(json, 'opponentKicks', min: 0);
    final int playerScore = readInt(json, 'playerScore', min: 0);
    final int opponentScore = readInt(json, 'opponentScore', min: 0);
    final MatchSide first = readEnum<MatchSide>(MatchSide.values, json, 'firstSide');
    final int ahead = first == MatchSide.player
        ? playerKicks - opponentKicks
        : opponentKicks - playerKicks;
    if (ahead != 0 && ahead != 1) {
      throw const FormatException('kick counts do not alternate');
    }
    if (playerScore > playerKicks || opponentScore > opponentKicks) {
      throw const FormatException('score exceeds kicks taken');
    }
    return MatchState(
      playerScore: playerScore,
      opponentScore: opponentScore,
      playerKicks: playerKicks,
      opponentKicks: opponentKicks,
      kicksPerSide: readInt(json, 'kicksPerSide', min: 1, max: 20),
      firstSide: first,
      nerve: readDouble(json, 'nerve', min: 0, max: 1),
      selahCharges: readInt(json, 'selahCharges', min: 0, max: 9),
    );
  }

  final int playerScore;
  final int opponentScore;
  final int playerKicks;
  final int opponentKicks;
  final int kicksPerSide;

  /// The side that takes the first kick of the match.
  final MatchSide firstSide;

  /// Pressure on the shooter, 0 (calm) to 1 (shaking).
  final double nerve;

  /// Selah pauses still available.
  final int selahCharges;

  int kicksOf(MatchSide side) =>
      side == MatchSide.player ? playerKicks : opponentKicks;

  int scoreOf(MatchSide side) =>
      side == MatchSide.player ? playerScore : opponentScore;

  /// Whose kick is next. The first side kicks whenever the counts are level.
  MatchSide get turn => playerKicks == opponentKicks ? firstSide : firstSide.other;

  /// True once both sides have taken their regular kicks and the match is
  /// still going.
  bool get isSuddenDeath =>
      playerKicks >= kicksPerSide && opponentKicks >= kicksPerSide;

  MatchState copyWith({
    int? playerScore,
    int? opponentScore,
    int? playerKicks,
    int? opponentKicks,
    int? kicksPerSide,
    MatchSide? firstSide,
    double? nerve,
    int? selahCharges,
  }) {
    return MatchState(
      playerScore: playerScore ?? this.playerScore,
      opponentScore: opponentScore ?? this.opponentScore,
      playerKicks: playerKicks ?? this.playerKicks,
      opponentKicks: opponentKicks ?? this.opponentKicks,
      kicksPerSide: kicksPerSide ?? this.kicksPerSide,
      firstSide: firstSide ?? this.firstSide,
      nerve: nerve ?? this.nerve,
      selahCharges: selahCharges ?? this.selahCharges,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'playerScore': playerScore,
        'opponentScore': opponentScore,
        'playerKicks': playerKicks,
        'opponentKicks': opponentKicks,
        'kicksPerSide': kicksPerSide,
        'firstSide': firstSide.name,
        'nerve': nerve,
        'selahCharges': selahCharges,
      };

  @override
  bool operator ==(Object other) =>
      other is MatchState &&
      other.playerScore == playerScore &&
      other.opponentScore == opponentScore &&
      other.playerKicks == playerKicks &&
      other.opponentKicks == opponentKicks &&
      other.kicksPerSide == kicksPerSide &&
      other.firstSide == firstSide &&
      other.nerve == nerve &&
      other.selahCharges == selahCharges;

  @override
  int get hashCode => Object.hash(
        playerScore,
        opponentScore,
        playerKicks,
        opponentKicks,
        kicksPerSide,
        firstSide,
        nerve,
        selahCharges,
      );
}
