enum BannerStatus { hidden, loading, ready }

/// What the banner slot should show. Height is zero unless [status] is ready.
final class BannerState {
  const BannerState(this.status, this.heightDp);

  static const BannerState hidden = BannerState(BannerStatus.hidden, 0);

  final BannerStatus status;
  final double heightDp;

  @override
  bool operator ==(Object other) =>
      other is BannerState && other.status == status && other.heightDp == heightDp;

  @override
  int get hashCode => Object.hash(status, heightDp);
}

enum RewardResult { earned, dismissed, unavailable }

/// The ad SDK behind a small interface. Every method is safe to call when the
/// SDK failed: nothing throws, the answer is simply "no ad". Callers must have
/// passed the consent and entitlement checks before calling any load method.
abstract interface class AdsPort {
  /// Starts the SDK. False means it failed and every slot stays collapsed.
  Future<bool> initialize();

  Future<void> loadBanner({required int widthDp});

  Stream<BannerState> get bannerState;

  void disposeBanner();

  Future<bool> loadInterstitial();

  /// True once an interstitial was shown and closed.
  Future<bool> showInterstitial();

  Future<bool> loadRewarded();

  Future<RewardResult> showRewarded();
}
