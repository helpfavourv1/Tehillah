/// The one tuning file for the match world. Every physical size, timing and
/// camera value lives here; no component carries its own number. Lengths are in
/// metres, times in seconds.
abstract final class Tuning {
  // ---- Pitch and goal (real proportions) ---------------------------------

  static const double goalWidth = 7.32;
  static const double goalHeight = 2.44;
  static const double halfGoal = goalWidth / 2;
  static const double postThickness = 0.12;

  /// Depth of the net behind the goal line.
  static const double netDepth = 1.8;

  /// Distance of the penalty spot from the goal line.
  static const double spotDistance = 11;
  static const double sixYardDepth = 5.5;
  static const double sixYardHalfWidth = 9.16;
  static const double penaltyAreaDepth = 16.5;
  static const double penaltyAreaHalfWidth = 20.16;
  static const double spotRadius = 0.15;

  /// How far the grass runs behind the goal line before the stand.
  static const double groundBehindGoal = 8;
  static const double standHeight = 4;

  /// Width of one mowing stripe along the pitch.
  static const double stripeDepth = 5.5;

  /// How far to either side the grass is drawn.
  static const double groundHalfWidth = 40;

  // ---- Camera: behind the shooter, looking at the goal --------------------

  static const double cameraZ = 16;
  static const double cameraHeight = 2;

  /// Anything closer than this to the camera is not drawn.
  static const double nearPlane = 0.8;

  /// Where the goal's foot sits on screen, as a fraction of the height.
  static const double goalBaseFracPortrait = 0.30;
  static const double goalBaseFracLandscape = 0.28;

  /// The widest the goal may be, as a fraction of the screen width.
  static const double goalWidthFrac = 0.62;

  /// The goal's top keeps at least this fraction of the height above it.
  static const double topMarginFrac = 0.08;

  /// The shooter's feet stay above this fraction of the height.
  static const double feetMaxFrac = 0.93;

  // ---- Shooter -------------------------------------------------------------

  static const double runUpStartZ = 13;
  static const double strikeZ = 11.7;

  /// The shooter stands to the left of the ball so the goal stays in view.
  static const double shooterX = -0.9;
  static const double shooterHeight = 1.8;
  static const double runUpSeconds = 0.55;
  static const double strikeSeconds = 0.14;

  // ---- Ball ----------------------------------------------------------------

  static const double ballRadius = 0.11;

  /// Flight time from the spot to the goal line at full and at no power.
  static const double fastFlightSeconds = 0.45;
  static const double slowFlightSeconds = 1.0;

  /// Sideways bulge of a fully curved shot, in metres.
  static const double curveBulge = 1.4;

  /// Height of the arc of a flat shot and the extra for a full lift.
  static const double arcBase = 0.2;
  static const double arcLift = 0.9;

  /// Gravity used after contact (half of g, in m/s squared, tuned for show).
  static const double fallHalfG = 4;

  // ---- Keeper --------------------------------------------------------------

  static const double keeperHeight = 1.9;
  static const double keeperRestY = 0.95;
  static const double keeperDiveSeconds = 0.4;
  static const double keeperReachX = 2.6;
  static const double keeperLowY = 0.7;
  static const double keeperHighY = 1.75;
  static const double keeperMaxTilt = 1.2;

  /// Where the keeper stands in front of the goal line.
  static const double keeperZ = 0.4;

  // ---- After contact -------------------------------------------------------

  static const double reactionSeconds = 1.0;
  static const double settleSeconds = 0.5;

  // ---- Effects (all skipped under Reduce Motion) ---------------------------

  static const double netRippleSeconds = 0.6;
  static const double burstSeconds = 0.7;
  static const double postFlashSeconds = 0.35;
  static const int burstParticles = 14;
}

/// The abstract figure the players are drawn with, in metres from the hip.
abstract final class FigureShape {
  static const double legLength = 0.95;
  static const double legSpread = 0.13;
  static const double legWidth = 0.15;
  static const double torsoWidth = 0.46;
  static const double torsoHeight = 0.72;
  static const double torsoCentreY = 0.38;
  static const double torsoRadius = 0.14;
  static const double shoulderX = 0.24;
  static const double shoulderY = 0.62;
  static const double armWidth = 0.12;
  static const double headY = 0.88;
  static const double headRadius = 0.13;
  static const double gloveRadius = 0.09;
  static const double hipHeight = 0.95;
}

/// Sling and Stone. Targets live on the goal plane in the rules' units (-1 to
/// 1 across, 0 to 1 up), so a disc of radius `r` is drawn as an ellipse that is
/// `r * halfGoal` wide and `r * goalHeight` tall, exactly the region that
/// counts as a hit.
abstract final class SlingTuning {
  /// Time from release to the stone reaching the goal plane.
  static const double stoneFlightSeconds = 0.3;

  /// Size of the stone, in metres.
  static const double stoneRadius = 0.14;

  /// Height of the stone's arc above a straight line.
  static const double stoneArc = 0.5;

  /// Where the stone waits before a throw.
  static const double stoneRestY = 0.2;
}
