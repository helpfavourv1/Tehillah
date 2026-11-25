import 'dart:ui';

import 'package:flame/components.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/game/scene_game.dart';
import 'package:tehillah/theme/tokens.dart';

/// A drawing layer of the match scene. It does nothing until the game has a
/// size, then asks the game for the current perspective and colours and calls
/// [paintScene]. [paintScene] takes everything it needs as arguments, so a
/// layer can also be painted onto any canvas in a test.
abstract class SceneLayer extends Component with HasGameReference<SceneGame> {
  SceneLayer({super.priority});

  @override
  void render(Canvas canvas) {
    final SceneGame g = game;
    if (!g.hasLayout) {
      return;
    }
    paintScene(canvas, g.projection, g.palette);
  }

  void paintScene(Canvas canvas, PitchProjection p, AppPalette c);
}
