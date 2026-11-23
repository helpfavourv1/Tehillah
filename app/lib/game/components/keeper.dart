import 'dart:ui';

import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/game/components/figure.dart';
import 'package:tehillah/game/components/scene_layer.dart';
import 'package:tehillah/game/geometry/keeper_motion.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/game/match_world.dart';
import 'package:tehillah/game/tuning.dart';
import 'package:tehillah/theme/tokens.dart';

/// The kit colour a side wears: the player's side in the accent, the opponent
/// in the quiet secondary text colour, so the two are told apart by more than
/// position.
Color kitFor(MatchSide side, AppPalette c) =>
    side == MatchSide.player ? c.accent : c.textSecondary;

/// The goalkeeper. Wears the colour of the side that is not kicking.
class Keeper extends SceneLayer {
  Keeper(this.scene) : super(priority: 20);

  final MatchWorld scene;

  @override
  void paintScene(Canvas canvas, PitchProjection p, AppPalette c) {
    final KeeperPose pose = scene.keeperPose;
    final ScreenPoint? s = p.project(pose.x, pose.y, Tuning.keeperZ);
    if (s == null) {
      return;
    }
    final ScreenPoint? ground = p.project(pose.x, 0, Tuning.keeperZ);
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
      hip: Offset(s.x, s.y),
      scale: s.scale,
      style: FigureStyle(
        kit: kitFor(scene.shooterSide.other, c),
        limb: c.textPrimary,
        glove: c.pitchLine,
      ),
      pose: FigurePose(arms: pose.stretch, spread: pose.stretch, tilt: pose.tilt),
    );
  }
}
