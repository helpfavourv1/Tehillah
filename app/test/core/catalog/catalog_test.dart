import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/catalog/ball_catalog.dart';
import 'package:tehillah/core/catalog/gear_catalog.dart';
import 'package:tehillah/core/catalog/stage_catalog.dart';
import 'package:tehillah/core/models/ball_def.dart';
import 'package:tehillah/core/models/gear_def.dart';
import 'package:tehillah/core/models/opponent_def.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/stage_def.dart';

void main() {
  group('StageCatalog', () {
    test('has twelve stages in order with four rounds each', () {
      expect(StageCatalog.stages, hasLength(12));
      for (int i = 0; i < 12; i++) {
        final StageDef s = StageCatalog.stages[i];
        expect(s.id, i + 1);
        expect(s.rounds, StageCatalog.roundsPerStage);
      }
    });

    test('difficulty rises stage to stage and round to round', () {
      for (int i = 1; i < 12; i++) {
        expect(StageCatalog.stages[i].difficulty,
            greaterThan(StageCatalog.stages[i - 1].difficulty));
      }
      for (final StageDef s in StageCatalog.stages) {
        for (int r = 1; r < s.rounds; r++) {
          expect(s.opponents[r].keeper.reaction,
              greaterThan(s.opponents[r - 1].keeper.reaction));
        }
      }
    });

    test('the bosses are the Valley of Elah and New Jerusalem', () {
      final List<int> bosses = <int>[
        for (final StageDef s in StageCatalog.stages)
          if (s.isBoss) s.id,
      ];
      expect(bosses, <int>[6, 12]);
      expect(StageCatalog.byId(12)!.nameKey, 'stageNewJerusalem');
    });

    test('48 opponents with unique ids and unique names', () {
      final List<OpponentDef> all = <OpponentDef>[
        for (final StageDef s in StageCatalog.stages) ...s.opponents,
      ];
      expect(all, hasLength(48));
      expect(all.map((OpponentDef o) => o.id).toSet(), hasLength(48));
      expect(all.map((OpponentDef o) => o.name).toSet(), hasLength(48));
    });

    test('every keeper tendency covers all dives and sums to one', () {
      for (final StageDef s in StageCatalog.stages) {
        for (final OpponentDef o in s.opponents) {
          expect(o.keeper.tendency.keys, unorderedEquals(KeeperDive.values));
          final double total =
              o.keeper.tendency.values.fold(0.0, (double a, double b) => a + b);
          expect(total, closeTo(1, 1e-9));
          expect(o.keeper.reaction, inInclusiveRange(0, 1));
          expect(o.keeper.reach, inInclusiveRange(0, 1));
        }
      }
    });

    test('keepers learn habits only from Damascus Road on', () {
      expect(StageCatalog.byId(8)!.opponents.first.keeper.habitReading, 0);
      expect(StageCatalog.byId(9)!.opponents.first.keeper.habitReading, greaterThan(0));
    });

    test('lookup of an unknown stage is null', () {
      expect(StageCatalog.byId(13), isNull);
      expect(StageCatalog.byId(0), isNull);
    });

    test('the catalog is read-only and each stage survives a JSON round trip', () {
      expect(() => StageCatalog.stages.add(StageCatalog.stages.first), throwsUnsupportedError);
      for (final StageDef s in StageCatalog.stages) {
        expect(StageDef.fromJson(s.toJson()), s);
      }
    });
  });

  group('BallCatalog', () {
    test('has the nine fruit balls and love is free', () {
      expect(BallCatalog.all, hasLength(9));
      expect(BallCatalog.all.map((BallDef b) => b.id).toSet(), hasLength(9));
      expect(BallCatalog.byId('love')!.unlockLamps, 0);
      expect(BallCatalog.byId('nope'), isNull);
    });

    test('a second ball unlocks after the first stage', () {
      expect(BallCatalog.all.where((BallDef b) => b.unlockLamps <= 1), hasLength(2));
    });

    test('every ball has both a benefit and a trade-off', () {
      for (final BallDef b in BallCatalog.all) {
        expect(b.mods.toJson(), isNotEmpty, reason: b.id);
      }
    });
  });

  group('GearCatalog', () {
    test('has six items, a first choice at Ararat and the right rules', () {
      expect(GearCatalog.all, hasLength(6));
      expect(GearCatalog.all.map((GearDef g) => g.id).toSet(), hasLength(6));
      expect(GearCatalog.all.where((GearDef g) => g.unlockLamps <= 1), hasLength(1));
      expect(GearCatalog.byId('beltOfTruth')!.special, GearSpecial.revealTendency);
      expect(GearCatalog.byId('shieldOfFaith')!.special, GearSpecial.postToGoalOnce);
      expect(GearCatalog.byId('helmetOfSalvation')!.special, GearSpecial.selahFloor);
      expect(GearCatalog.byId('x'), isNull);
    });
  });
}
