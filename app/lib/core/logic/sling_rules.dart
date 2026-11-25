import 'package:tehillah/core/logic/modifiers.dart';
import 'package:tehillah/core/logic/mode_rules.dart';
import 'package:tehillah/core/logic/reward_rules.dart';
import 'package:tehillah/core/models/shot_params.dart';

/// One thrown stone: what was thrown, when, and which target it hit (if any).
final class SlingThrow {
  const SlingThrow({required this.shot, required this.seconds, this.hitIndex});

  final ShotParams shot;
  final double seconds;

  /// Index into [SlingState.targets], or null for a miss.
  final int? hitIndex;

  bool get isHit => hitIndex != null;
}

/// The state of one Sling and Stone round. Immutable.
final class SlingState {
  const SlingState({
    required this.targets,
    required this.stonesLeft,
    this.hit = const <int>{},
    this.thrown = 0,
    this.bonusApplied = false,
    this.last,
  });

  final List<SlingTarget> targets;
  final int stonesLeft;
  final Set<int> hit;
  final int thrown;
  final bool bonusApplied;
  final SlingThrow? last;

  int get hits => hit.length;
  bool get allHit => hit.length >= targets.length;
  bool get finished => stonesLeft <= 0 || allHit;
  int get stars => SlingAndStone.stars(hits);

  /// A rewarded ad may add stones once, when the round ended with targets left.
  bool get canOfferExtraStones => finished && !allHit && !bonusApplied;

  SlingState copyWith({
    int? stonesLeft,
    Set<int>? hit,
    int? thrown,
    bool? bonusApplied,
    SlingThrow? last,
  }) {
    return SlingState(
      targets: targets,
      stonesLeft: stonesLeft ?? this.stonesLeft,
      hit: hit ?? this.hit,
      thrown: thrown ?? this.thrown,
      bonusApplied: bonusApplied ?? this.bonusApplied,
      last: last ?? this.last,
    );
  }
}

/// Pure round logic for Sling and Stone.
abstract final class SlingRules {
  /// A fresh round from a seed.
  static SlingState start(int seed) => SlingState(
        targets: SlingAndStone.targetsFor(seed),
        stonesLeft: SlingAndStone.stones,
      );

  /// Throws one stone [seconds] after the round began. When a stone covers
  /// several targets, the smallest (highest index) target not yet hit takes it.
  static SlingState throwStone(
    SlingState state, {
    required ShotParams shot,
    required double seconds,
    Modifiers mods = Modifiers.none,
  }) {
    if (state.finished) {
      throw StateError('The round is finished.');
    }
    if (seconds < 0) {
      throw ArgumentError.value(seconds, 'seconds', 'must not be negative');
    }
    int? index;
    for (int i = state.targets.length - 1; i >= 0; i--) {
      if (state.hit.contains(i)) {
        continue;
      }
      if (SlingAndStone.hits(shot: shot, target: state.targets[i], seconds: seconds, mods: mods)) {
        index = i;
        break;
      }
    }
    return state.copyWith(
      stonesLeft: state.stonesLeft - 1,
      thrown: state.thrown + 1,
      hit: index == null ? state.hit : <int>{...state.hit, index},
      last: SlingThrow(shot: shot, seconds: seconds, hitIndex: index),
    );
  }

  /// Adds the rewarded stones. Only once, only when [SlingState.canOfferExtraStones].
  static SlingState addExtraStones(SlingState state) {
    if (!state.canOfferExtraStones) {
      return state;
    }
    return state.copyWith(stonesLeft: RewardRules.extraStones, bonusApplied: true);
  }
}
