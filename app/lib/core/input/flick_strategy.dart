import 'dart:async';
import 'dart:math' as math;

import 'package:tehillah/core/input/shot_input_strategy.dart';
import 'package:tehillah/core/models/shot_params.dart';

/// Tuning for the flick gesture. Distances are logical pixels, times are
/// milliseconds. The defaults suit a 720 x 1640 phone and are adjusted from
/// test-build feedback.
final class FlickConfig {
  const FlickConfig({
    this.minLength = 40,
    this.maxDurationMs = 900,
    this.maxAimTangent = 0.8,
    this.minSpeed = 0.4,
    this.maxSpeed = 3.0,
    this.shortestLoft = 60,
    this.longestLoft = 420,
    this.fullCurveBulge = 0.25,
    this.minUpwardShare = 0.3,
  });

  /// Swipes shorter than this are taps and are ignored.
  final double minLength;

  /// Swipes slower than this are ignored.
  final int maxDurationMs;

  /// The sideways-to-forward ratio that aims at the post (1.0 on the scale).
  final double maxAimTangent;

  /// Speed (pixels per millisecond) that gives zero power.
  final double minSpeed;

  /// Speed that gives full power.
  final double maxSpeed;

  /// Swipe length that gives a ground shot, and the length that gives the
  /// highest lift.
  final double shortestLoft;
  final double longestLoft;

  /// How far the path bows away from a straight line, as a share of the swipe
  /// length, for full curve.
  final double fullCurveBulge;

  /// The least share of the swipe that must point up the screen. A sideways
  /// swipe is not a kick.
  final double minUpwardShare;
}

/// Turns a swipe from the ball toward the goal into a shot.
///
/// - Aim: the angle of the swipe. Straight up is the middle of the goal.
/// - Power: how fast the swipe is.
/// - Lift: how long the swipe is.
/// - Curve: how the path bows. A path that bows to the right curls right.
///
/// Call [begin], [update] with each pointer move and [end] on release. [end]
/// returns the shot, or null if the gesture was not a kick, and also sends it
/// on [shots].
final class FlickStrategy implements ShotInputStrategy {
  FlickStrategy({this.config = const FlickConfig()});

  final FlickConfig config;
  final StreamController<ShotParams> _controller =
      StreamController<ShotParams>.broadcast(sync: true);
  final List<({double x, double y})> _points = <({double x, double y})>[];
  double _startX = 0;
  double _startY = 0;
  int _startMs = 0;
  bool _active = false;

  @override
  Stream<ShotParams> get shots => _controller.stream;

  bool get isActive => _active;

  void begin(double x, double y, int timeMs) {
    _active = true;
    _startX = x;
    _startY = y;
    _startMs = timeMs;
    _points
      ..clear()
      ..add((x: x, y: y));
  }

  void update(double x, double y, int timeMs) {
    if (_active) {
      _points.add((x: x, y: y));
    }
  }

  /// Abandons the gesture without a shot.
  void cancel() {
    _active = false;
    _points.clear();
  }

  ShotParams? end(double x, double y, int timeMs) {
    if (!_active) {
      return null;
    }
    _active = false;
    _points.add((x: x, y: y));
    final ShotParams? shot = _classify(x, y, timeMs);
    _points.clear();
    if (shot != null) {
      _controller.add(shot);
    }
    return shot;
  }

  static double _clamp(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);

  ShotParams? _classify(double endX, double endY, int endMs) {
    final double dx = endX - _startX;
    final double dy = endY - _startY;
    final double length = math.sqrt(dx * dx + dy * dy);
    final int duration = endMs - _startMs;
    if (length < config.minLength ||
        duration <= 0 ||
        duration > config.maxDurationMs) {
      return null;
    }
    final double upward = -dy;
    if (upward <= 0 || upward / length < config.minUpwardShare) {
      return null;
    }

    final double direction =
        _clamp((dx / upward) / config.maxAimTangent, -1, 1);
    final double speed = length / duration;
    final double power = _clamp(
      (speed - config.minSpeed) / (config.maxSpeed - config.minSpeed),
      0,
      1,
    );
    final double elevation = _clamp(
      (length - config.shortestLoft) / (config.longestLoft - config.shortestLoft),
      0,
      1,
    );

    double bulge = 0;
    for (final ({double x, double y}) p in _points) {
      final double cross = (dx * (p.y - _startY) - dy * (p.x - _startX)) / length;
      if (cross.abs() > bulge.abs()) {
        bulge = cross;
      }
    }
    final double curve =
        _clamp((bulge / length) / config.fullCurveBulge, -1, 1);

    return ShotParams(
      direction: direction,
      elevation: elevation,
      power: power,
      curve: curve,
    );
  }

  @override
  void dispose() {
    _controller.close();
  }
}
