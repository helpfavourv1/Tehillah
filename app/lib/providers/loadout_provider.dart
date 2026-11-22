import 'package:flutter/foundation.dart';
import 'package:tehillah/core/catalog/ball_catalog.dart';
import 'package:tehillah/core/catalog/gear_catalog.dart';
import 'package:tehillah/core/logic/progression_rules.dart';
import 'package:tehillah/core/models/loadout.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/providers/progress_provider.dart';
import 'package:tehillah/providers/safe_notifier.dart';

/// The chosen loadout and which balls and gear the player may choose from.
@immutable
final class LoadoutState {
  const LoadoutState({
    required this.selected,
    required this.unlockedBalls,
    required this.unlockedGear,
  });

  /// The loadout to play with. A saved choice that is not unlocked is replaced
  /// here, so a match never starts with something the player does not have.
  final Loadout selected;
  final Set<String> unlockedBalls;
  final Set<String> unlockedGear;

  bool ballUnlocked(String id) => unlockedBalls.contains(id);
  bool gearUnlocked(String id) => unlockedGear.contains(id);

  @override
  bool operator ==(Object other) =>
      other is LoadoutState &&
      other.selected == selected &&
      setEquals(other.unlockedBalls, unlockedBalls) &&
      setEquals(other.unlockedGear, unlockedGear);

  @override
  int get hashCode =>
      Object.hash(selected, Object.hashAllUnordered(unlockedBalls), Object.hashAllUnordered(unlockedGear));
}

/// Ball and gear selection. Unlocks come from lamps in [ProgressProvider];
/// the choice is saved with the career.
final class LoadoutProvider extends SafeNotifier<LoadoutState> {
  LoadoutProvider(this._progress) : super(_derive(_progress.progress)) {
    _progress.addListener(_sync);
  }

  final ProgressProvider _progress;

  static LoadoutState _derive(Progress p) {
    final Set<String> unlocks = ProgressionRules.unlocksFor(p);
    final Set<String> balls = <String>{
      for (final b in BallCatalog.all)
        if (unlocks.contains('ball:${b.id}')) b.id,
    };
    final Set<String> gear = <String>{
      for (final g in GearCatalog.all)
        if (unlocks.contains('gear:${g.id}')) g.id,
    };
    final Loadout saved = p.loadout;
    final Loadout selected = Loadout(
      ballId: balls.contains(saved.ballId) ? saved.ballId : Loadout.starter.ballId,
      gearId: saved.gearId != null && gear.contains(saved.gearId) ? saved.gearId : null,
    );
    return LoadoutState(selected: selected, unlockedBalls: balls, unlockedGear: gear);
  }

  void _sync() => value = _derive(_progress.progress);

  /// Chooses a ball. Returns false if it is not unlocked.
  bool selectBall(String id) {
    if (!value.ballUnlocked(id)) {
      return false;
    }
    return _progress.update((Progress p) => p.copyWith(loadout: value.selected.copyWith(ballId: id)));
  }

  /// Chooses a piece of gear, or none when [id] is null. Returns false if it
  /// is not unlocked.
  bool selectGear(String? id) {
    if (id == null) {
      return _progress.update((Progress p) => p.copyWith(loadout: value.selected.copyWith(clearGear: true)));
    }
    if (!value.gearUnlocked(id)) {
      return false;
    }
    return _progress.update((Progress p) => p.copyWith(loadout: value.selected.copyWith(gearId: id)));
  }

  @override
  void dispose() {
    _progress.removeListener(_sync);
    super.dispose();
  }
}
