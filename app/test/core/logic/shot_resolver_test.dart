import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/catalog/gear_catalog.dart';
import 'package:tehillah/core/logic/modifiers.dart';
import 'package:tehillah/core/logic/seeded_rng.dart';
import 'package:tehillah/core/logic/shot_resolver.dart';
import 'package:tehillah/core/models/gear_def.dart';
import 'package:tehillah/core/models/keeper_profile.dart';
import 'package:tehillah/core/models/loadout.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/shot_params.dart';

KeeperProfile _keeper(double skill) => KeeperProfile(
      reaction: skill,
      reach: skill,
      habitReading: 0,
      tendency: <KeeperDive, double>{
        for (final KeeperDive d in KeeperDive.values) d: 1,
      },
    );

ShotResolution _resolve(
  ShotParams p,
  KeeperDive dive,
  int seed, {
  Modifiers mods = Modifiers.none,
  double nerve = 0,
  double wind = 0,
  double skill = 1,
  bool shield = false,
}) {
  return ShotResolver.resolve(
    params: p,
    dive: dive,
    mods: mods,
    nerve: nerve,
    wind: wind,
    keeper: _keeper(skill),
    rng: SeededRng(seed),
    postToGoalAvailable: shield,
  );
}

int _count(ShotParams p, KeeperDive dive, ShotResult r, {double skill = 1}) {
  int n = 0;
  for (int seed = 1; seed <= 300; seed++) {
    if (_resolve(p, dive, seed, skill: skill).outcome.result == r) {
      n++;
    }
  }
  return n;
}

void main() {
  const ShotParams middle =
      ShotParams(direction: 0, elevation: 0.2, power: 0.5, curve: 0);

  test('the same inputs always give the same result', () {
    for (int seed = 1; seed < 50; seed++) {
      final ShotResolution a = _resolve(middle, KeeperDive.leftLow, seed);
      final ShotResolution b = _resolve(middle, KeeperDive.leftLow, seed);
      expect(a.outcome, b.outcome);
    }
  });

  test('exactly 14 generator reads whatever the result', () {
    final List<ShotParams> shots = <ShotParams>[
      middle,
      const ShotParams(direction: 1, elevation: 0.5, power: 1, curve: 1),
      const ShotParams(direction: -1, elevation: 1, power: 0.2, curve: -1),
    ];
    for (final ShotParams s in shots) {
      final SeededRng rng = SeededRng(9);
      ShotResolver.resolve(
        params: s,
        dive: KeeperDive.centerLow,
        mods: Modifiers.none,
        nerve: 0.5,
        wind: 0.2,
        keeper: _keeper(0.5),
        rng: rng,
      );
      expect(rng.nextUint32(), _after14());
    }
  });

  test('a shot far outside the post is wide', () {
    const ShotParams wide =
        ShotParams(direction: 1, elevation: 0.3, power: 0.78, curve: 1);
    expect(_count(wide, KeeperDive.centerLow, ShotResult.wide), 300);
  });

  test('a flawless keeper stops a soft shot down the middle when dived right', () {
    expect(_count(middle, KeeperDive.centerLow, ShotResult.saved), greaterThan(250));
  });

  test('a keeper diving to the far side almost never saves', () {
    const ShotParams right =
        ShotParams(direction: 0.7, elevation: 0.2, power: 0.5, curve: 0);
    expect(_count(right, KeeperDive.leftLow, ShotResult.saved), lessThan(60));
    expect(_count(right, KeeperDive.rightLow, ShotResult.saved), greaterThan(200));
  });

  test('a weak keeper saves less than a strong one', () {
    final int weak = _count(middle, KeeperDive.centerLow, ShotResult.saved, skill: 0.2);
    final int strong = _count(middle, KeeperDive.centerLow, ShotResult.saved);
    expect(weak, lessThan(strong));
  });

  test('coverage is 1 for the same cell and falls with distance', () {
    expect(ShotResolver.coverage(0, false), 1.0);
    expect(ShotResolver.coverage(0, true), 0.75);
    expect(ShotResolver.coverage(1, false), 0.55);
    expect(ShotResolver.coverage(1, true), 0.35);
    expect(ShotResolver.coverage(2, false), 0.10);
    expect(ShotResolver.coverage(2, true), 0.10);
  });

  test('high nerve makes the aim worse', () {
    const ShotParams corner =
        ShotParams(direction: 0.9, elevation: 0.3, power: 0.78, curve: 0);
    int offTarget(double nerve) {
      int n = 0;
      for (int seed = 1; seed <= 400; seed++) {
        final ShotResult r = _resolve(corner, KeeperDive.leftLow, seed, nerve: nerve).outcome.result;
        if (r == ShotResult.wide || r == ShotResult.post) {
          n++;
        }
      }
      return n;
    }

    expect(offTarget(1.0), greaterThan(offTarget(0.0)));
  });

  test('aim forgiveness turns near misses into shots on target', () {
    const ShotParams edge =
        ShotParams(direction: 1.0, elevation: 0.3, power: 0.78, curve: 0);
    int onTarget(Modifiers m) {
      int n = 0;
      for (int seed = 1; seed <= 400; seed++) {
        final ShotResult r = _resolve(edge, KeeperDive.leftLow, seed, mods: m).outcome.result;
        if (r == ShotResult.goal || r == ShotResult.saved) {
          n++;
        }
      }
      return n;
    }

    expect(onTarget(const Modifiers(aimForgiveness: 0.3)),
        greaterThan(onTarget(Modifiers.none)));
  });

  test('the Shield of Faith turns one post into a goal and reports it', () {
    const ShotParams postShot =
        ShotParams(direction: 1.0, elevation: 0.5, power: 0.78, curve: 0);
    final Modifiers shield = Modifiers.fromLoadout(
      Loadout(ballId: 'love', gearId: GearCatalog.all.firstWhere((GearDef g) => g.special == GearSpecial.postToGoalOnce).id),
    );
    int? found;
    for (int seed = 1; seed <= 500 && found == null; seed++) {
      if (_resolve(postShot, KeeperDive.leftLow, seed).outcome.result == ShotResult.post) {
        found = seed;
      }
    }
    expect(found, isNotNull);
    final ShotResolution withShield = _resolve(postShot, KeeperDive.leftLow, found!,
        mods: shield, shield: true);
    expect(withShield.outcome.result, ShotResult.goal);
    expect(withShield.shieldUsed, isTrue);
    final ShotResolution spent = _resolve(postShot, KeeperDive.leftLow, found,
        mods: shield, shield: false);
    expect(spent.outcome.result, ShotResult.post);
    expect(spent.shieldUsed, isFalse);
  });

  test('GoalGrid maps positions to dives', () {
    expect(GoalGrid.diveFor(-0.9, 0.1), KeeperDive.leftLow);
    expect(GoalGrid.diveFor(0.0, 0.9), KeeperDive.centerHigh);
    expect(GoalGrid.diveFor(0.5, 0.5), KeeperDive.rightHigh);
    expect(GoalGrid.sideOf(-1 / 3), DiveSide.center);
  });
}

int _after14() {
  final SeededRng r = SeededRng(9);
  for (int i = 0; i < 14; i++) {
    r.nextUint32();
  }
  return r.nextUint32();
}
