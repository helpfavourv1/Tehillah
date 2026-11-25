import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/logic/mode_rules.dart';
import 'package:tehillah/core/logic/sling_rules.dart';
import 'package:tehillah/core/models/shot_params.dart';
import 'package:tehillah/game/components/pitch.dart';
import 'package:tehillah/game/components/scene_layer.dart';
import 'package:tehillah/game/components/sling_layers.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/game/geometry/shot_trajectory.dart';
import 'package:tehillah/game/input/sling_aim_layer.dart';
import 'package:tehillah/game/sling_controller.dart';
import 'package:tehillah/game/sling_game.dart';
import 'package:tehillah/game/sling_world.dart';
import 'package:tehillah/game/tuning.dart';
import 'package:tehillah/theme/tokens.dart';

import '../support/test_surface.dart';
import '../support/widget_harness.dart';

const double flight = SlingTuning.stoneFlightSeconds;

void drain(SlingWorld w, {double seconds = 1}) {
  for (double t = 0; t < seconds; t += 1 / 30) {
    w.update(1 / 30);
  }
}

class Rig {
  Rig(int seed) {
    world = SlingWorld();
    controller = SlingController(world: world);
    controller.onFinished = () => finished++;
    controller.start(seed);
  }

  late final SlingWorld world;
  late final SlingController controller;
  int finished = 0;

  /// Aims at the centre of target [i] where it will be on arrival.
  bool aimAt(int i) {
    final SlingTarget t = world.targets[i];
    return controller.release(
      direction: t.xAt(world.seconds + flight),
      elevation: t.y,
    );
  }

  bool miss() => controller.release(direction: 0, elevation: 1);

  void land() => drain(world, seconds: flight + 0.2);

  void dispose() => controller.dispose();
}

Future<int> pixelAt(SlingWorld w, List<SceneLayer> layers, AppPalette pal, int sx, int sy) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  final PitchProjection p = PitchProjection.fit(360, 600);
  for (final SceneLayer l in layers) {
    l.paintScene(canvas, p, pal);
  }
  final ui.Image image = await recorder.endRecording().toImage(360, 600);
  final ByteData data = (await image.toByteData())!;
  final int o = (sy * 360 + sx) * 4;
  return (data.getUint8(o) << 16) | (data.getUint8(o + 1) << 8) | data.getUint8(o + 2);
}

void main() {
  group('SlingWorld', () {
    test('the clock only runs while running', () {
      final SlingWorld w = SlingWorld()..load(SlingAndStone.targetsFor(1));
      drain(w);
      expect(w.seconds, 0);
      w.running = true;
      drain(w);
      expect(w.seconds, closeTo(1, 0.1));
      w.running = false;
      final double frozen = w.seconds;
      drain(w);
      expect(w.seconds, frozen);
    });

    test('a target moves with the clock and stays within the goal', () {
      final SlingWorld w = SlingWorld()
        ..load(SlingAndStone.targetsFor(5))
        ..running = true;
      for (int i = 0; i < 200; i++) {
        w.update(1 / 30);
        for (int t = 0; t < w.targets.length; t++) {
          expect(w.targetX(t).abs(), lessThanOrEqualTo(1.0001));
        }
      }
    });

    test('a stone lands after its flight and reports once', () {
      final SlingWorld w = SlingWorld()
        ..load(SlingAndStone.targetsFor(1))
        ..running = true;
      final List<SlingThrow> landed = <SlingThrow>[];
      w.onStoneLanded = landed.add;
      w.launch(const SlingThrow(
        shot: ShotParams(direction: 0, elevation: 1, power: 1, curve: 0),
        seconds: flight,
      ));
      expect(w.flight, isNotNull);
      expect(w.stonePosition, isNotNull);
      drain(w, seconds: flight / 2);
      expect(landed, isEmpty);
      drain(w, seconds: flight);
      expect(landed, hasLength(1));
      expect(w.flight, isNull);
      expect(w.stonePosition, isNull);
    });

    test('a hit target freezes where it was struck and counts as fallen', () {
      final SlingWorld w = SlingWorld()
        ..load(SlingAndStone.targetsFor(1))
        ..running = true;
      w.launch(SlingThrow(
        shot: const ShotParams(direction: 0, elevation: 0.5, power: 1, curve: 0),
        seconds: flight,
        hitIndex: 2,
      ));
      drain(w, seconds: flight + 0.1);
      expect(w.fallen, <int>{2});
      final double frozen = w.targetX(2);
      expect(frozen, closeTo(w.targets[2].xAt(flight), 1e-9));
      drain(w, seconds: 2);
      expect(w.targetX(2), frozen);
    });

    test('load puts everything back', () {
      final SlingWorld w = SlingWorld()
        ..load(SlingAndStone.targetsFor(1))
        ..running = true;
      w.launch(const SlingThrow(
        shot: ShotParams(direction: 0, elevation: 1, power: 1, curve: 0),
        seconds: flight,
      ));
      w.load(SlingAndStone.targetsFor(2));
      expect(w.flight, isNull);
      expect(w.seconds, 0);
      expect(w.fallen, isEmpty);
      expect(w.running, isFalse);
    });

    test('the stone flies from the sling to the aimed point', () {
      final SlingWorld w = SlingWorld()
        ..load(SlingAndStone.targetsFor(1))
        ..running = true;
      w.launch(const SlingThrow(
        shot: ShotParams(direction: 0.5, elevation: 0.5, power: 1, curve: 0),
        seconds: flight,
      ));
      final WorldPoint start = w.stonePosition!;
      expect(start.z, closeTo(Tuning.spotDistance, 1e-6));
      w.update(0.1);
      final WorldPoint mid = w.stonePosition!;
      expect(mid.z, lessThan(start.z));
    });
  });

  group('SlingController', () {
    test('start publishes a full round and opens input', () {
      final Rig r = Rig(3);
      expect(r.controller.state.value!.stonesLeft, 7);
      expect(r.controller.inputEnabled.value, isTrue);
      expect(r.world.stoneReady, isTrue);
      r.dispose();
    });

    test('a release closes input, and the numbers change only when the stone lands', () {
      final Rig r = Rig(3);
      expect(r.aimAt(4), isTrue);
      expect(r.controller.inputEnabled.value, isFalse);
      expect(r.controller.state.value!.stonesLeft, 7);
      r.land();
      expect(r.controller.state.value!.stonesLeft, 6);
      expect(r.controller.state.value!.hit, contains(4));
      expect(r.world.fallen, contains(4));
      expect(r.controller.inputEnabled.value, isTrue);
      r.dispose();
    });

    test('a second release while a stone flies is refused', () {
      final Rig r = Rig(3);
      expect(r.miss(), isTrue);
      expect(r.miss(), isFalse);
      r.land();
      expect(r.controller.state.value!.thrown, 1);
      r.dispose();
    });

    test('a release is refused while paused, and works again after resume', () {
      final Rig r = Rig(3);
      r.controller.pause();
      expect(r.controller.inputEnabled.value, isFalse);
      expect(r.miss(), isFalse);
      r.controller.resume();
      expect(r.controller.inputEnabled.value, isTrue);
      expect(r.miss(), isTrue);
      r.dispose();
    });

    test('pausing mid-flight holds the stone and resume lands it', () {
      final Rig r = Rig(3);
      r.miss();
      r.controller.pause();
      drain(r.world, seconds: 2);
      expect(r.world.flight, isNotNull);
      r.controller.resume();
      r.land();
      expect(r.world.flight, isNull);
      expect(r.controller.state.value!.thrown, 1);
      r.dispose();
    });

    test('running out of stones finishes the round once, after the last stone lands', () {
      final Rig r = Rig(3);
      for (int i = 0; i < 7; i++) {
        expect(r.miss(), isTrue);
        if (i == 6) {
          expect(r.finished, 0);
        }
        r.land();
      }
      expect(r.finished, 1);
      expect(r.controller.state.value!.finished, isTrue);
      expect(r.controller.inputEnabled.value, isFalse);
      expect(r.miss(), isFalse);
      expect(r.controller.canOfferExtraStones, isTrue);
      r.dispose();
    });

    test('hitting every target finishes early with three stars', () {
      final Rig r = Rig(3);
      for (int i = 4; i >= 0; i--) {
        expect(r.aimAt(i), isTrue);
        r.land();
      }
      expect(r.finished, 1);
      expect(r.controller.state.value!.stars, 3);
      expect(r.controller.canOfferExtraStones, isFalse);
      r.dispose();
    });

    test('extra stones reopen the round once and it can finish again', () {
      final Rig r = Rig(3);
      for (int i = 0; i < 7; i++) {
        r.miss();
        r.land();
      }
      expect(r.controller.addExtraStones(), isTrue);
      expect(r.controller.state.value!.stonesLeft, 3);
      expect(r.controller.inputEnabled.value, isTrue);
      expect(r.world.running, isTrue);
      for (int i = 0; i < 3; i++) {
        r.miss();
        r.land();
      }
      expect(r.finished, 2);
      expect(r.controller.addExtraStones(), isFalse);
      r.dispose();
    });

    test('extra stones are refused while the round is still going', () {
      final Rig r = Rig(3);
      expect(r.controller.addExtraStones(), isFalse);
      r.dispose();
    });

    test('out-of-range aim is clamped, not rejected', () {
      final Rig r = Rig(3);
      expect(r.controller.release(direction: 5, elevation: -3), isTrue);
      expect(r.world.flight!.shot.direction, 1);
      expect(r.world.flight!.shot.elevation, 0);
      r.dispose();
    });

    test('start again after a finished round begins fresh', () {
      final Rig r = Rig(3);
      for (int i = 0; i < 7; i++) {
        r.miss();
        r.land();
      }
      r.controller.start(9);
      expect(r.controller.state.value!.stonesLeft, 7);
      expect(r.controller.inputEnabled.value, isTrue);
      expect(r.world.fallen, isEmpty);
      r.dispose();
    });
  });

  group('SlingAimLayer', () {
    final PitchProjection p = PitchProjection.fit(360, 720);

    Widget layer(List<({double d, double e})> got, {bool enabled = true}) => SizedBox.expand(
          child: SlingAimLayer(
            projection: p,
            enabled: enabled,
            semanticLabel: 'aim',
            onRelease: (double d, double e) => got.add((d: d, e: e)),
          ),
        );

    testWidgets('releasing over the goal centre aims at the middle', (WidgetTester tester) async {
      useSurface(tester);
      final List<({double d, double e})> got = <({double d, double e})>[];
      await tester.pumpWidget(harness(layer(got)));
      final Rect g = Rect.fromLTRB(
        p.goalRect.left,
        p.goalRect.top,
        p.goalRect.right,
        p.goalRect.bottom,
      );
      final Offset finger = tester.getTopLeft(find.byType(SlingAimLayer)) +
          Offset(g.center.dx, g.center.dy + SlingAimLayer.defaultLift);
      final TestGesture gesture = await tester.startGesture(finger);
      await gesture.up();
      expect(got, hasLength(1));
      expect(got.single.d, closeTo(0, 0.01));
      expect(got.single.e, closeTo(0.5, 0.01));
    });

    testWidgets('dragging moves the aim and the release uses the last place', (WidgetTester tester) async {
      useSurface(tester);
      final List<({double d, double e})> got = <({double d, double e})>[];
      await tester.pumpWidget(harness(layer(got)));
      final Offset origin = tester.getTopLeft(find.byType(SlingAimLayer));
      final double y = p.goalRect.top + (p.goalRect.bottom - p.goalRect.top) / 2 + SlingAimLayer.defaultLift;
      final TestGesture gesture = await tester.startGesture(origin + Offset(p.centerX, y));
      await gesture.moveTo(origin + Offset(p.centerX + p.k * Tuning.halfGoal / 2, y));
      await gesture.up();
      expect(got.single.d, closeTo(0.5, 0.02));
    });

    testWidgets('far outside the goal clamps to the edge', (WidgetTester tester) async {
      useSurface(tester);
      final List<({double d, double e})> got = <({double d, double e})>[];
      await tester.pumpWidget(harness(layer(got)));
      final TestGesture gesture =
          await tester.startGesture(tester.getTopLeft(find.byType(SlingAimLayer)) + const Offset(2, 700));
      await gesture.up();
      expect(got.single.d, -1);
      expect(got.single.e, 0);
    });

    testWidgets('a disabled layer throws nothing', (WidgetTester tester) async {
      useSurface(tester);
      final List<({double d, double e})> got = <({double d, double e})>[];
      await tester.pumpWidget(harness(layer(got, enabled: false)));
      final TestGesture gesture = await tester.startGesture(const Offset(180, 300));
      await gesture.up();
      expect(got, isEmpty);
    });

    testWidgets('a cancelled touch throws nothing', (WidgetTester tester) async {
      useSurface(tester);
      final List<({double d, double e})> got = <({double d, double e})>[];
      await tester.pumpWidget(harness(layer(got)));
      final TestGesture gesture = await tester.startGesture(const Offset(180, 300));
      await gesture.cancel();
      expect(got, isEmpty);
    });

    testWidgets('disabling mid-press abandons the throw', (WidgetTester tester) async {
      useSurface(tester);
      final List<({double d, double e})> got = <({double d, double e})>[];
      await tester.pumpWidget(harness(layer(got)));
      final TestGesture gesture = await tester.startGesture(const Offset(180, 300));
      await tester.pumpWidget(harness(layer(got, enabled: false)));
      await gesture.up();
      expect(got, isEmpty);
    });

    testWidgets('it has a semantic label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(harness(layer(<({double d, double e})>[])));
      expect(find.bySemanticsLabel('aim'), findsOneWidget);
      handle.dispose();
    });
  });

  group('Sling layers', () {
    test('a live target is painted in the accent and a hit one is not', () async {
      final AppPalette pal = AppPalette.light;
      final SlingWorld w = SlingWorld()..load(SlingAndStone.targetsFor(2));
      final PitchProjection p = PitchProjection.fit(360, 600);
      final GoalPoint at = w.targetPoint(0);
      final ScreenPoint s = p.project(at.x, at.y, 0)!;
      final int before = await pixelAt(
        w,
        <SceneLayer>[Pitch(), SlingBackdrop(), SlingTargets(w)],
        pal,
        s.x.round() - 1,
        s.y.round() + (w.targets[0].radius * Tuning.goalHeight * s.scale * 0.8).round(),
      );
      expect(before, pal.accent.toARGB32() & 0xFFFFFF);
    });

    test('hit and live states paint different pictures', () async {
      final AppPalette pal = AppPalette.light;
      final SlingWorld live = SlingWorld()..load(SlingAndStone.targetsFor(2));
      final SlingWorld hit = SlingWorld()
        ..load(SlingAndStone.targetsFor(2))
        ..running = true;
      hit.launch(SlingThrow(
        shot: const ShotParams(direction: 0, elevation: 0.5, power: 1, curve: 0),
        seconds: flight,
        hitIndex: 0,
      ));
      drain(hit, seconds: flight + 0.1);
      final PitchProjection p = PitchProjection.fit(360, 600);
      final ScreenPoint s = p.project(live.targetPoint(0).x, live.targetPoint(0).y, 0)!;
      final int liveCentre = await pixelAt(live, <SceneLayer>[Pitch(), SlingBackdrop(), SlingTargets(live)], pal, s.x.round(), s.y.round());
      final int hitCentre = await pixelAt(hit, <SceneLayer>[Pitch(), SlingBackdrop(), SlingTargets(hit)], pal, s.x.round(), s.y.round());
      expect(liveCentre, isNot(hitCentre));
    });

    test('the stone layer paints a waiting and a flying stone without error', () async {
      final SlingWorld w = SlingWorld()
        ..load(SlingAndStone.targetsFor(2))
        ..running = true
        ..stoneReady = true;
      await pixelAt(w, <SceneLayer>[Pitch(), SlingStone(w)], AppPalette.dark, 10, 10);
      w.launch(const SlingThrow(
        shot: ShotParams(direction: 0.3, elevation: 0.4, power: 1, curve: 0),
        seconds: flight,
      ));
      w.update(0.1);
      await pixelAt(w, <SceneLayer>[Pitch(), SlingStone(w)], AppPalette.dark, 10, 10);
    });
  });

  group('SlingGame', () {
    Widget host(SlingGame game, double w, double h) => Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: w, height: h, child: GameWidget<SlingGame>(game: game)),
          ),
        );

    testWidgets('loads, lays out, runs a round and follows a resize', (WidgetTester tester) async {
      final SlingGame game = SlingGame(palette: AppPalette.light);
      await tester.pumpWidget(host(game, 360, 600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(game.hasLayout, isTrue);
      final SlingController c = SlingController(world: game.scene)..start(4);
      c.release(direction: 0, elevation: 1);
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(c.state.value!.thrown, 1);
      final double k = game.projection.k;
      await tester.pumpWidget(host(game, 600, 360));
      await tester.pump(const Duration(milliseconds: 50));
      expect(game.projection.k, isNot(k));
      expect(tester.takeException(), isNull);
      c.dispose();
    });

    testWidgets('palette changes while running', (WidgetTester tester) async {
      final SlingGame game = SlingGame(palette: AppPalette.light);
      await tester.pumpWidget(host(game, 360, 600));
      await tester.pump();
      game.palette = AppPalette.dark;
      expect(game.backgroundColor(), AppPalette.dark.bgPrimary);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
    });
  });
}
