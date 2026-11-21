import 'package:tehillah/core/catalog/stage_catalog.dart';
import 'package:tehillah/core/models/kick_record.dart';
import 'package:tehillah/core/models/loadout.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/match_state.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/shot_params.dart';

const ShotParams centreShot =
    ShotParams(direction: 0, elevation: 0.2, power: 0.78, curve: 0);

MatchConfig configFor({
  MatchMode mode = MatchMode.friendly,
  int seed = 1,
  Loadout loadout = Loadout.starter,
  int stage = 1,
  int kicksPerSide = 5,
  double difficulty = 0.1,
  double wind = 0,
}) {
  return MatchConfig(
    mode: mode,
    opponent: StageCatalog.stages[stage - 1].opponents[0],
    loadout: loadout,
    seed: seed,
    difficulty: difficulty,
    kicksPerSide: kicksPerSide,
    wind: wind,
  );
}

KickRecord kickRecord(MatchSide side, int round, {required bool goal}) {
  return KickRecord(
    side: side,
    round: round,
    params: centreShot,
    outcome: ShotOutcome(
      goal ? ShotResult.goal : ShotResult.saved,
      KeeperDive.leftLow,
    ),
  );
}

MatchState stateOf({
  int playerScore = 0,
  int opponentScore = 0,
  int playerKicks = 0,
  int opponentKicks = 0,
  int kicksPerSide = 5,
  MatchSide firstSide = MatchSide.player,
  double nerve = 0,
  int selahCharges = 3,
}) {
  return MatchState(
    playerScore: playerScore,
    opponentScore: opponentScore,
    playerKicks: playerKicks,
    opponentKicks: opponentKicks,
    kicksPerSide: kicksPerSide,
    firstSide: firstSide,
    nerve: nerve,
    selahCharges: selahCharges,
  );
}
