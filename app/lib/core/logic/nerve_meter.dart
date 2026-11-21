import 'package:tehillah/core/logic/modifiers.dart';
import 'package:tehillah/core/models/gear_def.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/match_state.dart';

/// The shooter's nerve: pressure raises it, a goal eases it, a miss shakes it,
/// and a Selah pause steadies it. High nerve widens the aim error in the shot
/// resolver. It is a skill resource, not luck.
abstract final class NerveMeter {
  static const double _basePressure = 0.03;
  static const double _suddenDeathPressure = 0.10;
  static const double _trailingPressure = 0.05;
  static const double _bossPressure = 0.04;
  static const double _goalRelief = 0.04;
  static const double _missShake = 0.03;
  static const double _selahRelief = 0.35;

  static double _clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

  /// The nerve after the player's kick. [before] is the match state before the
  /// kick, so that "trailing" and "sudden death" describe the moment the kick
  /// was taken.
  static double afterKick({
    required MatchState before,
    required Modifiers mods,
    required bool wasGoal,
    required bool isBoss,
  }) {
    double pressure = _basePressure;
    if (before.isSuddenDeath) {
      pressure += _suddenDeathPressure;
    }
    if (before.scoreOf(MatchSide.player) < before.scoreOf(MatchSide.opponent)) {
      pressure += _trailingPressure;
    }
    if (isBoss) {
      pressure += _bossPressure;
    }
    final double gain = pressure * (1 + mods.nerveGain);
    final double change = gain + (wasGoal ? -_goalRelief : _missShake);
    return _clamp01(before.nerve + change);
  }

  /// The nerve after a Selah pause.
  static double afterSelah(double nerve, Modifiers mods) {
    final double relief =
        _selahRelief * (1 + mods.nerveRecovery) * (1 + 0.5 * mods.selahDuration);
    return _clamp01(nerve - (relief < 0 ? 0 : relief));
  }

  /// Selah pauses left after one is used. The Helmet of Salvation never lets
  /// the last pause run out.
  static int chargesAfterSelah(int charges, Modifiers mods) {
    final int left = charges - 1;
    if (mods.special == GearSpecial.selahFloor && left < 1) {
      return 1;
    }
    return left < 0 ? 0 : left;
  }
}
