import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:tehillah/game/components/ball.dart';
import 'package:tehillah/game/components/effects.dart';
import 'package:tehillah/game/components/goal.dart';
import 'package:tehillah/game/components/keeper.dart';
import 'package:tehillah/game/components/pitch.dart';
import 'package:tehillah/game/components/shooter.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/game/match_world.dart';
import 'package:tehillah/theme/tokens.dart';

/// The match scene. It owns the [MatchWorld] (what is happening) and the
/// layers that draw it, and hands every layer the current perspective and
/// palette. The HUD, menus and verse cards around it are ordinary Flutter
/// widgets, so text in every language and direction stays correct.
class TehillahGame extends FlameGame {
  TehillahGame({required AppPalette palette, bool reduceMotion = false})
      : _palette = palette {
    scene.reduceMotion = reduceMotion;
  }

  /// What is happening on the pitch.
  final MatchWorld scene = MatchWorld();

  AppPalette _palette;
  PitchProjection? _projection;

  AppPalette get palette => _palette;

  /// Takes effect on the next frame.
  set palette(AppPalette value) {
    _palette = value;
  }

  bool get reduceMotion => scene.reduceMotion;

  set reduceMotion(bool value) {
    scene.reduceMotion = value;
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

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await addAll(<Component>[
      scene,
      Pitch(),
      GoalNet(scene),
      Keeper(scene),
      GoalFrame(),
      Shooter(scene),
      Ball(scene),
      Effects(scene),
    ]);
  }
}
