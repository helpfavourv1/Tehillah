import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/catalog/gear_catalog.dart';
import 'package:tehillah/core/logic/match_rules.dart';
import 'package:tehillah/core/logic/modifiers.dart';
import 'package:tehillah/core/models/gear_def.dart';
import 'package:tehillah/core/models/loadout.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/match_state.dart';

import '../../support/match_helpers.dart';

MatchState _play(MatchState s, List<bool> goals) {
  MatchState state = s;
  for (final bool goal in goals) {
    state = MatchRules.apply(
      state: state,
      kick: kickRecord(state.turn, state.kicksOf(state.turn) + 1, goal: goal),
      mods: Modifiers.none,
      isBoss: false,
    );
  }
  return state;
}

MatchState _fresh() => MatchRules.start(configFor(), Modifiers.none);

void main() {
  test('the player kicks first except in Watchman', () {
    expect(_fresh().turn, MatchSide.player);
    expect(
      MatchRules.start(configFor(mode: MatchMode.watchman), Modifiers.none).turn,
      MatchSide.opponent,
    );
  });

  test('the start state carries kicks per side and Selah charges', () {
    final MatchState s = MatchRules.start(
      configFor(kicksPerSide: 3), const Modifiers(selahCharges: 2));
    expect(s.kicksPerSide, 3);
    expect(s.selahCharges, 2);
    expect(s.nerve, 0);
  });

  test('kicks alternate and scores are counted by side', () {
    final MatchState s = _play(_fresh(), <bool>[true, false, true]);
    expect(s.playerScore, 2);
    expect(s.opponentScore, 0);
    expect(s.playerKicks, 2);
    expect(s.opponentKicks, 1);
    expect(s.turn, MatchSide.opponent);
  });

  test('the match is not finished while the trailing side can catch up', () {
    final MatchState s = _play(_fresh(), <bool>[true, false, true, false, true]);
    expect(MatchRules.isFinished(s), isFalse);
    expect(MatchRules.winner(s), isNull);
  });

  test('an early win ends the match once the trailing side cannot catch up', () {
    final MatchState s = _play(_fresh(), <bool>[true, false, true, false, true, false]);
    expect(MatchRules.isFinished(s), isTrue);
    expect(MatchRules.winner(s), MatchSide.player);
    expect(MatchRules.wentToSuddenDeath(s), isFalse);
  });

  test('the opponent can win early too', () {
    final MatchState s = _play(_fresh(), <bool>[false, true, false, true, false, true, false]);
    expect(MatchRules.winner(s), MatchSide.opponent);
  });

  test('a level score after five kicks each goes to sudden death', () {
    final MatchState s = _play(
      _fresh(),
      <bool>[true, true, true, true, true, true, true, true, false, false],
    );
    expect(s.playerKicks, 5);
    expect(s.opponentKicks, 5);
    expect(MatchRules.isFinished(s), isFalse);
    expect(s.isSuddenDeath, isTrue);
  });

  test('in sudden death the match ends only when both have kicked and differ', () {
    MatchState s = _play(
      _fresh(),
      <bool>[true, true, true, true, true, true, true, true, false, false],
    );
    s = _play(s, <bool>[true]);
    expect(MatchRules.isFinished(s), isFalse);
    s = _play(s, <bool>[false]);
    expect(MatchRules.isFinished(s), isTrue);
    expect(MatchRules.winner(s), MatchSide.player);
    expect(MatchRules.wentToSuddenDeath(s), isTrue);
  });

  test('sudden death goes on while both score or both miss', () {
    MatchState s = _play(
      _fresh(),
      <bool>[true, true, true, true, true, true, true, true, false, false],
    );
    s = _play(s, <bool>[true, true, false, false]);
    expect(MatchRules.isFinished(s), isFalse);
    s = _play(s, <bool>[false, true]);
    expect(MatchRules.winner(s), MatchSide.opponent);
  });

  test('a short shootout of three kicks ends on its own count', () {
    MatchState s = MatchRules.start(configFor(kicksPerSide: 3), Modifiers.none);
    s = _play(s, <bool>[true, false, true, false, true]);
    expect(MatchRules.isFinished(s), isFalse);
    s = _play(s, <bool>[false]);
    expect(MatchRules.winner(s), MatchSide.player);
  });

  test('kicking out of turn or after the end throws', () {
    final MatchState s = _fresh();
    expect(
      () => MatchRules.apply(
        state: s,
        kick: kickRecord(MatchSide.opponent, 1, goal: true),
        mods: Modifiers.none,
        isBoss: false,
      ),
      throwsStateError,
    );
    final MatchState done = _play(s, <bool>[true, false, true, false, true, false]);
    expect(
      () => MatchRules.apply(
        state: done,
        kick: kickRecord(MatchSide.player, 4, goal: true),
        mods: Modifiers.none,
        isBoss: false,
      ),
      throwsStateError,
    );
  });

  test('only the player\'s kicks move the nerve', () {
    final MatchState a = _play(_fresh(), <bool>[false]);
    expect(a.nerve, greaterThan(0));
    final MatchState b = _play(a, <bool>[true]);
    expect(b.nerve, a.nerve);
  });

  test('Selah lowers nerve and spends a charge; none left throws', () {
    MatchState s = stateOf(nerve: 0.8, selahCharges: 1);
    s = MatchRules.useSelah(s, Modifiers.none);
    expect(s.nerve, closeTo(0.45, 1e-9));
    expect(s.selahCharges, 0);
    expect(() => MatchRules.useSelah(s, Modifiers.none), throwsStateError);
  });

  test('with the Helmet the last Selah charge stays', () {
    final Modifiers helmet = Modifiers.fromLoadout(Loadout(
      ballId: 'love',
      gearId: GearCatalog.all.firstWhere((GearDef g) => g.special == GearSpecial.selahFloor).id,
    ));
    MatchState s = stateOf(nerve: 0.9, selahCharges: 1);
    s = MatchRules.useSelah(s, helmet);
    s = MatchRules.useSelah(s, helmet);
    expect(s.selahCharges, 1);
  });
}
