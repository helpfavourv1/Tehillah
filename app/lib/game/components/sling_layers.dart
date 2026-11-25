import 'dart:math' as math;
import 'dart:ui';

import 'package:tehillah/game/components/scene_layer.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/game/geometry/shot_trajectory.dart';
import 'package:tehillah/game/sling_world.dart';
import 'package:tehillah/game/tuning.dart';
import 'package:tehillah/theme/tokens.dart';

/// The wall the targets hang on: a panel filling the goal mouth, so discs read
/// clearly against it.
class SlingBackdrop extends SceneLayer {
  SlingBackdrop() : super(priority: 10);

  @override
  void paintScene(Canvas canvas, PitchProjection p, AppPalette c) {
    final ScreenRect g = p.goalRect;
    canvas.drawRect(
      Rect.fromLTRB(g.left, g.top, g.right, g.bottom),
      Paint()..color = c.bgSecondary,
    );
  }
}

/// The targets. A live target is a filled disc with two rings; a target that
/// has been hit stays where it was struck as a hollow ring with a tick. The
/// state is told apart by shape, not by colour.
class SlingTargets extends SceneLayer {
  SlingTargets(this.scene) : super(priority: 20);

  final SlingWorld scene;

  @override
  void paintScene(Canvas canvas, PitchProjection p, AppPalette c) {
    final Set<int> fallen = scene.fallen;
    for (int i = 0; i < scene.targets.length; i++) {
      final GoalPoint at = scene.targetPoint(i);
      final ScreenPoint? s = p.project(at.x, at.y, 0);
      if (s == null) {
        continue;
      }
      final double r = scene.targets[i].radius;
      final double rx = math.max(r * Tuning.halfGoal * s.scale, 3);
      final double ry = math.max(r * Tuning.goalHeight * s.scale, 3);
      final Offset centre = Offset(s.x, s.y);
      if (fallen.contains(i)) {
        _hit(canvas, centre, rx, ry, c, math.max(1.5, ry * 0.12));
      } else {
        _live(canvas, centre, rx, ry, c);
      }
    }
  }

  static Rect _oval(Offset centre, double rx, double ry) =>
      Rect.fromCenter(centre: centre, width: rx * 2, height: ry * 2);

  void _live(Canvas canvas, Offset centre, double rx, double ry, AppPalette c) {
    canvas.drawOval(_oval(centre, rx, ry), Paint()..color = c.accent);
    final Paint ring = Paint()
      ..color = c.onAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, ry * 0.1);
    canvas.drawOval(_oval(centre, rx * 0.66, ry * 0.66), ring);
    canvas.drawOval(_oval(centre, rx * 0.3, ry * 0.3), Paint()..color = c.onAccent);
  }

  void _hit(Canvas canvas, Offset centre, double rx, double ry, AppPalette c, double stroke) {
    final Paint line = Paint()
      ..color = c.success
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawOval(_oval(centre, rx, ry), line);
    final Path tick = Path()
      ..moveTo(centre.dx - rx * 0.4, centre.dy + ry * 0.02)
      ..lineTo(centre.dx - rx * 0.08, centre.dy + ry * 0.36)
      ..lineTo(centre.dx + rx * 0.45, centre.dy - ry * 0.34);
    canvas.drawPath(tick, line);
  }
}

/// The stone: waiting at the sling, or flying to where it was aimed.
class SlingStone extends SceneLayer {
  SlingStone(this.scene) : super(priority: 30);

  final SlingWorld scene;

  @override
  void paintScene(Canvas canvas, PitchProjection p, AppPalette c) {
    final WorldPoint? flying = scene.stonePosition;
    final WorldPoint? at = flying ??
        (scene.stoneReady
            ? (x: 0.0, y: SlingTuning.stoneRestY, z: Tuning.spotDistance)
            : null);
    if (at == null) {
      return;
    }
    final ScreenPoint? s = p.project(at.x, at.y, at.z);
    if (s == null) {
      return;
    }
    final ScreenPoint? ground = p.project(at.x, 0, at.z);
    final double r = math.max(SlingTuning.stoneRadius * s.scale, 4);
    if (ground != null) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ground.x, ground.y),
          width: r * 2.2,
          height: r * 0.7,
        ),
        Paint()..color = c.scrim,
      );
    }
    final Offset centre = Offset(s.x, s.y);
    canvas.drawCircle(centre, r, Paint()..color = c.pitchLine);
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..color = c.ballInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, r * 0.14),
    );
  }
}
