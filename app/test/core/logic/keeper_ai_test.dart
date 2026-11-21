import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/logic/keeper_ai.dart';
import 'package:tehillah/core/logic/seeded_rng.dart';
import 'package:tehillah/core/models/keeper_profile.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/shot_params.dart';

KeeperProfile _profile({double habit = 0, Map<KeeperDive, double>? tendency}) {
  return KeeperProfile(
    reaction: 0.5,
    reach: 0.5,
    habitReading: habit,
    tendency: tendency ??
        <KeeperDive, double>{for (final KeeperDive d in KeeperDive.values) d: 1},
  );
}

const ShotParams _leftLow =
    ShotParams(direction: -0.8, elevation: 0.2, power: 0.7, curve: 0);

void main() {
  test('follows the tendency table when it reads no habits', () {
    final KeeperProfile p = _profile(
      tendency: <KeeperDive, double>{
        KeeperDive.leftLow: 8,
        KeeperDive.leftHigh: 1,
        KeeperDive.centerLow: 0,
        KeeperDive.centerHigh: 0,
        KeeperDive.rightLow: 0,
        KeeperDive.rightHigh: 1,
      },
    );
    final SeededRng rng = SeededRng(5);
    final Map<KeeperDive, int> counts = <KeeperDive, int>{};
    for (int i = 0; i < 2000; i++) {
      final KeeperDive d = KeeperAi.decide(profile: p, playerShots: const <ShotParams>[], rng: rng);
      counts[d] = (counts[d] ?? 0) + 1;
    }
    expect(counts[KeeperDive.leftLow]! / 2000, closeTo(0.8, 0.04));
    expect(counts.containsKey(KeeperDive.centerLow), isFalse);
  });

  test('a habit-reading keeper starts favouring where the player aims', () {
    final KeeperProfile p = _profile(habit: 0.9);
    final List<ShotParams> shots = List<ShotParams>.filled(6, _leftLow);
    final SeededRng rng = SeededRng(8);
    int left = 0;
    for (int i = 0; i < 1000; i++) {
      if (KeeperAi.decide(profile: p, playerShots: shots, rng: rng) == KeeperDive.leftLow) {
        left++;
      }
    }
    expect(left / 1000, greaterThan(0.6));
  });

  test('it does not read habits from fewer than two kicks', () {
    final KeeperProfile p = _profile(habit: 1);
    final List<double> one = KeeperAi.diveWeights(p, <ShotParams>[_leftLow]);
    expect(one, everyElement(1.0));
    final List<double> two = KeeperAi.diveWeights(p, <ShotParams>[_leftLow, _leftLow]);
    expect(two[KeeperDive.leftLow.index], greaterThan(two[KeeperDive.rightHigh.index]));
  });

  test('the same seed gives the same dives', () {
    final KeeperProfile p = _profile(habit: 0.5);
    List<KeeperDive> run() {
      final SeededRng rng = SeededRng(77);
      return <KeeperDive>[
        for (int i = 0; i < 30; i++)
          KeeperAi.decide(profile: p, playerShots: <ShotParams>[_leftLow, _leftLow], rng: rng),
      ];
    }

    expect(run(), run());
  });

  test('mostLikely picks the heaviest tendency', () {
    final KeeperProfile p = _profile(
      tendency: <KeeperDive, double>{
        for (final KeeperDive d in KeeperDive.values)
          d: d == KeeperDive.rightHigh ? 3 : 1,
      },
    );
    expect(KeeperAi.mostLikely(p), KeeperDive.rightHigh);
  });
}
