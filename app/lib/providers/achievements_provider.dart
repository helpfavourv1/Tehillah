import 'package:flutter/foundation.dart';
import 'package:tehillah/providers/progress_provider.dart';
import 'package:tehillah/providers/safe_notifier.dart';

@immutable
final class AchievementsState {
  const AchievementsState({this.unlocked = const <String>{}, this.pending = const <String>[]});

  /// Every achievement the player holds.
  final Set<String> unlocked;

  /// Achievements reached since the player last saw them, oldest first. The
  /// UI shows each once and calls [AchievementsProvider.acknowledge].
  final List<String> pending;

  @override
  bool operator ==(Object other) =>
      other is AchievementsState &&
      setEquals(other.unlocked, unlocked) &&
      listEquals(other.pending, pending);

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(unlocked), Object.hashAll(pending));
}

/// Unlocked fruit achievements and the "newly unlocked" queue. The set lives
/// in the career file; this only watches it. Achievements already held when
/// the career loads are never announced.
final class AchievementsProvider extends SafeNotifier<AchievementsState> {
  AchievementsProvider(this._progress) : super(const AchievementsState()) {
    _progress.addListener(_sync);
    _sync();
  }

  final ProgressProvider _progress;
  bool _baselined = false;

  void _sync() {
    if (!_progress.value.loaded) {
      return;
    }
    final Set<String> now = _progress.progress.achievements;
    if (!_baselined) {
      _baselined = true;
      value = AchievementsState(unlocked: now);
      return;
    }
    final List<String> added = <String>[
      for (final String id in now)
        if (!value.unlocked.contains(id)) id,
    ]..sort();
    if (added.isEmpty && setEquals(now, value.unlocked)) {
      return;
    }
    value = AchievementsState(
      unlocked: now,
      pending: <String>[...value.pending, ...added],
    );
  }

  /// Removes one achievement from the queue after the player has seen it.
  void acknowledge(String id) {
    if (!value.pending.contains(id)) {
      return;
    }
    value = AchievementsState(
      unlocked: value.unlocked,
      pending: <String>[
        for (final String p in value.pending)
          if (p != id) p,
      ],
    );
  }

  @override
  void dispose() {
    _progress.removeListener(_sync);
    super.dispose();
  }
}
