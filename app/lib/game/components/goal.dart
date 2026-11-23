import 'dart:math' as math;
import 'dart:ui';

import 'package:tehillah/game/components/scene_layer.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/game/geometry/shot_trajectory.dart';
import 'package:tehillah/game/match_world.dart';
import 'package:tehillah/game/tuning.dart';
import 'package:tehillah/theme/tokens.dart';

/// The net behind the goal line: a mesh on the back panel, with its sides and
/// roof. It shakes after a goal (not under Reduce Motion).
class GoalNet extends SceneLayer {
  GoalNet(this.scene) : super(priority: 12);

  final MatchWorld scene;

  static const int _columns = 12;
  static const int _rows = 6;
  static const double _inset = 0.2;
  static const double _roofDrop = 0.3;

  @override
  void paintScene(Canvas canvas, PitchProjection p, AppPalette c) {
    const double backHalf = Tuning.halfGoal - _inset;
    const double backTop = Tuning.goalHeight - _roofDrop;
    const double z = -Tuning.netDepth;
    final Paint mesh = Paint()
      ..color = c.pitchLine.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke;

    final double ripple = scene.netRipple;
    final GoalPoint? hit = scene.contact;
    final double phase = scene.sinceContact * 28;

    Offset at(double x, double y, double zz) {
      final ScreenPoint s = p.projectClamped(x, y, zz);
      double dy = 0;
      if (ripple > 0 && hit != null) {
        final double dist = math.sqrt(math.pow(x - hit.x, 2) + math.pow(y - hit.y, 2));
        final double falloff = math.max(1 - dist / 2.5, 0);
        dy = -math.sin(phase) * ripple * falloff * 0.3 * s.scale;
      }
      return Offset(s.x, s.y + dy);
    }

    final double meshWidth = math.max(0.75, 0.015 * p.k);
    mesh.strokeWidth = meshWidth;
    for (int i = 0; i <= _columns; i++) {
      final double x = -backHalf + 2 * backHalf * i / _columns;
      canvas.drawLine(at(x, 0, z), at(x, backTop, z), mesh);
      canvas.drawLine(at(x * Tuning.halfGoal / backHalf, Tuning.goalHeight, 0), at(x, backTop, z), mesh);
    }
    for (int j = 0; j <= _rows; j++) {
      final double y = backTop * j / _rows;
      canvas.drawLine(at(-backHalf, y, z), at(backHalf, y, z), mesh);
    }
    for (final double side in <double>[-1, 1]) {
      canvas.drawLine(at(side * Tuning.halfGoal, 0, 0), at(side * backHalf, 0, z), mesh);
      canvas.drawLine(
        at(side * Tuning.halfGoal, Tuning.goalHeight, 0),
        at(side * backHalf, backTop, z),
        mesh,
      );
    }

    final Paint support = Paint()
      ..color = c.postWood
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, 0.04 * p.k);
    for (final double side in <double>[-1, 1]) {
      canvas.drawLine(at(side * backHalf, 0, z), at(side * backHalf, backTop, z), support);
    }
  }
}

/// The posts and crossbar, drawn in front of the keeper.
class GoalFrame extends SceneLayer {
  GoalFrame() : super(priority: 25);

  @override
  void paintScene(Canvas canvas, PitchProjection p, AppPalette c) {
    final ScreenRect g = p.goalRect;
    final double w = math.max(2, Tuning.postThickness * p.k);
    final Paint paint = Paint()
      ..color = c.pitchLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.square;
    final double half = w / 2;
    final Path frame = Path()
      ..moveTo(g.left + half, g.bottom)
      ..lineTo(g.left + half, g.top + half)
      ..lineTo(g.right - half, g.top + half)
      ..lineTo(g.right - half, g.bottom);
    canvas.drawPath(frame, paint);
  }
}
