import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:tehillah/core/config/app_config.dart';
import 'package:tehillah/core/ports/billing_port.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/core/ports/storage_port.dart';

/// One purchase event for the Remove Ads product.
typedef PurchaseEvent = ({String productId, PurchaseStatus status});

/// Works out the entitlement after a batch of store events. Pure, so the rules
/// are tested without a store.
///
///  * a purchased or restored event for the product means owned;
///  * a pending event means pending (unless already owned);
///  * an error or cancel leaves things as they were, or not owned if it was pending;
///  * an empty batch while a restore we started is running means the store holds
///    no purchase, so not owned (this is how a refund is noticed);
///  * events for other products change nothing.
EntitlementStatus entitlementAfter(
  EntitlementStatus current,
  List<PurchaseEvent> events, {
  required String productId,
  required bool restoreInFlight,
}) {
  if (events.isEmpty) {
    return restoreInFlight ? EntitlementStatus.notOwned : current;
  }
  final List<PurchaseEvent> mine = <PurchaseEvent>[
    for (final PurchaseEvent e in events)
      if (e.productId == productId) e,
  ];
  if (mine.isEmpty) {
    return current;
  }
  if (mine.any((PurchaseEvent e) => e.status == PurchaseStatus.purchased || e.status == PurchaseStatus.restored)) {
    return EntitlementStatus.owned;
  }
  if (mine.any((PurchaseEvent e) => e.status == PurchaseStatus.pending)) {
    return current == EntitlementStatus.owned ? current : EntitlementStatus.pending;
  }
  return current == EntitlementStatus.pending ? EntitlementStatus.notOwned : current;
}

/// The store's billing for the one Remove Ads purchase (Google Play Billing on
/// Android, StoreKit on iOS). There is no server: entitlement comes from the
/// store's own purchase list on every launch. The last answer is remembered so
/// a launch with no connection still shows the purchase.
final class BillingService implements BillingPort {
  BillingService(
    this._storage, {
    String productId = AppConfig.removeAdsProductId,
    InAppPurchase? store,
    LogPort? log,
    this.settleTime = const Duration(seconds: 4),
  })  : _productId = productId,
        _store = store ?? InAppPurchase.instance,
        _log = log;

  static const String cacheKey = 'entitlement.removeAds.v1';

  final StoragePort _storage;
  final String _productId;
  final InAppPurchase _store;
  final LogPort? _log;

  /// How long to wait for the store's first answer before deciding "not owned".
  final Duration settleTime;

  final StreamController<EntitlementStatus> _changes = StreamController<EntitlementStatus>.broadcast();
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Timer? _settleTimer;
  EntitlementStatus _status = EntitlementStatus.unknown;
  bool _restoreInFlight = false;

  void _set(EntitlementStatus status) {
    if (status == _status) {
      return;
    }
    _status = status;
    if (!_changes.isClosed) {
      _changes.add(status);
    }
    unawaited(_remember(status));
  }

  Future<void> _remember(EntitlementStatus status) async {
    try {
      if (status == EntitlementStatus.owned) {
        await _storage.setString(cacheKey, 'owned');
      } else if (status == EntitlementStatus.notOwned) {
        await _storage.removeKey(cacheKey);
      }
    } on Object catch (error) {
      _log?.log(LogLevel.warning, 'billing', 'could not remember entitlement: $error');
    }
  }

  @override
  Future<void> initialize() async {
    try {
      if (await _storage.getString(cacheKey) == 'owned') {
        _set(EntitlementStatus.owned);
      }
    } on Object {
      // No remembered answer; the store decides.
    }
    _subscription ??= _store.purchaseStream.listen(
      (List<PurchaseDetails> purchases) => unawaited(_onPurchases(purchases)),
      onError: (Object error) => _log?.log(LogLevel.warning, 'billing', 'purchase stream: $error'),
    );
    try {
      if (!await _store.isAvailable()) {
        _log?.log(LogLevel.info, 'billing', 'store not available');
        _settleAfterUnavailable();
        return;
      }
      _restoreInFlight = true;
      await _store.restorePurchases();
      _settleTimer = Timer(settleTime, () {
        _restoreInFlight = false;
        if (_status == EntitlementStatus.unknown) {
          _set(EntitlementStatus.notOwned);
        }
      });
    } on Object catch (error) {
      _log?.log(LogLevel.warning, 'billing', 'start-up check failed: $error');
      _restoreInFlight = false;
      _settleAfterUnavailable();
    }
  }

  void _settleAfterUnavailable() {
    if (_status == EntitlementStatus.unknown) {
      _set(EntitlementStatus.notOwned);
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    final List<PurchaseEvent> events = <PurchaseEvent>[
      for (final PurchaseDetails p in purchases) (productId: p.productID, status: p.status),
    ];
    for (final PurchaseDetails p in purchases) {
      if (p.status == PurchaseStatus.error) {
        _log?.log(LogLevel.warning, 'billing', 'purchase error: ${p.error?.code} ${p.error?.message}');
      }
      if (p.pendingCompletePurchase) {
        try {
          await _store.completePurchase(p);
        } on Object catch (error) {
          _log?.log(LogLevel.warning, 'billing', 'could not complete purchase: $error');
        }
      }
    }
    _set(entitlementAfter(_status, events, productId: _productId, restoreInFlight: _restoreInFlight));
    _restoreInFlight = false;
  }

  @override
  Future<String?> priceLabel() async {
    try {
      final ProductDetailsResponse response = await _store.queryProductDetails(<String>{_productId});
      return response.productDetails.isEmpty ? null : response.productDetails.first.price;
    } on Object catch (error) {
      _log?.log(LogLevel.info, 'billing', 'price not available: $error');
      return null;
    }
  }

  @override
  Future<PurchaseOutcome> buyRemoveAds() async {
    if (_status == EntitlementStatus.owned) {
      return PurchaseOutcome.alreadyOwned;
    }
    try {
      if (!await _store.isAvailable()) {
        return PurchaseOutcome.unavailable;
      }
      final ProductDetailsResponse response = await _store.queryProductDetails(<String>{_productId});
      if (response.productDetails.isEmpty) {
        return PurchaseOutcome.unavailable;
      }
      final bool started = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: response.productDetails.first),
      );
      return started ? PurchaseOutcome.started : PurchaseOutcome.failed;
    } on Object catch (error) {
      _log?.log(LogLevel.warning, 'billing', 'purchase failed to start: $error');
      return PurchaseOutcome.failed;
    }
  }

  @override
  Future<void> restore() async {
    try {
      _restoreInFlight = true;
      await _store.restorePurchases();
    } on Object catch (error) {
      _restoreInFlight = false;
      _log?.log(LogLevel.warning, 'billing', 'restore failed: $error');
    }
  }

  @override
  Future<EntitlementStatus> currentEntitlement() async => _status;

  @override
  Stream<EntitlementStatus> get entitlementChanges => _changes.stream;

  Future<void> dispose() async {
    _settleTimer?.cancel();
    await _subscription?.cancel();
    _subscription = null;
    await _changes.close();
  }
}
