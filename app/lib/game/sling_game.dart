import 'package:flame/components.dart';
import 'package:tehillah/game/components/goal.dart';
import 'package:tehillah/game/components/pitch.dart';
import 'package:tehillah/game/components/sling_layers.dart';
import 'package:tehillah/game/scene_game.dart';
import 'package:tehillah/game/sling_world.dart';

/// The Sling and Stone scene: the pitch and goal frame as a wall, with moving
/// targets and the stone. Aim and HUD are ordinary Flutter widgets above it.
class SlingGame extends SceneGame {
  SlingGame({required super.palette});

  /// What is happening in the round.
  final SlingWorld scene = SlingWorld();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await addAll(<Component>[
      scene,
      Pitch(),
      SlingBackdrop(),
      SlingTargets(scene),
      GoalFrame(),
      SlingStone(scene),
    ]);
  }
}
