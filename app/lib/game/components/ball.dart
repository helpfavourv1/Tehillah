import 'dart:math' as math;
import 'dart:ui';

import 'package:tehillah/game/components/figure.dart';
import 'package:tehillah/game/components/scene_layer.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/game/geometry/shot_trajectory.dart';
import 'package:tehillah/game/match_world.dart';
import 'package:tehillah/game/tuning.dart';
import 'package:tehillah/theme/tokens.dart';

/// The ball. Its marks are a count of dots (one to nine, one for each fruit),
/// so each ball is told apart by shape and not by colour. In front of the goal
/// it is drawn above the frame; once it is behind the line it goes under the
/// frame and the keeper so it sits inside the net.
class Ball extends SceneLayer {
  Ball(this.scene) : super(priority: front);

  static const int front = 30;
  static const int behind = 14;

  final MatchWorld scene;

  @override
  void update(double dt) {
    super.update(dt);
    final int want = scene.ballBehindGoalLine ? behind : front;
    if (priority != want) {
      priority = want;
    }
  }

  @override
  void paintScene(Canvas canvas, PitchProjection p, AppPalette c) {
    final WorldPoint b = scene.ballPosition;
    final ScreenPoint? s = p.project(b.x, b.y, b.z);
    if (s == null) {
      return;
    }
    final ScreenPoint? ground = p.project(b.x, 0, b.z);
    if (ground != null && b.z >= 0) {
      FigurePainter.shadow(
        canvas,
        ground: Offset(ground.x, ground.y),
        width: Tuning.ballRadius * 2.4 * ground.scale,
        color: c.scrim,
      );
    }
    final double r = math.max(Tuning.ballRadius * s.scale, 3);
    final Offset centre = Offset(s.x, s.y);
    canvas.drawCircle(centre, r, Paint()..color = c.pitchLine);
    final Paint ink = Paint()..color = c.ballInk;
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..color = c.ballInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, r * 0.12),
    );
    if (r >= 5) {
      final int n = scene.ballMarks.clamp(1, 9);
      final double spin = scene.ballSpin;
      if (n == 1) {
        canvas.drawCircle(centre, r * 0.22, ink);
      } else {
        for (int i = 0; i < n; i++) {
          final double a = spin + 2 * math.pi * i / n;
          canvas.drawCircle(
            centre + Offset(math.cos(a), math.sin(a)) * (r * 0.58),
            r * 0.14,
            ink,
          );
        }
      }
    }
  }
}
