import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:tehillah/core/logic/mode_rules.dart';
import 'package:tehillah/core/logic/sling_rules.dart';
import 'package:tehillah/core/models/shot_params.dart';
import 'package:tehillah/game/geometry/shot_trajectory.dart';
import 'package:tehillah/game/tuning.dart';

/// A stone on its way to the goal plane.
final class StoneFlight {
  StoneFlight({required this.thrown, required this.target});

  final SlingThrow thrown;

  /// Where it will land, in metres on the goal plane.
  final GoalPoint target;

  double elapsed = 0;

  ShotParams get shot => thrown.shot;

  /// Progress, 0 at the sling and 1 at the goal plane.
  double get progress => (elapsed / SlingTuning.stoneFlightSeconds).clamp(0, 1).toDouble();
}

/// The Sling and Stone scene's state: the round clock, where each target is,
/// and the stone in flight. Components only read from here. The rules have
/// already decided whether a stone hits by the time [launch] is called; this
/// only shows it, with the clock and the targets agreeing with that decision
/// because the controller asks the rules about the moment of impact.
class SlingWorld extends Component {
  /// Called once when a stone reaches the goal plane.
  void Function(SlingThrow thrown)? onStoneLanded;

  List<SlingTarget> _targets = const <SlingTarget>[];
  final Map<int, double> _fallenAt = <int, double>{};
  StoneFlight? _flight;
  double _seconds = 0;

  /// The clock and the stone only move while this is true.
  bool running = false;

  /// Whether the stone waits at the sling, ready to throw.
  bool stoneReady = false;

  List<SlingTarget> get targets => _targets;

  /// Seconds since the round began, paused while [running] is false.
  double get seconds => _seconds;

  StoneFlight? get flight => _flight;

  /// Indexes of targets that have been hit and have landed on screen.
  Set<int> get fallen => _fallenAt.keys.toSet();

  /// Begins a round with [targets]; the clock starts at zero, stopped.
  void load(List<SlingTarget> targets) {
    _targets = List<SlingTarget>.unmodifiable(targets);
    _fallenAt.clear();
    _flight = null;
    _seconds = 0;
    running = false;
    stoneReady = false;
  }

  /// Puts everything away without calling [onStoneLanded].
  void clear() => load(const <SlingTarget>[]);

  /// Where target [i] is now, in the rules' units (-1 to 1 across).
  double targetX(int i) => _fallenAt[i] ?? _targets[i].xAt(_seconds);

  /// Where target [i] is, on the goal plane, in metres.
  GoalPoint targetPoint(int i) => (
        x: targetX(i) * Tuning.halfGoal,
        y: _targets[i].y * Tuning.goalHeight,
      );

  /// Shows [thrown] flying to where it was aimed.
  void launch(SlingThrow thrown) {
    _flight = StoneFlight(
      thrown: thrown,
      target: (
        x: thrown.shot.direction * Tuning.halfGoal,
        y: thrown.shot.elevation * Tuning.goalHeight,
      ),
    );
    stoneReady = false;
  }

  /// The stone's place in the world, or null when none is in flight.
  WorldPoint? get stonePosition {
    final StoneFlight? f = _flight;
    if (f == null) {
      return null;
    }
    final WorldPoint p = ShotTrajectory.flightAt(
      ShotParams(
        direction: f.shot.direction,
        elevation: f.shot.elevation,
        power: 1,
        curve: 0,
      ),
      f.target,
      f.progress,
    );
    final double u = f.progress;
    final double extra = SlingTuning.stoneArc * 4 * u * (1 - u);
    return (x: p.x, y: p.y + extra, z: p.z);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!running) {
      return;
    }
    final double step = math.min(math.max(dt, 0), 0.1);
    _seconds += step;
    final StoneFlight? f = _flight;
    if (f == null) {
      return;
    }
    f.elapsed += step;
    if (f.elapsed >= SlingTuning.stoneFlightSeconds) {
      _flight = null;
      final int? hit = f.thrown.hitIndex;
      if (hit != null && hit >= 0 && hit < _targets.length) {
        _fallenAt[hit] = _targets[hit].xAt(f.thrown.seconds);
      }
      onStoneLanded?.call(f.thrown);
    }
  }
}
