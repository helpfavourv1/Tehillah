import 'package:flutter/foundation.dart';
import 'package:tehillah/core/ads/consent_tracker.dart';
import 'package:tehillah/core/ports/consent_port.dart';
import 'package:tehillah/providers/safe_notifier.dart';

@immutable
final class ConsentState {
  const ConsentState({
    this.snapshot = ConsentSnapshot.unknown,
    this.refreshed = false,
    this.busy = false,
  });

  final ConsentSnapshot snapshot;

  /// The launch refresh has finished (with a fresh or a saved answer).
  final bool refreshed;

  /// A refresh or the privacy options form is in progress.
  final bool busy;

  /// Ads may be requested. Follows UMP; a failed refresh keeps a saved answer.
  bool get canRequestAds => snapshot.canRequestAds;

  /// Settings shows the Privacy choices row.
  bool get privacyOptionsRequired => snapshot.privacyOptionsRequired;

  ConsentState copyWith({ConsentSnapshot? snapshot, bool? refreshed, bool? busy}) {
    return ConsentState(
      snapshot: snapshot ?? this.snapshot,
      refreshed: refreshed ?? this.refreshed,
      busy: busy ?? this.busy,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ConsentState &&
      other.snapshot == snapshot &&
      other.refreshed == refreshed &&
      other.busy == busy;

  @override
  int get hashCode => Object.hash(snapshot, refreshed, busy);
}

/// Consent state for the whole app. [ConsentTracker] holds the rules (a failed
/// or offline refresh never overrides a saved answer); this exposes them.
final class ConsentProvider extends SafeNotifier<ConsentState> {
  ConsentProvider(this._tracker) : super(const ConsentState());

  final ConsentTracker _tracker;

  /// Refreshes consent, showing the form where one is required. Run on every
  /// launch before any ad is requested. Never throws.
  Future<void> refreshOnLaunch() async {
    value = value.copyWith(busy: true);
    final ConsentSnapshot snapshot = await _tracker.refresh();
    value = ConsentState(snapshot: snapshot, refreshed: true);
  }

  /// Opens the Privacy choices form and re-reads the state at once.
  Future<void> openPrivacyOptions() async {
    value = value.copyWith(busy: true);
    final ConsentSnapshot snapshot = await _tracker.openPrivacyOptions();
    value = value.copyWith(snapshot: snapshot, busy: false);
  }
}
