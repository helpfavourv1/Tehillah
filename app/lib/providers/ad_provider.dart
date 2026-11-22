import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tehillah/core/ads/ad_policy.dart';
import 'package:tehillah/core/models/remote_flags.dart';
import 'package:tehillah/core/ports/ads_port.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/providers/consent_provider.dart';
import 'package:tehillah/providers/entitlement_provider.dart';
import 'package:tehillah/providers/progress_provider.dart';
import 'package:tehillah/providers/safe_notifier.dart';

/// What the ad slot and the result screen read.
@immutable
final class AdState {
  const AdState({
    this.initialized = false,
    this.bannerVisible = false,
    this.bannerHeightDp = 0,
    this.interstitialReady = false,
    this.rewardedReady = false,
  });

  final bool initialized;

  /// A banner is ready and allowed. When false the slot has no height, no gap
  /// and no border.
  final bool bannerVisible;

  /// The height the slot takes; zero whenever [bannerVisible] is false.
  final double bannerHeightDp;

  final bool interstitialReady;
  final bool rewardedReady;

  @override
  bool operator ==(Object other) =>
      other is AdState &&
      other.initialized == initialized &&
      other.bannerVisible == bannerVisible &&
      other.bannerHeightDp == bannerHeightDp &&
      other.interstitialReady == interstitialReady &&
      other.rewardedReady == rewardedReady;

  @override
  int get hashCode =>
      Object.hash(initialized, bannerVisible, bannerHeightDp, interstitialReady, rewardedReady);
}

/// The single ad decision. It combines consent, entitlement, the remote flags,
/// the session count and the keyboard through [AdPolicy], and drives
/// [AdsPort]. Any ad failure collapses the slot and is logged; nothing here
/// throws.
final class AdProvider extends SafeNotifier<AdState> {
  AdProvider({
    required AdsPort ads,
    required ConsentProvider consent,
    required EntitlementProvider entitlement,
    required ValueListenable<RemoteFlags> flags,
    required ProgressProvider progress,
    required LogPort log,
    DateTime Function()? clock,
  })  : _ads = ads,
        _consent = consent,
        _entitlement = entitlement,
        _flags = flags,
        _progress = progress,
        _log = log,
        _clock = clock ?? DateTime.now,
        super(const AdState()) {
    _consent.addListener(_reevaluate);
    _entitlement.addListener(_reevaluate);
    _flags.addListener(_reevaluate);
    _progress.addListener(_reevaluate);
    _bannerSub = _ads.bannerState.listen(
      (BannerState s) {
        _banner = s;
        _publish();
      },
      onError: (Object error) {
        _log.log(LogLevel.warning, 'ads', 'banner stream error: $error');
        _banner = BannerState.hidden;
        _publish();
      },
    );
  }

  final AdsPort _ads;
  final ConsentProvider _consent;
  final EntitlementProvider _entitlement;
  final ValueListenable<RemoteFlags> _flags;
  final ProgressProvider _progress;
  final LogPort _log;
  final DateTime Function() _clock;

  StreamSubscription<BannerState>? _bannerSub;
  BannerState _banner = BannerState.hidden;
  bool _initStarted = false;
  bool _initialized = false;
  bool _keyboardOpen = false;
  int? _widthDp;
  bool _bannerRequested = false;
  bool _interstitialReady = false;
  bool _interstitialLoading = false;
  bool _rewardedReady = false;
  bool _rewardedLoading = false;
  DateTime? _lastInterstitial;

  AdInputs get _inputs => AdInputs(
        canRequestAds: _consent.value.canRequestAds,
        entitlement: _entitlement.value.status,
        flags: _flags.value,
        sessions: _progress.progress.sessions,
        sinceLastInterstitial:
            _lastInterstitial == null ? null : _clock().difference(_lastInterstitial!),
      );

  /// The slot reports its width so an adaptive banner can be requested.
  void requestBanner(int widthDp) {
    _widthDp = widthDp;
    _reevaluate();
  }

  /// The slot collapses completely while the keyboard is open.
  void setKeyboardOpen(bool open) {
    if (_keyboardOpen == open) {
      return;
    }
    _keyboardOpen = open;
    _publish();
  }

  /// Whether the result screen may show an interstitial right now.
  bool get canShowInterstitial =>
      _initialized && _interstitialReady && AdPolicy.interstitialShow(_inputs);

  /// Shows an interstitial if the rules allow it. Returns whether one was
  /// shown. The next one is loaded afterwards.
  Future<bool> showInterstitial() async {
    if (!canShowInterstitial) {
      return false;
    }
    bool shown = false;
    try {
      shown = await _ads.showInterstitial();
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'ads', 'interstitial failed: $error');
    }
    _interstitialReady = false;
    if (shown) {
      _lastInterstitial = _clock();
    }
    _publish();
    unawaited(_loadInterstitial());
    return shown;
  }

  /// Shows a rewarded ad the player asked for.
  Future<RewardResult> showRewarded() async {
    if (!_initialized || !_rewardedReady || !AdPolicy.rewarded(_inputs)) {
      return RewardResult.unavailable;
    }
    RewardResult result = RewardResult.unavailable;
    try {
      result = await _ads.showRewarded();
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'ads', 'rewarded failed: $error');
    }
    _rewardedReady = false;
    _publish();
    unawaited(_loadRewarded());
    return result;
  }

  void _reevaluate() {
    if (isDisposed) {
      return;
    }
    final AdInputs inputs = _inputs;
    final bool needsSdk = AdPolicy.banner(inputs) ||
        AdPolicy.interstitialLoad(inputs) ||
        AdPolicy.rewarded(inputs);
    if (needsSdk && !_initStarted) {
      _initStarted = true;
      unawaited(_initialize());
    }
    if (!_initialized) {
      _publish();
      return;
    }
    if (AdPolicy.banner(inputs)) {
      final int? width = _widthDp;
      if (width != null && !_bannerRequested) {
        _bannerRequested = true;
        unawaited(_loadBanner(width));
      }
    } else if (_bannerRequested) {
      _bannerRequested = false;
      _banner = BannerState.hidden;
      _safely(_ads.disposeBanner);
    }
    if (AdPolicy.interstitialLoad(inputs)) {
      unawaited(_loadInterstitial());
    } else {
      _interstitialReady = false;
    }
    if (AdPolicy.rewarded(inputs)) {
      unawaited(_loadRewarded());
    } else {
      _rewardedReady = false;
    }
    _publish();
  }

  Future<void> _initialize() async {
    try {
      _initialized = await _ads.initialize();
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'ads', 'initialize failed: $error');
      _initialized = false;
    }
    if (_initialized) {
      _reevaluate();
    } else {
      _publish();
    }
  }

  Future<void> _loadBanner(int width) async {
    try {
      await _ads.loadBanner(widthDp: width);
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'ads', 'banner load failed: $error');
      _banner = BannerState.hidden;
      _publish();
    }
  }

  Future<void> _loadInterstitial() async {
    if (_interstitialReady || _interstitialLoading || !_initialized) {
      return;
    }
    if (!AdPolicy.interstitialLoad(_inputs)) {
      return;
    }
    _interstitialLoading = true;
    try {
      _interstitialReady = await _ads.loadInterstitial();
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'ads', 'interstitial load failed: $error');
      _interstitialReady = false;
    }
    _interstitialLoading = false;
    _publish();
  }

  Future<void> _loadRewarded() async {
    if (_rewardedReady || _rewardedLoading || !_initialized) {
      return;
    }
    if (!AdPolicy.rewarded(_inputs)) {
      return;
    }
    _rewardedLoading = true;
    try {
      _rewardedReady = await _ads.loadRewarded();
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'ads', 'rewarded load failed: $error');
      _rewardedReady = false;
    }
    _rewardedLoading = false;
    _publish();
  }

  void _safely(void Function() action) {
    try {
      action();
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'ads', 'ad call failed: $error');
    }
  }

  void _publish() {
    final bool visible = _initialized &&
        AdPolicy.banner(_inputs) &&
        !_keyboardOpen &&
        _banner.status == BannerStatus.ready &&
        _banner.heightDp > 0;
    value = AdState(
      initialized: _initialized,
      bannerVisible: visible,
      bannerHeightDp: visible ? _banner.heightDp : 0,
      interstitialReady: _initialized && _interstitialReady && AdPolicy.interstitialLoad(_inputs),
      rewardedReady: _initialized && _rewardedReady && AdPolicy.rewarded(_inputs),
    );
  }

  @override
  void dispose() {
    if (isDisposed) {
      return;
    }
    _consent.removeListener(_reevaluate);
    _entitlement.removeListener(_reevaluate);
    _flags.removeListener(_reevaluate);
    _progress.removeListener(_reevaluate);
    unawaited(_bannerSub?.cancel());
    super.dispose();
  }
}
