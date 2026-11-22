import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:tehillah/core/ports/ads_port.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/platform/ad_unit_ids.dart';

/// AdMob behind [AdsPort].
///
/// Three protections are built in:
///  * every method first asks [mayRequest], so nothing is initialized or loaded
///    until consent allows it and the caller's other checks pass;
///  * every SDK failure becomes "no ad" and a log line, never an exception;
///  * a banner that is loading, failed or removed has zero height and draws
///    nothing.
final class AdService implements AdsPort {
  AdService({required bool Function() mayRequest, LogPort? log})
      : _mayRequest = mayRequest,
        _log = log;

  static const Duration _loadTimeout = Duration(seconds: 20);

  final bool Function() _mayRequest;
  final LogPort? _log;
  final StreamController<BannerState> _bannerStates = StreamController<BannerState>.broadcast();
  bool _ready = false;
  BannerAd? _banner;
  AdSize? _bannerSize;
  BannerState _bannerState = BannerState.hidden;
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;

  bool get _allowed => _ready && _mayRequest();

  void _emit(BannerState state) {
    _bannerState = state;
    if (!_bannerStates.isClosed) {
      _bannerStates.add(state);
    }
  }

  @override
  Future<bool> initialize() async {
    if (_ready) {
      return true;
    }
    if (!_mayRequest()) {
      return false;
    }
    try {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(maxAdContentRating: MaxAdContentRating.t),
      );
      await MobileAds.instance.initialize();
      _ready = true;
    } on Object catch (error) {
      _log?.log(LogLevel.error, 'ads', 'SDK did not start: $error');
      _ready = false;
    }
    return _ready;
  }

  @override
  Stream<BannerState> get bannerState => _bannerStates.stream;

  BannerState get currentBanner => _bannerState;

  /// The banner as a widget, or null while there is nothing to show. The size is
  /// the ad's own, so the slot is exactly as tall as the ad.
  Widget? buildBanner() {
    final BannerAd? banner = _banner;
    final AdSize? size = _bannerSize;
    if (banner == null || size == null || _bannerState.status != BannerStatus.ready) {
      return null;
    }
    return SizedBox(
      width: size.width.toDouble(),
      height: size.height.toDouble(),
      child: AdWidget(ad: banner),
    );
  }

  @override
  Future<void> loadBanner({required int widthDp}) async {
    disposeBanner();
    if (!_allowed || widthDp < 120) {
      return;
    }
    try {
      _emit(const BannerState(BannerStatus.loading, 0));
      final AnchoredAdaptiveBannerAdSize? size =
          await AdSize.getAnchoredAdaptiveBannerAdSize(Orientation.portrait, widthDp);
      if (size == null) {
        _emit(BannerState.hidden);
        return;
      }
      late final BannerAd banner;
      banner = BannerAd(
        adUnitId: AdUnitIds.banner,
        size: size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            if (identical(_banner, banner)) {
              _emit(BannerState(BannerStatus.ready, size.height.toDouble()));
            }
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            _log?.log(LogLevel.info, 'ads', 'banner not loaded: ${error.code} ${error.message}');
            ad.dispose();
            if (identical(_banner, banner)) {
              _banner = null;
              _bannerSize = null;
              _emit(BannerState.hidden);
            }
          },
        ),
      );
      _banner = banner;
      _bannerSize = size;
      await banner.load();
    } on Object catch (error) {
      _log?.log(LogLevel.warning, 'ads', 'banner failed: $error');
      disposeBanner();
    }
  }

  @override
  void disposeBanner() {
    final BannerAd? banner = _banner;
    _banner = null;
    _bannerSize = null;
    if (banner != null) {
      banner.dispose().ignore();
    }
    if (_bannerState.status != BannerStatus.hidden) {
      _emit(BannerState.hidden);
    }
  }

  @override
  Future<bool> loadInterstitial() async {
    if (!_allowed) {
      return false;
    }
    if (_interstitial != null) {
      return true;
    }
    final Completer<bool> done = Completer<bool>();
    try {
      await InterstitialAd.load(
        adUnitId: AdUnitIds.interstitial,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitial = ad;
            if (!done.isCompleted) {
              done.complete(true);
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            _log?.log(LogLevel.info, 'ads', 'interstitial not loaded: ${error.code}');
            if (!done.isCompleted) {
              done.complete(false);
            }
          },
        ),
      );
      return await done.future.timeout(_loadTimeout, onTimeout: () => false);
    } on Object catch (error) {
      _log?.log(LogLevel.warning, 'ads', 'interstitial failed: $error');
      return false;
    }
  }

  @override
  Future<bool> showInterstitial() async {
    final InterstitialAd? ad = _interstitial;
    if (ad == null || !_allowed) {
      return false;
    }
    _interstitial = null;
    final Completer<bool> closed = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback<InterstitialAd>(
      onAdDismissedFullScreenContent: (InterstitialAd shown) {
        shown.dispose().ignore();
        if (!closed.isCompleted) {
          closed.complete(true);
        }
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd shown, AdError error) {
        _log?.log(LogLevel.info, 'ads', 'interstitial not shown: ${error.code}');
        shown.dispose().ignore();
        if (!closed.isCompleted) {
          closed.complete(false);
        }
      },
    );
    try {
      await ad.show();
      return await closed.future;
    } on Object catch (error) {
      _log?.log(LogLevel.warning, 'ads', 'interstitial show failed: $error');
      return false;
    }
  }

  @override
  Future<bool> loadRewarded() async {
    if (!_allowed) {
      return false;
    }
    if (_rewarded != null) {
      return true;
    }
    final Completer<bool> done = Completer<bool>();
    try {
      await RewardedAd.load(
        adUnitId: AdUnitIds.rewarded,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            _rewarded = ad;
            if (!done.isCompleted) {
              done.complete(true);
            }
          },
          onAdFailedToLoad: (LoadAdError error) {
            _log?.log(LogLevel.info, 'ads', 'rewarded not loaded: ${error.code}');
            if (!done.isCompleted) {
              done.complete(false);
            }
          },
        ),
      );
      return await done.future.timeout(_loadTimeout, onTimeout: () => false);
    } on Object catch (error) {
      _log?.log(LogLevel.warning, 'ads', 'rewarded failed: $error');
      return false;
    }
  }

  @override
  Future<RewardResult> showRewarded() async {
    final RewardedAd? ad = _rewarded;
    if (ad == null || !_allowed) {
      return RewardResult.unavailable;
    }
    _rewarded = null;
    bool earned = false;
    final Completer<RewardResult> closed = Completer<RewardResult>();
    ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
      onAdDismissedFullScreenContent: (RewardedAd shown) {
        shown.dispose().ignore();
        if (!closed.isCompleted) {
          closed.complete(earned ? RewardResult.earned : RewardResult.dismissed);
        }
      },
      onAdFailedToShowFullScreenContent: (RewardedAd shown, AdError error) {
        _log?.log(LogLevel.info, 'ads', 'rewarded not shown: ${error.code}');
        shown.dispose().ignore();
        if (!closed.isCompleted) {
          closed.complete(RewardResult.unavailable);
        }
      },
    );
    try {
      await ad.show(onUserEarnedReward: (AdWithoutView view, RewardItem reward) => earned = true);
      return await closed.future;
    } on Object catch (error) {
      _log?.log(LogLevel.warning, 'ads', 'rewarded show failed: $error');
      return RewardResult.unavailable;
    }
  }

  Future<void> dispose() async {
    disposeBanner();
    await _interstitial?.dispose();
    await _rewarded?.dispose();
    _interstitial = null;
    _rewarded = null;
    await _bannerStates.close();
  }
}
