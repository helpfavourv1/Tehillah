enum EntitlementStatus { unknown, notOwned, pending, owned }

enum PurchaseOutcome { started, alreadyOwned, cancelled, unavailable, failed }

/// The store billing behind an interface. The only product is Remove Ads.
abstract interface class BillingPort {
  Future<void> initialize();

  /// The localized price of Remove Ads, or null if the store has not answered.
  Future<String?> priceLabel();

  Future<PurchaseOutcome> buyRemoveAds();

  /// Asks the store to replay past purchases; results arrive on
  /// [entitlementChanges].
  Future<void> restore();

  Future<EntitlementStatus> currentEntitlement();

  Stream<EntitlementStatus> get entitlementChanges;
}
