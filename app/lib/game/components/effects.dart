import 'dart:math' as math;
import 'dart:ui';

import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/game/components/scene_layer.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/game/geometry/shot_trajectory.dart';
import 'package:tehillah/game/match_world.dart';
import 'package:tehillah/game/tuning.dart';
import 'package:tehillah/theme/tokens.dart';

/// The moment of contact. Each result has its own shape, never colour alone:
/// a goal bursts into dots, a post flashes a ring, a save flashes a cross.
/// Misses have no effect. Nothing is drawn under Reduce Motion.
class Effects extends SceneLayer {
  Effects(this.scene) : super(priority: 40);

  final MatchWorld scene;

  @override
  void paintScene(Canvas canvas, PitchProjection p, AppPalette c) {
    final KickScript? s = scene.script;
    final GoalPoint? hit = scene.contact;
    if (s == null || hit == null || scene.reduceMotion) {
      return;
    }
    final double since = scene.sinceContact;
    switch (s.result) {
      case ShotResult.goal:
        _burst(canvas, p, c, hit, since);
      case ShotResult.post:
        _ring(canvas, p, c, hit, since);
      case ShotResult.saved:
        _cross(canvas, p, c, hit, since);
      case ShotResult.wide:
      case ShotResult.high:
        break;
    }
  }

  void _burst(Canvas canvas, PitchProjection p, AppPalette c, GoalPoint hit, double since) {
    final double u = since / Tuning.burstSeconds;
    if (u >= 1) {
      return;
    }
    final double e = 1 - (1 - u) * (1 - u);
    for (int i = 0; i < Tuning.burstParticles; i++) {
      final double a = 2 * math.pi * i / Tuning.burstParticles;
      final double reach = (0.4 + 1.6 * e) * (i.isEven ? 1 : 0.65);
      final ScreenPoint? s = p.project(hit.x + math.cos(a) * reach, hit.y + math.sin(a) * reach, 0);
      if (s == null) {
        continue;
      }
      final Color base = i.isEven ? c.accent : c.starFill;
      canvas.drawCircle(
        Offset(s.x, s.y),
        math.max(2, (0.09 - 0.04 * u) * s.scale),
        Paint()..color = base.withValues(alpha: 1 - u),
      );
    }
  }

  void _ring(Canvas canvas, PitchProjection p, AppPalette c, GoalPoint hit, double since) {
    final double u = since / Tuning.postFlashSeconds;
    if (u >= 1) {
      return;
    }
    final ScreenPoint? s = p.project(hit.x, hit.y, 0);
    if (s == null) {
      return;
    }
    canvas.drawCircle(
      Offset(s.x, s.y),
      (0.15 + 0.45 * u) * s.scale,
      Paint()
        ..color = c.pitchLine.withValues(alpha: 1 - u)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, 0.05 * s.scale),
    );
  }

  void _cross(Canvas canvas, PitchProjection p, AppPalette c, GoalPoint hit, double since) {
    final double u = since / Tuning.postFlashSeconds;
    if (u >= 1) {
      return;
    }
    final ScreenPoint? s = p.project(hit.x, hit.y, 0);
    if (s == null) {
      return;
    }
    final double arm = (0.2 + 0.3 * u) * s.scale;
    final Paint paint = Paint()
      ..color = c.pitchLine.withValues(alpha: 1 - u)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(1.5, 0.05 * s.scale);
    canvas.drawLine(Offset(s.x - arm, s.y), Offset(s.x + arm, s.y), paint);
    canvas.drawLine(Offset(s.x, s.y - arm), Offset(s.x, s.y + arm), paint);
  }
}
