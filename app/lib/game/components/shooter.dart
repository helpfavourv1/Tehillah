import 'dart:ui';

import 'package:tehillah/game/components/figure.dart';
import 'package:tehillah/game/components/keeper.dart';
import 'package:tehillah/game/components/scene_layer.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/game/match_world.dart';
import 'package:tehillah/game/tuning.dart';
import 'package:tehillah/theme/tokens.dart';

/// The player taking the kick, seen from behind: waiting, running up, striking.
class Shooter extends SceneLayer {
  Shooter(this.scene) : super(priority: 27);

  final MatchWorld scene;

  @override
  void paintScene(Canvas canvas, PitchProjection p, AppPalette c) {
    final ShooterState st = scene.shooter;
    final ScreenPoint? hip = p.project(st.x, FigureShape.hipHeight, st.z);
    if (hip == null) {
      return;
    }
    final ScreenPoint? ground = p.project(st.x, 0, st.z);
    if (ground != null) {
      FigurePainter.shadow(
        canvas,
        ground: Offset(ground.x, ground.y),
        width: 0.9 * ground.scale,
        color: c.scrim,
      );
    }
    FigurePainter.paint(
      canvas,
      hip: Offset(hip.x, hip.y),
      scale: hip.scale,
      style: FigureStyle(kit: kitFor(scene.shooterSide, c), limb: c.textPrimary),
      pose: FigurePose(swing: st.swing),
    );
  }
}
