import 'dart:math' as math;

import 'package:tehillah/game/tuning.dart';

/// A point on screen with the size one metre has there.
typedef ScreenPoint = ({double x, double y, double scale});

/// The corners of a rectangle on screen.
typedef ScreenRect = ({double left, double top, double right, double bottom});

/// The perspective that turns world metres into screen pixels.
///
/// World axes: `x` across the pitch (right is positive, as the shooter sees
/// it), `y` up from the grass, `z` along the pitch measured from the goal line
/// towards the shooter. The camera stands behind the shooter on the centre
/// line. The goal is placed first, then the scale is the largest that keeps the
/// goal inside its width share, keeps its top clear of the edge and keeps the
/// shooter's feet on screen. That makes one function serve portrait and
/// landscape, and the input layers ask the same function so touch zones match
/// what is drawn.
final class PitchProjection {
  PitchProjection._({
    required this.width,
    required this.height,
    required this.k,
    required this.horizon,
  });

  /// Fits the scene to a canvas of [width] by [height] pixels.
  factory PitchProjection.fit(double width, double height) {
    final double w = math.max(width, 1);
    final double h = math.max(height, 1);
    final bool portrait = h >= w;
    final double goalBase =
        h * (portrait ? Tuning.goalBaseFracPortrait : Tuning.goalBaseFracLandscape);
    final double shooterDepth = Tuning.cameraZ - Tuning.runUpStartZ;
    final double byWidth = w * Tuning.goalWidthFrac / Tuning.goalWidth;
    final double byTop = (goalBase - h * Tuning.topMarginFrac) / Tuning.goalHeight;
    final double byFeet = (h * Tuning.feetMaxFrac - goalBase) /
        (Tuning.cameraHeight * (Tuning.cameraZ / shooterDepth - 1));
    final double k = math.max(math.min(byWidth, math.min(byTop, byFeet)), 1);
    return PitchProjection._(
      width: w,
      height: h,
      k: k,
      horizon: goalBase - Tuning.cameraHeight * k,
    );
  }

  final double width;
  final double height;

  /// Pixels per metre at the goal line.
  final double k;

  /// The screen row of the horizon.
  final double horizon;

  double get centerX => width / 2;

  /// Pixels per metre at depth [z] (the distance from the goal line), or null
  /// when that point is too close to, or behind, the camera.
  double? scaleAt(double z) {
    final double depth = Tuning.cameraZ - z;
    if (depth < Tuning.nearPlane) {
      return null;
    }
    return k * Tuning.cameraZ / depth;
  }

  /// Where the world point ([x], [y], [z]) lands on screen, or null when it is
  /// not in front of the camera.
  ScreenPoint? project(double x, double y, double z) {
    final double? s = scaleAt(z);
    if (s == null) {
      return null;
    }
    return (
      x: centerX + x * s,
      y: horizon + (Tuning.cameraHeight - y) * s,
      scale: s,
    );
  }

  /// Like [project] but never null: points behind the near plane are pushed to
  /// the near plane. For shapes that must stay closed.
  ScreenPoint projectClamped(double x, double y, double z) {
    final double zc = math.min(z, Tuning.cameraZ - Tuning.nearPlane);
    return project(x, y, zc)!;
  }

  /// The goal mouth on screen (posts and crossbar, outer edges).
  ScreenRect get goalRect {
    final ScreenPoint a = project(-Tuning.halfGoal, Tuning.goalHeight, 0)!;
    final ScreenPoint b = project(Tuning.halfGoal, 0, 0)!;
    return (left: a.x, top: a.y, right: b.x, bottom: b.y);
  }

  /// The goal-plane point (metres) under screen pixel ([sx], [sy]); the inverse
  /// of [project] at the goal line. Used to turn touches into aim.
  ({double x, double y}) goalPlaneAt(double sx, double sy) {
    return (
      x: (sx - centerX) / k,
      y: Tuning.cameraHeight - (sy - horizon) / k,
    );
  }

  /// The screen rectangle of one zone of a grid laid over the goal mouth,
  /// [columns] across and [rows] down (row 0 is the bottom row).
  ScreenRect zoneRect(int column, int row, {required int columns, required int rows}) {
    assert(column >= 0 && column < columns && row >= 0 && row < rows);
    final ScreenRect g = goalRect;
    final double zw = (g.right - g.left) / columns;
    final double zh = (g.bottom - g.top) / rows;
    final int fromTop = rows - 1 - row;
    return (
      left: g.left + zw * column,
      top: g.top + zh * fromTop,
      right: g.left + zw * (column + 1),
      bottom: g.top + zh * (fromTop + 1),
    );
  }
}
