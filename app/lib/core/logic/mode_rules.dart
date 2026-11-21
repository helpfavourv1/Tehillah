import 'package:tehillah/core/catalog/stage_catalog.dart';
import 'package:tehillah/core/logic/date_key.dart';
import 'package:tehillah/core/logic/modifiers.dart';
import 'package:tehillah/core/logic/seeded_rng.dart';
import 'package:tehillah/core/models/daily_challenge.dart';
import 'package:tehillah/core/models/loadout.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/opponent_def.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/models/shot_params.dart';
import 'package:tehillah/core/models/stage_def.dart';

/// How each mode is built from the one match core, and when it unlocks.
abstract final class ModeRules {
  /// The Journey stage that must be cleared (its lamp earned) before a mode
  /// opens. Null for modes with no stage condition.
  static int? unlockStage(MatchMode mode) {
    switch (mode) {
      case MatchMode.friendly:
        return 1;
      case MatchMode.watchman:
        return 3;
      case MatchMode.jericho:
        return 5;
      case MatchMode.slingAndStone:
        return 6;
      case MatchMode.journey:
      case MatchMode.sevenDays:
      case MatchMode.dailyBread:
        return null;
    }
  }

  /// Whether the player can open a mode. Seven Days opens after the first
  /// Daily Bread.
  static bool isUnlocked(MatchMode mode, Progress progress) {
    if (mode == MatchMode.sevenDays) {
      return progress.dailyHistory.isNotEmpty;
    }
    final int? stage = unlockStage(mode);
    return stage == null || progress.lamps.contains(stage);
  }

  /// Difficulty implied by an opponent's keeper, 0 to 1. The stage catalog
  /// builds keepers as reaction = 0.30 + 0.60 * strength.
  static double difficultyOf(OpponentDef opponent) {
    final double d = (opponent.keeper.reaction - 0.30) / 0.60;
    return d < 0 ? 0 : (d > 1 ? 1 : d);
  }

  static MatchConfig journey({
    required StageDef stage,
    required int round,
    required Loadout loadout,
    required int seed,
  }) {
    if (round < 1 || round > stage.opponents.length) {
      throw RangeError.range(round, 1, stage.opponents.length, 'round');
    }
    return MatchConfig(
      mode: MatchMode.journey,
      opponent: stage.opponents[round - 1],
      loadout: loadout,
      seed: seed,
      difficulty: stage.difficulty,
      stageId: stage.id,
      round: round,
      wind: stage.wind,
    );
  }

  static MatchConfig friendly({
    required OpponentDef opponent,
    required Loadout loadout,
    required int seed,
  }) {
    return MatchConfig(
      mode: MatchMode.friendly,
      opponent: opponent,
      loadout: loadout,
      seed: seed,
      difficulty: difficultyOf(opponent),
    );
  }

  /// Watchman: the player keeps goal and the opponent kicks first.
  static MatchConfig watchman({
    required OpponentDef opponent,
    required Loadout loadout,
    required int seed,
  }) {
    return MatchConfig(
      mode: MatchMode.watchman,
      opponent: opponent,
      loadout: loadout,
      seed: seed,
      difficulty: difficultyOf(opponent),
    );
  }

  /// Jericho has seven rounds against one opponent, each harder than the last.
  static const int jerichoRounds = 7;

  static MatchConfig jericho({
    required OpponentDef opponent,
    required int round,
    required Loadout loadout,
    required int seed,
  }) {
    if (round < 1 || round > jerichoRounds) {
      throw RangeError.range(round, 1, jerichoRounds, 'round');
    }
    final double raw = difficultyOf(opponent) + 0.06 * (round - 1);
    return MatchConfig(
      mode: MatchMode.jericho,
      opponent: opponent,
      loadout: loadout,
      seed: seed,
      difficulty: raw > 1 ? 1 : raw,
      round: round,
    );
  }

  /// The seven days of the week-long challenge: kicks per side, a difficulty
  /// change and wind for each day.
  static const List<({int kicks, double difficultyShift, double wind})>
      sevenDaysThemes = <({int kicks, double difficultyShift, double wind})>[
    (kicks: 5, difficultyShift: 0.00, wind: 0),
    (kicks: 3, difficultyShift: 0.05, wind: 0),
    (kicks: 5, difficultyShift: 0.05, wind: 0.30),
    (kicks: 7, difficultyShift: 0.05, wind: 0),
    (kicks: 5, difficultyShift: 0.10, wind: -0.30),
    (kicks: 3, difficultyShift: 0.15, wind: 0.20),
    (kicks: 5, difficultyShift: 0.20, wind: 0),
  ];

  static const int sevenDaysLength = 7;

  /// Which day (1 to 7) of the challenge [todayKey] is, counting from
  /// [startKey]. Null before the start or after the seventh day.
  static int? sevenDaysDay(String startKey, String todayKey) {
    final int n = DateKey.daysBetween(startKey, todayKey);
    return n < 0 || n >= sevenDaysLength ? null : n + 1;
  }

  static MatchConfig sevenDays({
    required int day,
    required OpponentDef opponent,
    required Loadout loadout,
    required int seed,
  }) {
    if (day < 1 || day > sevenDaysLength) {
      throw RangeError.range(day, 1, sevenDaysLength, 'day');
    }
    final ({int kicks, double difficultyShift, double wind}) theme =
        sevenDaysThemes[day - 1];
    final double raw = difficultyOf(opponent) + theme.difficultyShift;
    return MatchConfig(
      mode: MatchMode.sevenDays,
      opponent: opponent,
      loadout: loadout,
      seed: seed,
      difficulty: raw > 1 ? 1 : raw,
      round: day,
      kicksPerSide: theme.kicks,
      wind: theme.wind,
    );
  }

  /// Daily Bread is the same for everyone, so it always uses the starter
  /// loadout.
  static MatchConfig daily(DailyChallenge challenge) {
    return MatchConfig(
      mode: MatchMode.dailyBread,
      opponent: challenge.opponent,
      loadout: Loadout.starter,
      seed: challenge.seed,
      difficulty: challenge.difficulty,
      kicksPerSide: challenge.kicksPerSide,
      wind: challenge.wind,
    );
  }

  /// The opponents of the whole Journey, in order.
  static List<OpponentDef> allOpponents() => <OpponentDef>[
        for (final StageDef s in StageCatalog.stages) ...s.opponents,
      ];
}

/// One target in Sling and Stone: a disc on the goal face that slides
/// sideways. Coordinates are the same as a shot's: x from -1 to 1 across the
/// goal and y from 0 (ground) to 1 (crossbar).
final class SlingTarget {
  const SlingTarget({
    required this.centerX,
    required this.y,
    required this.radius,
    required this.amplitude,
    required this.speed,
    required this.phase,
  });

  final double centerX;
  final double y;
  final double radius;

  /// How far the disc slides either side of [centerX].
  final double amplitude;

  /// Slide cycles per second (a full back-and-forth is two units of the wave).
  final double speed;

  /// Starting point in the wave, 0 to 2.
  final double phase;

  /// Where the disc is [seconds] after the round starts.
  double xAt(double seconds) {
    final double t = seconds * speed + phase;
    final double p = t - (t / 2).floor() * 2.0;
    final double wave = p <= 1 ? p : 2 - p;
    return centerX + amplitude * (wave * 2 - 1);
  }
}

/// Sling and Stone: a limited number of stones thrown at moving targets. There
/// is no keeper. Stones use the same shot parameters as a kick.
abstract final class SlingAndStone {
  static const int stones = 7;
  static const int targets = 5;

  /// The targets for a round, from a seed.
  static List<SlingTarget> targetsFor(int seed) {
    final SeededRng rng = SeededRng(seed).fork('sling');
    return <SlingTarget>[
      for (int i = 0; i < targets; i++)
        SlingTarget(
          centerX: (rng.nextDouble() - 0.5) * 1.2,
          y: 0.2 + 0.6 * rng.nextDouble(),
          radius: 0.16 - 0.015 * i,
          amplitude: 0.15 + 0.25 * rng.nextDouble(),
          speed: 0.25 + 0.05 * i,
          phase: rng.nextDouble() * 2,
        ),
    ];
  }

  /// Whether a stone thrown [seconds] after the round started hits [target].
  /// The throw bends and wobbles like a kick, but with a fixed small wobble so
  /// the game rewards aim, not luck. Aim forgiveness from the ball widens the
  /// disc.
  static bool hits({
    required ShotParams shot,
    required SlingTarget target,
    required double seconds,
    required Modifiers mods,
  }) {
    final double landingX = shot.direction + shot.curve * 0.30 * (1 + mods.curveRange);
    final double forgiveness = mods.aimForgiveness < 0 ? 0 : mods.aimForgiveness;
    final double reach = target.radius * (1 + forgiveness);
    final double dx = landingX - target.xAt(seconds);
    final double dy = shot.elevation - target.y;
    return dx * dx + dy * dy <= reach * reach;
  }

  /// Stars for a round from the number of targets hit.
  static int stars(int hit) {
    if (hit >= 5) {
      return 3;
    }
    if (hit >= 4) {
      return 2;
    }
    return hit >= 3 ? 1 : 0;
  }
}
