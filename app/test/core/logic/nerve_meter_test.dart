import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/logic/modifiers.dart';
import 'package:tehillah/core/logic/nerve_meter.dart';
import 'package:tehillah/core/models/gear_def.dart';
import 'package:tehillah/core/models/match_state.dart';

import '../../support/match_helpers.dart';

void main() {
  final MatchState calm = stateOf(nerve: 0.2);

  test('a goal eases nerve and a miss shakes it', () {
    expect(
      NerveMeter.afterKick(before: calm, mods: Modifiers.none, wasGoal: true, isBoss: false),
      closeTo(0.19, 1e-9),
    );
    expect(
      NerveMeter.afterKick(before: calm, mods: Modifiers.none, wasGoal: false, isBoss: false),
      closeTo(0.26, 1e-9),
    );
  });

  test('sudden death, trailing and a boss add pressure', () {
    final MatchState sudden = stateOf(
      playerScore: 4, opponentScore: 4, playerKicks: 5, opponentKicks: 5, nerve: 0.2);
    expect(
      NerveMeter.afterKick(before: sudden, mods: Modifiers.none, wasGoal: true, isBoss: false),
      closeTo(0.2 + 0.13 - 0.04, 1e-9),
    );
    final MatchState trailing = stateOf(
      playerScore: 0, opponentScore: 1, playerKicks: 1, opponentKicks: 1, nerve: 0.2);
    expect(
      NerveMeter.afterKick(before: trailing, mods: Modifiers.none, wasGoal: true, isBoss: true),
      closeTo(0.2 + 0.03 + 0.05 + 0.04 - 0.04, 1e-9),
    );
  });

  test('gain follows the nerveGain modifier and stays between 0 and 1', () {
    final double slow = NerveMeter.afterKick(
        before: calm, mods: const Modifiers(nerveGain: -0.5), wasGoal: false, isBoss: false);
    final double fast = NerveMeter.afterKick(
        before: calm, mods: const Modifiers(nerveGain: 0.5), wasGoal: false, isBoss: false);
    expect(slow, lessThan(fast));
    expect(
      NerveMeter.afterKick(
          before: stateOf(nerve: 1), mods: Modifiers.none, wasGoal: false, isBoss: true),
      1.0,
    );
    expect(
      NerveMeter.afterKick(
          before: stateOf(nerve: 0), mods: Modifiers.none, wasGoal: true, isBoss: false),
      0.0,
    );
  });

  test('Selah steadies nerve, more with recovery and duration', () {
    expect(NerveMeter.afterSelah(0.8, Modifiers.none), closeTo(0.45, 1e-9));
    expect(NerveMeter.afterSelah(0.2, Modifiers.none), 0.0);
    expect(NerveMeter.afterSelah(0.8, const Modifiers(nerveRecovery: 0.5)), lessThan(0.45));
    expect(NerveMeter.afterSelah(0.8, const Modifiers(selahDuration: 0.5)), lessThan(0.45));
    expect(NerveMeter.afterSelah(0.8, const Modifiers(nerveRecovery: -0.5)), greaterThan(0.45));
  });

  test('the Helmet keeps the last Selah charge', () {
    expect(NerveMeter.chargesAfterSelah(3, Modifiers.none), 2);
    expect(NerveMeter.chargesAfterSelah(1, Modifiers.none), 0);
    expect(NerveMeter.chargesAfterSelah(0, Modifiers.none), 0);
    const Modifiers helmet = Modifiers(special: GearSpecial.selahFloor);
    expect(NerveMeter.chargesAfterSelah(3, helmet), 2);
    expect(NerveMeter.chargesAfterSelah(1, helmet), 1);
  });
}
