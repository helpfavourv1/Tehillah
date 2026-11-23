import 'package:tehillah/game/tuning.dart';

/// The stages of one kick on screen.
enum KickPhase { runUp, strike, flight, reaction, settle, done }

/// When each stage of one kick starts, for a ball with the given flight time.
/// Time zero is the start of the run-up. With Reduce Motion the run-up is
/// skipped so the kick is struck at once; the flight is gameplay and stays.
final class KickTimeline {
  KickTimeline({required this.flightSeconds, this.reduceMotion = false})
      : assert(flightSeconds > 0);

  final double flightSeconds;
  final bool reduceMotion;

  double get runUp => reduceMotion ? 0 : Tuning.runUpSeconds;
  double get strikeAt => runUp;
  double get flightStart => strikeAt + Tuning.strikeSeconds;
  double get contactAt => flightStart + flightSeconds;
  double get reactionEnd => contactAt + Tuning.reactionSeconds;
  double get total => reactionEnd + Tuning.settleSeconds;

  KickPhase phaseAt(double t) {
    if (t < strikeAt) {
      return KickPhase.runUp;
    }
    if (t < flightStart) {
      return KickPhase.strike;
    }
    if (t < contactAt) {
      return KickPhase.flight;
    }
    if (t < reactionEnd) {
      return KickPhase.reaction;
    }
    if (t < total) {
      return KickPhase.settle;
    }
    return KickPhase.done;
  }

  /// Progress of the run-up, 0 to 1.
  double runUpProgress(double t) =>
      runUp == 0 ? 1 : (t / runUp).clamp(0, 1).toDouble();

  /// Progress of the ball's flight, 0 before the strike and 1 at the goal.
  double flightProgress(double t) =>
      ((t - flightStart) / flightSeconds).clamp(0, 1).toDouble();

  /// Seconds since the ball reached the goal plane (0 before).
  double sinceContact(double t) => t < contactAt ? 0 : t - contactAt;

  /// Seconds since the keeper left the line; the keeper goes with the strike.
  double keeperSeconds(double t) => t < flightStart ? 0 : t - flightStart;

  bool isDone(double t) => t >= total;
}
