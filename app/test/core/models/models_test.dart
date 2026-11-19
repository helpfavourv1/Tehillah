import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/models/ball_def.dart';
import 'package:tehillah/core/models/gear_def.dart';
import 'package:tehillah/core/models/keeper_profile.dart';
import 'package:tehillah/core/models/kick_record.dart';
import 'package:tehillah/core/models/loadout.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/match_state.dart';
import 'package:tehillah/core/models/opponent_def.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/shot_params.dart';
import 'package:tehillah/core/models/stage_def.dart';
import 'package:tehillah/core/models/stat_mods.dart';

Map<String, Object?> viaJson(Map<String, Object?> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, Object?>;

KeeperProfile keeper() => KeeperProfile(
      reaction: 0.5,
      reach: 0.6,
      habitReading: 0.2,
      tendency: <KeeperDive, double>{
        for (final KeeperDive d in KeeperDive.values) d: 1 / 6,
      },
    );

OpponentDef opponent() =>
    OpponentDef(id: 's01r1', name: 'Tobin Ashgrove', team: 'Eden Rovers', keeper: keeper());

void main() {
  group('ShotParams', () {
    const ShotParams p =
        ShotParams(direction: -0.4, elevation: 0.7, power: 0.9, curve: 0.25);

    test('round-trips and compares by value', () {
      final ShotParams back = ShotParams.fromJson(viaJson(p.toJson()));
      expect(back, p);
      expect(back.hashCode, p.hashCode);
    });

    test('copyWith changes only the named field', () {
      final ShotParams q = p.copyWith(power: 0.1);
      expect(q.power, 0.1);
      expect(q.direction, p.direction);
      expect(q, isNot(p));
    });

    test('rejects out-of-range and missing values', () {
      expect(
        () => ShotParams.fromJson(<String, Object?>{
          'direction': 2, 'elevation': 0, 'power': 0, 'curve': 0,
        }),
        throwsFormatException,
      );
      expect(() => ShotParams.fromJson(<String, Object?>{}), throwsFormatException);
    });

    test('accepts integers where a number is expected', () {
      final ShotParams q = ShotParams.fromJson(<String, Object?>{
        'direction': 1, 'elevation': 0, 'power': 1, 'curve': -1,
      });
      expect(q.direction, 1.0);
    });
  });

  group('ShotOutcome and KickRecord', () {
    const ShotOutcome o = ShotOutcome(ShotResult.post, KeeperDive.leftHigh);

    test('outcome round-trips', () {
      expect(ShotOutcome.fromJson(viaJson(o.toJson())), o);
      expect(o.isGoal, isFalse);
      expect(const ShotOutcome(ShotResult.goal, KeeperDive.centerLow).isGoal, isTrue);
    });

    test('unknown enum names are rejected', () {
      expect(
        () => ShotOutcome.fromJson(<String, Object?>{'result': 'boom', 'dive': 'leftLow'}),
        throwsFormatException,
      );
    });

    test('dive zones expose side and height', () {
      expect(KeeperDive.rightHigh.side, DiveSide.right);
      expect(KeeperDive.rightHigh.high, isTrue);
      expect(KeeperDive.centerLow.high, isFalse);
    });

    test('kick record round-trips', () {
      const KickRecord k = KickRecord(
        side: MatchSide.opponent,
        round: 3,
        params: ShotParams(direction: 0, elevation: 0.5, power: 0.5, curve: 0),
        outcome: o,
      );
      final KickRecord back = KickRecord.fromJson(viaJson(k.toJson()));
      expect(back, k);
      expect(back.hashCode, k.hashCode);
    });

    test('kick record needs round 1 or more', () {
      expect(
        () => KickRecord.fromJson(<String, Object?>{
          'side': 'player',
          'round': 0,
          'params': const ShotParams(direction: 0, elevation: 0, power: 0, curve: 0).toJson(),
          'outcome': o.toJson(),
        }),
        throwsFormatException,
      );
    });
  });

  group('StatMods', () {
    test('writes only non-zero values and round-trips', () {
      const StatMods m = StatMods(aimForgiveness: 0.15, selahCharges: -1);
      expect(m.toJson().keys, unorderedEquals(<String>['aimForgiveness', 'selahCharges']));
      expect(StatMods.fromJson(viaJson(m.toJson())), m);
      expect(StatMods.fromJson(<String, Object?>{}), StatMods.none);
    });

    test('adds field by field', () {
      const StatMods a = StatMods(power: -0.05, selahCharges: -1);
      const StatMods b = StatMods(power: 0.02, lowShot: 0.2, selahCharges: 2);
      final StatMods s = a + b;
      expect(s.power, closeTo(-0.03, 1e-12));
      expect(s.lowShot, 0.2);
      expect(s.selahCharges, 1);
    });

    test('rejects out-of-range values', () {
      expect(() => StatMods.fromJson(<String, Object?>{'power': 5}), throwsFormatException);
    });
  });

  group('Loadout', () {
    test('round-trips with and without gear', () {
      const Loadout a = Loadout(ballId: 'joy', gearId: 'beltOfTruth');
      expect(Loadout.fromJson(viaJson(a.toJson())), a);
      expect(Loadout.fromJson(viaJson(Loadout.starter.toJson())), Loadout.starter);
    });

    test('copyWith can set and clear gear', () {
      const Loadout a = Loadout(ballId: 'joy', gearId: 'beltOfTruth');
      expect(a.copyWith(clearGear: true).gearId, isNull);
      expect(a.copyWith(ballId: 'peace').gearId, 'beltOfTruth');
      expect(Loadout.starter.copyWith(gearId: 'x').gearId, 'x');
    });

    test('rejects an empty ball id and a non-string gear id', () {
      expect(() => Loadout.fromJson(<String, Object?>{'ballId': ''}), throwsFormatException);
      expect(
        () => Loadout.fromJson(<String, Object?>{'ballId': 'love', 'gearId': 3}),
        throwsFormatException,
      );
    });
  });

  group('KeeperProfile and OpponentDef', () {
    test('round-trip and equality', () {
      final KeeperProfile k = keeper();
      expect(KeeperProfile.fromJson(viaJson(k.toJson())), k);
      expect(KeeperProfile.fromJson(viaJson(k.toJson())).hashCode, k.hashCode);
      expect(k.copyWith(reach: 0.9), isNot(k));
      final OpponentDef o = opponent();
      expect(OpponentDef.fromJson(viaJson(o.toJson())), o);
    });

    test('tendency is read-only', () {
      expect(() => keeper().tendency[KeeperDive.leftLow] = 1, throwsUnsupportedError);
    });

    test('a tendency with no weight is rejected', () {
      final Map<String, Object?> json = keeper().toJson();
      json['tendency'] = <String, Object?>{
        for (final KeeperDive d in KeeperDive.values) d.name: 0,
      };
      expect(() => KeeperProfile.fromJson(json), throwsFormatException);
    });
  });

  group('StageDef', () {
    test('round-trips and exposes its round count', () {
      final StageDef s = StageDef(
        id: 2,
        nameKey: 'stageArarat',
        difficulty: 0.2,
        wind: -0.3,
        isBoss: false,
        opponents: <OpponentDef>[opponent(), opponent()],
      );
      expect(s.rounds, 2);
      expect(StageDef.fromJson(viaJson(s.toJson())), s);
      expect(StageDef.fromJson(viaJson(s.toJson())).hashCode, s.hashCode);
    });

    test('an empty opponent list is rejected', () {
      expect(
        () => StageDef.fromJson(<String, Object?>{
          'id': 1, 'nameKey': 'k', 'difficulty': 0, 'wind': 0, 'isBoss': false,
          'opponents': <Object?>[],
        }),
        throwsFormatException,
      );
    });
  });

  group('BallDef and GearDef', () {
    test('ball round-trips', () {
      const BallDef b = BallDef(
        id: 'love', fruitKey: 'fruitLove', unlockLamps: 0,
        mods: StatMods(aimForgiveness: 0.15),
      );
      expect(BallDef.fromJson(viaJson(b.toJson())), b);
    });

    test('gear round-trips with its special rule', () {
      const GearDef g = GearDef(
        id: 'shieldOfFaith', armorKey: 'armorShieldOfFaith', unlockLamps: 4,
        mods: StatMods(powerWindow: -0.1), special: GearSpecial.postToGoalOnce,
      );
      final GearDef back = GearDef.fromJson(viaJson(g.toJson()));
      expect(back, g);
      expect(back.special, GearSpecial.postToGoalOnce);
    });
  });

  group('MatchConfig', () {
    final MatchConfig c = MatchConfig(
      mode: MatchMode.journey,
      opponent: opponent(),
      loadout: Loadout.starter,
      seed: 42,
      difficulty: 0.3,
      stageId: 3,
      round: 2,
      wind: 0.1,
    );

    test('round-trips and defaults to five kicks a side', () {
      expect(c.kicksPerSide, 5);
      expect(MatchConfig.fromJson(viaJson(c.toJson())), c);
      expect(MatchConfig.fromJson(viaJson(c.toJson())).hashCode, c.hashCode);
    });

    test('stage may be null for modes outside a stage', () {
      final MatchConfig f = MatchConfig(
        mode: MatchMode.friendly, opponent: opponent(),
        loadout: Loadout.starter, seed: 1, difficulty: 0.5,
      );
      expect(MatchConfig.fromJson(viaJson(f.toJson())).stageId, isNull);
    });

    test('copyWith keeps the rest', () {
      final MatchConfig d = c.copyWith(seed: 7);
      expect(d.seed, 7);
      expect(d.opponent, c.opponent);
      expect(d, isNot(c));
    });

    test('bad stage id is rejected', () {
      final Map<String, Object?> json = viaJson(c.toJson());
      json['stageId'] = 0;
      expect(() => MatchConfig.fromJson(json), throwsFormatException);
    });
  });

  group('MatchState', () {
    final MatchState start = MatchState.initial(
      kicksPerSide: 5, firstSide: MatchSide.player, selahCharges: 2,
    );

    test('starts level with the first side to kick', () {
      expect(start.turn, MatchSide.player);
      expect(start.isSuddenDeath, isFalse);
    });

    test('turn alternates with the kick counts', () {
      final MatchState after = start.copyWith(playerKicks: 1, playerScore: 1);
      expect(after.turn, MatchSide.opponent);
      final MatchState level = after.copyWith(opponentKicks: 1);
      expect(level.turn, MatchSide.player);
    });

    test('opponent-first matches alternate the other way', () {
      final MatchState s = MatchState.initial(
        kicksPerSide: 5, firstSide: MatchSide.opponent, selahCharges: 0,
      );
      expect(s.turn, MatchSide.opponent);
      expect(s.copyWith(opponentKicks: 1).turn, MatchSide.player);
    });

    test('sudden death starts after the regular kicks', () {
      final MatchState s = start.copyWith(playerKicks: 5, opponentKicks: 5);
      expect(s.isSuddenDeath, isTrue);
      expect(start.copyWith(playerKicks: 5, opponentKicks: 4).isSuddenDeath, isFalse);
    });

    test('accessors by side', () {
      final MatchState s = start.copyWith(
        playerKicks: 2, opponentKicks: 1, playerScore: 2, opponentScore: 0,
      );
      expect(s.kicksOf(MatchSide.player), 2);
      expect(s.scoreOf(MatchSide.opponent), 0);
    });

    test('round-trips', () {
      final MatchState s = start.copyWith(playerKicks: 1, playerScore: 1, nerve: 0.4);
      expect(MatchState.fromJson(viaJson(s.toJson())), s);
      expect(MatchState.fromJson(viaJson(s.toJson())).hashCode, s.hashCode);
    });

    test('inconsistent saved states are rejected', () {
      final Map<String, Object?> bad = start.toJson();
      bad['playerKicks'] = 3;
      expect(() => MatchState.fromJson(bad), throwsFormatException);
      final Map<String, Object?> over = start.toJson();
      over['playerScore'] = 1;
      expect(() => MatchState.fromJson(over), throwsFormatException);
    });
  });
}
