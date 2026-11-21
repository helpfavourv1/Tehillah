import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/catalog/gear_catalog.dart';
import 'package:tehillah/core/logic/match_engine.dart';
import 'package:tehillah/core/models/gear_def.dart';
import 'package:tehillah/core/models/kick_record.dart';
import 'package:tehillah/core/models/loadout.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/shot_outcome.dart';

import '../../support/match_helpers.dart';

/// Plays a whole match: the player aims at the middle, the watchman dives left.
MatchEngine _playOut(MatchConfig config) {
  final MatchEngine e = MatchEngine(config);
  int guard = 0;
  while (e.prompt != KickPrompt.finished && guard++ < 200) {
    switch (e.prompt) {
      case KickPrompt.humanShot:
        e.kick(shot: centreShot);
      case KickPrompt.humanDive:
        e.kick(dive: KeeperDive.leftLow);
      case KickPrompt.automatic:
        e.kick();
      case KickPrompt.finished:
        return e;
    }
  }
  return e;
}

GearDef _gear(GearSpecial s) => GearCatalog.all.firstWhere((GearDef g) => g.special == s);

void main() {
  test('every mode that uses the engine plays to a finish', () {
    for (final MatchMode mode in <MatchMode>[
      MatchMode.journey,
      MatchMode.friendly,
      MatchMode.watchman,
      MatchMode.jericho,
      MatchMode.sevenDays,
      MatchMode.dailyBread,
    ]) {
      final MatchEngine e = _playOut(configFor(mode: mode, seed: 5));
      expect(e.isFinished, isTrue, reason: mode.name);
      expect(e.winner, isNotNull, reason: mode.name);
    }
  });

  test('the same config and inputs replay the same match', () {
    final MatchEngine a = _playOut(configFor(seed: 123, difficulty: 0.6));
    final MatchEngine b = _playOut(configFor(seed: 123, difficulty: 0.6));
    expect(a.history.map((KickRecord k) => k.toJson().toString()).toList(),
        b.history.map((KickRecord k) => k.toJson().toString()).toList());
    expect(a.state, b.state);
  });

  test('different seeds can give different matches', () {
    final Set<String> seen = <String>{
      for (int seed = 1; seed <= 30; seed++)
        _playOut(configFor(seed: seed, difficulty: 0.5)).history.map((KickRecord k) => k.outcome.result.name).join(','),
    };
    expect(seen.length, greaterThan(3));
  });

  test('the prompt follows the mode and whose turn it is', () {
    final MatchEngine normal = MatchEngine(configFor());
    expect(normal.prompt, KickPrompt.humanShot);
    normal.kick(shot: centreShot);
    expect(normal.prompt, KickPrompt.automatic);
    final MatchEngine watch = MatchEngine(configFor(mode: MatchMode.watchman));
    expect(watch.prompt, KickPrompt.humanDive);
    watch.kick(dive: KeeperDive.leftLow);
    expect(watch.prompt, KickPrompt.automatic);
  });

  test('a kick needs the input its prompt asks for', () {
    expect(() => MatchEngine(configFor()).kick(), throwsArgumentError);
    expect(() => MatchEngine(configFor(mode: MatchMode.watchman)).kick(), throwsArgumentError);
    final MatchEngine done = _playOut(configFor());
    expect(() => done.kick(), throwsStateError);
  });

  test('kick records carry side and a running round number', () {
    final MatchEngine e = _playOut(configFor(seed: 9, difficulty: 0.3));
    final Map<MatchSide, int> counts = <MatchSide, int>{};
    for (final KickRecord k in e.history) {
      counts[k.side] = (counts[k.side] ?? 0) + 1;
      expect(k.round, counts[k.side]);
    }
    expect(e.history.first.side, MatchSide.player);
  });

  test('Selah is available only on the player\'s own kick and lowers nerve', () {
    final MatchEngine e = MatchEngine(configFor());
    for (int i = 0; i < 2; i++) {
      e.kick(shot: centreShot);
      e.kick();
    }
    final double before = e.state.nerve;
    if (e.canUseSelah && before > 0) {
      e.useSelah();
      expect(e.state.nerve, lessThan(before));
      expect(e.state.selahCharges, 2);
    }
    e.kick(shot: centreShot);
    expect(e.canUseSelah, isFalse);
    expect(e.useSelah, throwsStateError);
  });

  test('the Belt of Truth reveals the keeper after two kicks only', () {
    final MatchEngine e = MatchEngine(configFor(
      loadout: Loadout(ballId: 'love', gearId: _gear(GearSpecial.revealTendency).id),
    ));
    expect(e.revealedTendency, isNull);
    e.kick(shot: centreShot);
    e.kick();
    expect(e.revealedTendency, isNull);
    e.kick(shot: centreShot);
    e.kick();
    expect(e.revealedTendency, isNotNull);
    expect(MatchEngine(configFor()).revealedTendency, isNull);
  });

  test('the Shield of Faith is used once at most per match', () {
    final MatchEngine e = MatchEngine(configFor(
      seed: 4,
      loadout: Loadout(ballId: 'love', gearId: _gear(GearSpecial.postToGoalOnce).id),
    ));
    expect(e.shieldAvailable, isTrue);
    expect(MatchEngine(configFor()).shieldAvailable, isFalse);
  });

  test('an unknown ball or gear is rejected', () {
    expect(() => MatchEngine(configFor(loadout: const Loadout(ballId: 'nope'))), throwsArgumentError);
    expect(
      () => MatchEngine(configFor(loadout: const Loadout(ballId: 'love', gearId: 'nope'))),
      throwsArgumentError,
    );
  });

  test('history cannot be changed from outside', () {
    final MatchEngine e = MatchEngine(configFor());
    e.kick(shot: centreShot);
    expect(() => e.history.clear(), throwsUnsupportedError);
  });
}
