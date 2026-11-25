import 'package:flutter/foundation.dart';
import 'package:tehillah/core/logic/modifiers.dart';
import 'package:tehillah/core/logic/sling_rules.dart';
import 'package:tehillah/core/models/shot_params.dart';
import 'package:tehillah/game/sling_world.dart';
import 'package:tehillah/game/tuning.dart';

/// The glue between the round's rules ([SlingRules]), the picture
/// ([SlingWorld]) and the player's aim.
///
/// A release is decided by the rules at once, asked about the moment the stone
/// will arrive, so the picture shows exactly that. [state] is published when
/// the stone lands, so the numbers on screen never run ahead of the stone.
/// Input is closed while a stone flies, when the round is over and while
/// paused. [onFinished] fires after the last stone lands, and again if a
/// rewarded ad adds stones and the round ends once more.
class SlingController {
  SlingController({required this.world, this.mods = Modifiers.none}) {
    world.onStoneLanded = _landed;
  }

  final SlingWorld world;

  /// Gear and ball effects; they widen the targets.
  Modifiers mods;

  /// Called each time the round ends, after the last stone has landed.
  void Function()? onFinished;

  /// The round as the player sees it (null before [start]).
  final ValueNotifier<SlingState?> state = ValueNotifier<SlingState?>(null);

  /// True when the player may throw right now.
  final ValueNotifier<bool> inputEnabled = ValueNotifier<bool>(false);

  SlingState? _truth;
  bool _paused = false;
  bool _disposed = false;

  bool get isPaused => _paused;
  bool get isFlying => world.flight != null;

  /// Begins a round from [seed].
  void start(int seed) {
    if (_disposed) {
      return;
    }
    final SlingState fresh = SlingRules.start(seed);
    _truth = fresh;
    world.load(fresh.targets);
    state.value = fresh;
    _paused = false;
    world.running = true;
    _refresh();
  }

  /// Throws a stone at [direction] (-1 to 1) and [elevation] (0 to 1) on the
  /// goal. False when no throw is possible right now.
  bool release({required double direction, required double elevation}) {
    final SlingState? truth = _truth;
    if (_disposed || truth == null || _paused || isFlying || truth.finished) {
      return false;
    }
    final ShotParams shot = ShotParams(
      direction: direction.clamp(-1.0, 1.0).toDouble(),
      elevation: elevation.clamp(0.0, 1.0).toDouble(),
      power: 1,
      curve: 0,
    );
    final SlingState next = SlingRules.throwStone(
      truth,
      shot: shot,
      seconds: world.seconds + SlingTuning.stoneFlightSeconds,
      mods: mods,
    );
    _truth = next;
    world.launch(next.last!);
    _refresh();
    return true;
  }

  /// Whether a rewarded ad may be offered for extra stones right now.
  bool get canOfferExtraStones {
    final SlingState? truth = _truth;
    return !_disposed && truth != null && !isFlying && truth.canOfferExtraStones;
  }

  /// Adds the rewarded stones and reopens the round. False when not allowed.
  bool addExtraStones() {
    if (!canOfferExtraStones) {
      return false;
    }
    final SlingState next = SlingRules.addExtraStones(_truth!);
    _truth = next;
    state.value = next;
    world.running = !_paused;
    _refresh();
    return true;
  }

  void pause() {
    if (_paused) {
      return;
    }
    _paused = true;
    world.running = false;
    _refresh();
  }

  void resume() {
    if (!_paused) {
      return;
    }
    _paused = false;
    final SlingState? truth = _truth;
    world.running = truth != null && (!truth.finished || isFlying);
    _refresh();
  }

  void _landed(SlingThrow thrown) {
    final SlingState? truth = _truth;
    if (_disposed || truth == null) {
      return;
    }
    state.value = truth;
    if (truth.finished) {
      world.running = false;
      _refresh();
      onFinished?.call();
      return;
    }
    _refresh();
  }

  void _refresh() {
    final SlingState? truth = _truth;
    final bool open = !_disposed && truth != null && !_paused && !isFlying && !truth.finished;
    inputEnabled.value = open;
    world.stoneReady = open;
  }

  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (world.onStoneLanded == _landed) {
      world.onStoneLanded = null;
    }
    state.dispose();
    inputEnabled.dispose();
  }
}
