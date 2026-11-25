import 'dart:ui';

import 'package:flame/game.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/theme/tokens.dart';

/// What every scene shares: the palette and the perspective for the current
/// canvas size. Scene layers ask this, so one layer can serve any scene.
abstract class SceneGame extends FlameGame {
  SceneGame({required AppPalette palette}) : _palette = palette;

  AppPalette _palette;
  PitchProjection? _projection;

  AppPalette get palette => _palette;

  /// Takes effect on the next frame.
  set palette(AppPalette value) {
    _palette = value;
  }

  /// The perspective for the current canvas size.
  PitchProjection get projection {
    final PitchProjection? cached = _projection;
    final double w = size.x;
    final double h = size.y;
    if (cached != null && cached.width == w && cached.height == h) {
      return cached;
    }
    final PitchProjection fresh = PitchProjection.fit(w, h);
    _projection = fresh;
    return fresh;
  }

  @override
  Color backgroundColor() => _palette.bgPrimary;
}
