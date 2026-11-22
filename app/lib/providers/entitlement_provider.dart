import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tehillah/core/ports/billing_port.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/providers/safe_notifier.dart';

/// Whether Remove Ads is owned, and what the store screen needs to show.
@immutable
final class Entitlement {
  const Entitlement({
    this.status = EntitlementStatus.unknown,
    this.restoring = false,
    this.priceLabel,
  });

  final EntitlementStatus status;

  /// A restore is running and the store has not answered yet.
  final bool restoring;

  /// The localized price, or null until the store has answered.
  final String? priceLabel;

  /// The one fact every ad decision reads. Only a confirmed purchase removes
  /// ads; `unknown` and `pending` do not.
  bool get adsRemoved => status == EntitlementStatus.owned;

  Entitlement copyWith({EntitlementStatus? status, bool? restoring, String? priceLabel}) {
    return Entitlement(
      status: status ?? this.status,
      restoring: restoring ?? this.restoring,
      priceLabel: priceLabel ?? this.priceLabel,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Entitlement &&
      other.status == status &&
      other.restoring == restoring &&
      other.priceLabel == priceLabel;

  @override
  int get hashCode => Object.hash(status, restoring, priceLabel);
}

/// The single source for ad removal. It never infers ownership at the point of
/// use: screens and the ad provider read [Entitlement.adsRemoved].
final class EntitlementProvider extends SafeNotifier<Entitlement> {
  EntitlementProvider(
    this._billing,
    this._log, {
    this.restoreTimeout = const Duration(seconds: 20),
  }) : super(const Entitlement());

  final BillingPort _billing;
  final LogPort _log;

  /// How long a restore waits for the store before it stops showing progress.
  final Duration restoreTimeout;

  StreamSubscription<EntitlementStatus>? _subscription;
  Completer<void>? _restoreAnswer;

  /// Reads the current state, the price and starts listening for changes.
  /// Never throws: a billing failure leaves the status unknown.
  Future<void> start() async {
    await _subscription?.cancel();
    _subscription = _billing.entitlementChanges.listen(_onStatus);
    try {
      await _billing.initialize();
      _onStatus(await _billing.currentEntitlement(), fromStream: false);
      final String? price = await _billing.priceLabel();
      if (price != null) {
        value = value.copyWith(priceLabel: price);
      }
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'entitlement', 'billing unavailable: $error');
    }
  }

  void _onStatus(EntitlementStatus status, {bool fromStream = true}) {
    value = value.copyWith(status: status);
    if (fromStream && status != EntitlementStatus.pending) {
      final Completer<void>? waiting = _restoreAnswer;
      if (waiting != null && !waiting.isCompleted) {
        waiting.complete();
      }
    }
  }

  /// Starts the purchase. The result arrives on the status as well.
  Future<PurchaseOutcome> buy() async {
    try {
      final PurchaseOutcome outcome = await _billing.buyRemoveAds();
      if (outcome == PurchaseOutcome.started) {
        value = value.copyWith(status: EntitlementStatus.pending);
      }
      return outcome;
    } on Object catch (error) {
      _log.log(LogLevel.error, 'entitlement', 'purchase failed: $error');
      return PurchaseOutcome.failed;
    }
  }

  /// Asks the store to replay purchases. Completes when the store answers or
  /// after [restoreTimeout]; [Entitlement.restoring] is true meanwhile.
  Future<void> restore() async {
    if (value.restoring) {
      return;
    }
    final Completer<void> answer = Completer<void>();
    _restoreAnswer = answer;
    value = value.copyWith(restoring: true);
    try {
      await _billing.restore();
      await answer.future.timeout(restoreTimeout, onTimeout: () {});
    } on Object catch (error) {
      _log.log(LogLevel.error, 'entitlement', 'restore failed: $error');
    } finally {
      _restoreAnswer = null;
      value = value.copyWith(restoring: false);
    }
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
