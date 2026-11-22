import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tehillah/core/errors/app_error.dart';
import 'package:tehillah/core/logic/achievements_engine.dart';
import 'package:tehillah/core/logic/progression_rules.dart';
import 'package:tehillah/core/models/daily_challenge.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/core/storage/progress_store.dart';
import 'package:tehillah/providers/safe_notifier.dart';

/// The saved career plus what the UI needs to say about how it was loaded and
/// whether saving works.
@immutable
final class ProgressState {
  const ProgressState({
    required this.progress,
    required this.loadStatus,
    this.loaded = false,
    this.saveFailed = false,
    this.readOnly = false,
    this.noticeDismissed = false,
  });

  final Progress progress;
  final ProgressLoadStatus loadStatus;

  /// False until the first [ProgressProvider.load] has finished.
  final bool loaded;

  /// The last write failed; the career is safe in memory and the next change
  /// writes again.
  final bool saveFailed;

  /// Writing is switched off to protect a file this build cannot replace.
  final bool readOnly;

  final bool noticeDismissed;

  /// A one-time message about damaged or newer data is waiting to be shown.
  bool get needsNotice =>
      loaded &&
      !noticeDismissed &&
      (loadStatus == ProgressLoadStatus.recoveredFromBackup ||
          loadStatus == ProgressLoadStatus.startedClean ||
          loadStatus == ProgressLoadStatus.newerVersionReadOnly ||
          loadStatus == ProgressLoadStatus.storageUnavailable);

  /// Whether the persistent warning banner is shown: progress is not being
  /// saved right now.
  bool get savingBroken => loaded && (saveFailed || readOnly);

  ProgressState copyWith({
    Progress? progress,
    ProgressLoadStatus? loadStatus,
    bool? loaded,
    bool? saveFailed,
    bool? readOnly,
    bool? noticeDismissed,
  }) {
    return ProgressState(
      progress: progress ?? this.progress,
      loadStatus: loadStatus ?? this.loadStatus,
      loaded: loaded ?? this.loaded,
      saveFailed: saveFailed ?? this.saveFailed,
      readOnly: readOnly ?? this.readOnly,
      noticeDismissed: noticeDismissed ?? this.noticeDismissed,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProgressState &&
      identical(other.progress, progress) &&
      other.loadStatus == loadStatus &&
      other.loaded == loaded &&
      other.saveFailed == saveFailed &&
      other.readOnly == readOnly &&
      other.noticeDismissed == noticeDismissed;

  @override
  int get hashCode => Object.hash(
        identityHashCode(progress),
        loadStatus,
        loaded,
        saveFailed,
        readOnly,
        noticeDismissed,
      );
}

/// What a finished match changed, for the result screen.
final class MatchRecorded {
  const MatchRecorded({
    required this.stars,
    required this.newAchievements,
    required this.newUnlocks,
    required this.newLamps,
  });

  final int stars;

  /// Achievement ids reached by this match, in catalog order.
  final List<String> newAchievements;

  /// Balls, gear and modes this match opened (`ball:joy`, `mode:watchman`).
  final Set<String> newUnlocks;

  /// Stage lamps this match earned.
  final Set<int> newLamps;
}

/// Owns the career. Every change is applied in memory first and then written
/// through [ProgressStore]; writes never overlap and the newest value always
/// wins. A failed write never loses the change.
final class ProgressProvider extends SafeNotifier<ProgressState> {
  ProgressProvider(this._store, this._log)
      : super(ProgressState(
          progress: Progress.empty(),
          loadStatus: ProgressLoadStatus.fresh,
        ));

  final ProgressStore _store;
  final LogPort _log;

  bool _writing = false;
  bool _dirty = false;
  bool _sessionCounted = false;
  Completer<void>? _idle;

  Progress get progress => value.progress;

  /// Unlocks the player has earned and not yet been told about. The starting
  /// set is never announced.
  Set<String> get newUnlocks => ProgressionRules.unlocksFor(progress)
      .difference(ProgressionRules.unlocksFor(Progress.empty()))
      .difference(progress.announcedUnlocks);

  /// Loads the career, recovering from damage as [ProgressStore] decides.
  Future<void> load() async {
    final ProgressLoad result = await _store.load();
    value = ProgressState(
      progress: result.progress,
      loadStatus: result.status,
      loaded: true,
      readOnly: _store.readOnly,
    );
  }

  /// Counts this app launch once. Interstitials never show in the first
  /// session, so this number matters.
  void beginSession() {
    if (_sessionCounted) {
      return;
    }
    _sessionCounted = true;
    update((Progress p) => p.copyWith(sessions: p.sessions + 1));
  }

  /// Applies [change] and saves. Returns false if progress is not loaded yet.
  bool update(Progress Function(Progress current) change) {
    if (!value.loaded) {
      _log.log(LogLevel.warning, 'progress', 'update before load ignored');
      return false;
    }
    final Progress next = change(value.progress);
    if (next == value.progress) {
      return true;
    }
    value = value.copyWith(progress: next);
    _dirty = true;
    unawaited(_drain());
    return true;
  }

  /// Records a finished match, then re-evaluates achievements.
  MatchRecorded applyMatch(MatchSummary summary) {
    final Progress before = progress;
    final Set<String> unlocksBefore = ProgressionRules.unlocksFor(before);
    final List<String> earned = <String>[];
    update((Progress p) {
      final Progress next = _withAchievements(ProgressionRules.recordMatch(p, summary), earned);
      return next;
    });
    return MatchRecorded(
      stars: ProgressionRules.stars(summary),
      newAchievements: earned,
      newUnlocks: ProgressionRules.unlocksFor(progress).difference(unlocksBefore),
      newLamps: progress.lamps.difference(before.lamps),
    );
  }

  /// Records the Daily Bread result for its day (the first result only).
  List<String> applyDaily(DailyChallenge challenge, {required bool won, required int goals}) {
    final List<String> earned = <String>[];
    update((Progress p) => _withAchievements(
          ProgressionRules.recordDaily(p, challenge, won: won, goals: goals),
          earned,
        ));
    return earned;
  }

  /// Records one day of Seven Days.
  void applySevenDays({required String todayKey, required bool won}) {
    update((Progress p) =>
        ProgressionRules.recordSevenDays(p, todayKey: todayKey, won: won));
  }

  void markUnlocksAnnounced() {
    final Set<String> all = ProgressionRules.unlocksFor(progress);
    update((Progress p) => p.copyWith(announcedUnlocks: <String>{...p.announcedUnlocks, ...all}));
  }

  void markRatingPromptShown() =>
      update((Progress p) => p.copyWith(ratingPromptShown: true));

  /// Hides the one-time recovery notice.
  void dismissNotice() => value = value.copyWith(noticeDismissed: true);

  /// Tries to write again now, for the warning banner's Retry.
  Future<void> retrySave() {
    if (value.loaded) {
      _dirty = true;
      unawaited(_drain());
    }
    return flush();
  }

  /// Completes when every change made so far has been written (or has failed).
  Future<void> flush() => _idle?.future ?? Future<void>.value();

  Progress _withAchievements(Progress p, List<String> collector) {
    final List<String> fresh = AchievementsEngine.evaluate(p);
    if (fresh.isEmpty) {
      return p;
    }
    collector
      ..clear()
      ..addAll(fresh);
    return p.copyWith(achievements: <String>{...p.achievements, ...fresh});
  }

  Future<void> _drain() async {
    if (_writing) {
      return;
    }
    _writing = true;
    final Completer<void> idle = Completer<void>();
    _idle = idle;
    try {
      while (_dirty) {
        _dirty = false;
        final SaveResult result = await _store.save(value.progress);
        switch (result) {
          case SaveOk():
            if (value.saveFailed) {
              value = value.copyWith(saveFailed: false);
            }
          case SaveSkippedReadOnly():
            if (!value.readOnly) {
              value = value.copyWith(readOnly: true);
            }
          case SaveFailed(:final StorageDegradedError error):
            _log.log(LogLevel.error, 'progress', 'kept in memory: ${error.code}');
            value = value.copyWith(saveFailed: true);
        }
      }
    } finally {
      _writing = false;
      _idle = null;
      idle.complete();
    }
  }
}
