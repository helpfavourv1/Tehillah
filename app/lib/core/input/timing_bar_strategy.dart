import 'dart:async';

import 'package:tehillah/core/input/shot_input_strategy.dart';
import 'package:tehillah/core/models/shot_params.dart';

/// Where the timing-bar scheme is.
enum TimingPhase {
  /// Waiting for the player to tap a target zone.
  aiming,

  /// A zone is chosen and the bar is moving; the player taps to stop it.
  running,
}

/// Aim and timing bar: tap one of six zones on the goal, then stop a moving
/// bar. The bar's position is the power. Stopping near the top skies the ball;
/// stopping too low loses accuracy and pulls the ball toward the middle.
final class TimingBarStrategy implements ShotInputStrategy {
  /// [speedFactor] scales the bar; the Patience ball slows it (below 1).
  TimingBarStrategy({this.speedFactor = 1.0, this.secondsPerSweep = 1.1})
      : assert(speedFactor > 0),
        assert(secondsPerSweep > 0);

  /// Columns, left to right, as goal positions.
  static const List<double> columnDirections = <double>[-0.8, 0, 0.8];

  /// Rows, low then high, as heights.
  static const List<double> rowElevations = <double>[0.2, 0.75];

  /// The bar position that gives a clean strike.
  static const double sweetSpot = 0.78;

  /// Above this position the strike starts to rise over the bar.
  static const double skyThreshold = 0.9;

  final double speedFactor;

  /// Time for the bar to travel from one end to the other at factor 1.
  final double secondsPerSweep;

  final StreamController<ShotParams> _controller =
      StreamController<ShotParams>.broadcast(sync: true);
  TimingPhase _phase = TimingPhase.aiming;
  int _column = 1;
  int _row = 0;
  double _position = 0;

  @override
  Stream<ShotParams> get shots => _controller.stream;

  TimingPhase get phase => _phase;

  /// The bar position, 0 to 1.
  double get position => _position;

  int get column => _column;
  int get row => _row;

  /// Chooses the zone and starts the bar.
  void selectZone(int column, int row) {
    if (column < 0 || column >= columnDirections.length) {
      throw RangeError.range(column, 0, columnDirections.length - 1, 'column');
    }
    if (row < 0 || row >= rowElevations.length) {
      throw RangeError.range(row, 0, rowElevations.length - 1, 'row');
    }
    _column = column;
    _row = row;
    _position = 0;
    _phase = TimingPhase.running;
  }

  /// Moves the bar to where it is [elapsedMs] after the zone was chosen. The
  /// bar sweeps up, then down, then up again.
  void tick(int elapsedMs) {
    if (_phase != TimingPhase.running) {
      return;
    }
    final double t = elapsedMs / (secondsPerSweep * 1000 / speedFactor);
    final double p = t - (t / 2).floor() * 2.0;
    _position = p <= 1 ? p : 2 - p;
  }

  /// Stops the bar and sends the shot. Returns null if no zone was chosen.
  ShotParams? stop() {
    if (_phase != TimingPhase.running) {
      return null;
    }
    final double power = _position;
    double elevation = rowElevations[_row];
    if (power > skyThreshold) {
      elevation += (power - skyThreshold) * 2;
    }
    final double accuracy = power >= sweetSpot ? 1 : 0.6 + 0.4 * (power / sweetSpot);
    final ShotParams shot = ShotParams(
      direction: columnDirections[_column] * accuracy,
      elevation: elevation > 1 ? 1 : elevation,
      power: power,
      curve: 0,
    );
    _phase = TimingPhase.aiming;
    _position = 0;
    _controller.add(shot);
    return shot;
  }

  /// Back to choosing a zone, without a shot.
  void reset() {
    _phase = TimingPhase.aiming;
    _position = 0;
  }

  @override
  void dispose() {
    _controller.close();
  }
}
