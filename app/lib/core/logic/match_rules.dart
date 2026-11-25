import 'package:tehillah/core/logic/modifiers.dart';
import 'package:tehillah/core/logic/nerve_meter.dart';
import 'package:tehillah/core/models/kick_record.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/match_state.dart';

/// The rules of a shootout: five kicks each, an early win when the trailing
/// side cannot catch up, then sudden death. Pure functions over [MatchState].
abstract final class MatchRules {
  /// The state before the first kick. The player kicks first in every mode
  /// except Watchman, where the opponent does.
  static MatchState start(MatchConfig config, Modifiers mods) {
    return MatchState.initial(
      kicksPerSide: config.kicksPerSide,
      firstSide: config.mode == MatchMode.watchman
          ? MatchSide.opponent
          : MatchSide.player,
      selahCharges: mods.selahCharges + config.bonusSelah,
    );
  }

  /// Applies one kick. The kick must be by the side whose turn it is, and
  /// the match must not be finished.
  static MatchState apply({
    required MatchState state,
    required KickRecord kick,
    required Modifiers mods,
    required bool isBoss,
  }) {
    if (isFinished(state)) {
      throw StateError('the match is already finished');
    }
    if (kick.side != state.turn) {
      throw StateError('it is the ${state.turn.name} side to kick');
    }
    final bool goal = kick.isGoal;
    final bool player = kick.side == MatchSide.player;
    return state.copyWith(
      playerScore: state.playerScore + (player && goal ? 1 : 0),
      opponentScore: state.opponentScore + (!player && goal ? 1 : 0),
      playerKicks: state.playerKicks + (player ? 1 : 0),
      opponentKicks: state.opponentKicks + (player ? 0 : 1),
      nerve: player
          ? NerveMeter.afterKick(
              before: state,
              mods: mods,
              wasGoal: goal,
              isBoss: isBoss,
            )
          : state.nerve,
    );
  }

  /// Uses one Selah pause before a kick: steadies the nerve and spends a
  /// charge. Throws if no pause is left.
  static MatchState useSelah(MatchState state, Modifiers mods) {
    if (state.selahCharges <= 0) {
      throw StateError('no Selah pause left');
    }
    return state.copyWith(
      nerve: NerveMeter.afterSelah(state.nerve, mods),
      selahCharges: NerveMeter.chargesAfterSelah(state.selahCharges, mods),
    );
  }

  /// True when the match is decided.
  static bool isFinished(MatchState state) {
    final int k = state.kicksPerSide;
    if (state.playerKicks >= k && state.opponentKicks >= k) {
      return state.playerKicks == state.opponentKicks &&
          state.playerScore != state.opponentScore;
    }
    final int playerLeft = _left(k, state.playerKicks);
    final int opponentLeft = _left(k, state.opponentKicks);
    return state.playerScore > state.opponentScore + opponentLeft ||
        state.opponentScore > state.playerScore + playerLeft;
  }

  static int _left(int k, int taken) => taken >= k ? 0 : k - taken;

  /// The winning side, or null while the match is still going.
  static MatchSide? winner(MatchState state) {
    if (!isFinished(state)) {
      return null;
    }
    return state.playerScore > state.opponentScore
        ? MatchSide.player
        : MatchSide.opponent;
  }

  /// True when the match was decided in sudden death.
  static bool wentToSuddenDeath(MatchState state) =>
      state.playerKicks > state.kicksPerSide ||
      state.opponentKicks > state.kicksPerSide;
}
