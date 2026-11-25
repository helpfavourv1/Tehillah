import 'package:flame/components.dart';
import 'package:tehillah/game/components/ball.dart';
import 'package:tehillah/game/components/effects.dart';
import 'package:tehillah/game/components/goal.dart';
import 'package:tehillah/game/components/keeper.dart';
import 'package:tehillah/game/components/pitch.dart';
import 'package:tehillah/game/components/shooter.dart';
import 'package:tehillah/game/match_world.dart';
import 'package:tehillah/game/scene_game.dart';

/// The match scene. It owns the [MatchWorld] (what is happening) and the
/// layers that draw it, and hands every layer the current perspective and
/// palette. The HUD, menus and verse cards around it are ordinary Flutter
/// widgets, so text in every language and direction stays correct.
class TehillahGame extends SceneGame {
  TehillahGame({required super.palette, bool reduceMotion = false}) {
    scene.reduceMotion = reduceMotion;
  }

  /// What is happening on the pitch.
  final MatchWorld scene = MatchWorld();

  bool get reduceMotion => scene.reduceMotion;

  set reduceMotion(bool value) {
    scene.reduceMotion = value;
  }

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
