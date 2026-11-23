import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/models/kick_record.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/shot_params.dart';
import 'package:tehillah/game/components/ball.dart';
import 'package:tehillah/game/components/effects.dart';
import 'package:tehillah/game/components/goal.dart';
import 'package:tehillah/game/components/keeper.dart';
import 'package:tehillah/game/components/pitch.dart';
import 'package:tehillah/game/components/scene_layer.dart';
import 'package:tehillah/game/components/shooter.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/game/geometry/shot_trajectory.dart';
import 'package:tehillah/game/match_world.dart';
import 'package:tehillah/game/tehillah_game.dart';
import 'package:tehillah/game/tuning.dart';
import 'package:tehillah/theme/tokens.dart';

KickRecord kick(ShotResult result, {MatchSide side = MatchSide.player}) => KickRecord(
      side: side,
      round: 1,
      params: const ShotParams(direction: 0.6, elevation: 0.5, power: 0.8, curve: 0.5),
      outcome: ShotOutcome(result, KeeperDive.rightLow),
    );

List<SceneLayer> layersFor(MatchWorld w) => <SceneLayer>[
      Pitch(),
      GoalNet(w),
      Keeper(w),
      GoalFrame(),
      Shooter(w),
      Ball(w),
      Effects(w),
    ];

Future<({ByteData data, int width})> rasterize(
  MatchWorld w,
  AppPalette palette,
  int width,
  int height, {
  List<SceneLayer>? only,
}) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final ui.Canvas canvas = ui.Canvas(recorder);
  final PitchProjection p = PitchProjection.fit(width.toDouble(), height.toDouble());
  for (final SceneLayer l in only ?? layersFor(w)) {
    l.paintScene(canvas, p, palette);
  }
  final ui.Image image = await recorder.endRecording().toImage(width, height);
  final ByteData? data = await image.toByteData();
  return (data: data!, width: width);
}

int pixel(({ByteData data, int width}) img, int x, int y) {
  final int o = (y * img.width + x) * 4;
  final int r = img.data.getUint8(o);
  final int g = img.data.getUint8(o + 1);
  final int b = img.data.getUint8(o + 2);
  final int a = img.data.getUint8(o + 3);
  return (a << 24) | (r << 16) | (g << 8) | b;
}

void main() {
  const List<({String name, int w, int h})> sizes = <({String name, int w, int h})>[
    (name: 'portrait', w: 360, h: 800),
    (name: 'landscape', w: 800, h: 360),
    (name: 'tiny', w: 120, h: 160),
  ];
  const List<AppPalette> palettes = <AppPalette>[AppPalette.light, AppPalette.dark, AppPalette.sepia];

  group('painting', () {
    for (final ({String name, int w, int h}) s in sizes) {
      for (final AppPalette pal in palettes) {
        testWidgets('${s.name} ${pal.mode.name}: every layer paints through a whole kick',
            (WidgetTester tester) async {
          await tester.runAsync(() async {
            for (final ShotResult r in ShotResult.values) {
              final MatchWorld w = MatchWorld();
              w.play(kick(r));
              final double total = w.script!.timeline.total;
              for (double t = 0; t < total; t += total / 12) {
                w.update(total / 12);
                await rasterize(w, pal, s.w, s.h);
              }
            }
          });
        });
      }
    }

    testWidgets('an opponent kick paints and an idle scene paints', (WidgetTester tester) async {
      await tester.runAsync(() async {
        final MatchWorld w = MatchWorld()..idleShooter = MatchSide.opponent;
        await rasterize(w, AppPalette.light, 360, 800);
        w.play(kick(ShotResult.saved, side: MatchSide.opponent));
        w.update(0.2);
        await rasterize(w, AppPalette.light, 360, 800);
      });
    });
  });

  group('pixels', () {
    testWidgets('sky, stand, grass, post and ball are where the projection says', (WidgetTester tester) async {
      await tester.runAsync(() async {
        const AppPalette pal = AppPalette.light;
        final MatchWorld w = MatchWorld()..ballMarks = 1;
        final ({ByteData data, int width}) img = await rasterize(w, pal, 360, 800);
        final PitchProjection p = PitchProjection.fit(360, 800);

        expect(pixel(img, 180, 4), pal.bgPrimary.toARGB32());

        final ScreenPoint standLow = p.project(0, 0.3, -Tuning.groundBehindGoal)!;
        final ScreenRect g = p.goalRect;
        expect(standLow.y, lessThan(g.bottom));
        expect(pixel(img, 8, standLow.y.round() - 4), pal.bgTertiary.toARGB32());

        final int grass = pixel(img, 180, 790);
        expect(<int>[pal.pitchGrass.toARGB32(), pal.pitchGrassAlt.toARGB32()], contains(grass));

        final double postW = Tuning.postThickness * p.k;
        final int postX = (g.left + postW / 2).round();
        final int postY = ((g.top + g.bottom) / 2).round();
        expect(pixel(img, postX, postY), pal.pitchLine.toARGB32());

        final ScreenPoint ball = p.project(0, Tuning.ballRadius, Tuning.spotDistance)!;
        expect(pixel(img, ball.x.round(), ball.y.round()), pal.ballInk.toARGB32());
        final int right = (ball.x + ball.scale * Tuning.ballRadius * 0.7).round();
        expect(pixel(img, right, ball.y.round()), pal.pitchLine.toARGB32());
      });
    });

    testWidgets('the ball is drawn higher on screen in flight than on the spot', (WidgetTester tester) async {
      await tester.runAsync(() async {
        const AppPalette pal = AppPalette.dark;
        final MatchWorld w = MatchWorld();
        w.play(kick(ShotResult.goal));
        w.update(0.1);
        final PitchProjection p = PitchProjection.fit(360, 800);
        final ScreenPoint onSpot = p.project(0, Tuning.ballRadius, Tuning.spotDistance)!;
        final MatchWorld flying = MatchWorld();
        flying.play(kick(ShotResult.goal));
        for (int i = 0; i < 60 && flying.ballPosition.z == Tuning.spotDistance; i++) {
          flying.update(1 / 60);
        }
        flying.update(0.2);
        final WorldPoint b = flying.ballPosition;
        final ScreenPoint inFlight = p.project(b.x, b.y, b.z)!;
        expect(inFlight.y, lessThan(onSpot.y));
        expect(inFlight.scale, lessThan(onSpot.scale));
        await rasterize(flying, pal, 360, 800, only: <SceneLayer>[Pitch(), Ball(flying)]);
      });
    });
  });

  group('TehillahGame', () {
    testWidgets('loads, lays out, plays a kick and reports it finished', (WidgetTester tester) async {
      final TehillahGame game = TehillahGame(palette: AppPalette.light);
      int finished = 0;
      game.scene.onKickFinished = () => finished++;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 360, height: 800, child: GameWidget<TehillahGame>(game: game)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(game.hasLayout, isTrue);
      expect(game.projection.width, 360);
      expect(game.projection.height, 800);

      game.scene.play(kick(ShotResult.goal));
      for (int i = 0; i < 300 && finished == 0; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(finished, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('palette and Reduce Motion can be changed while running', (WidgetTester tester) async {
      final TehillahGame game = TehillahGame(palette: AppPalette.light);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 360, height: 800, child: GameWidget<TehillahGame>(game: game)),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(game.backgroundColor(), AppPalette.light.bgPrimary);
      game.palette = AppPalette.dark;
      expect(game.backgroundColor(), AppPalette.dark.bgPrimary);
      expect(game.reduceMotion, isFalse);
      game.reduceMotion = true;
      expect(game.scene.reduceMotion, isTrue);
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
    });

    testWidgets('the projection follows a resize', (WidgetTester tester) async {
      final TehillahGame game = TehillahGame(palette: AppPalette.light);
      Widget host(double w, double h) => Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: w, height: h, child: GameWidget<TehillahGame>(game: game)),
            ),
          );
      await tester.pumpWidget(host(360, 800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final double portraitK = game.projection.k;
      await tester.pumpWidget(host(800, 360));
      await tester.pump(const Duration(milliseconds: 50));
      expect(game.projection.width, 800);
      expect(game.projection.k, isNot(portraitK));
    });
  });
}
