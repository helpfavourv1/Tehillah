import 'package:flutter/foundation.dart';

/// Ad unit IDs. These are Google's published sample units, which always serve
/// test ads. Production IDs replace them when the owner supplies them; until
/// then [production] stays false and no real ad can be shown or clicked.
abstract final class AdUnitIds {
  static const bool production = false;

  static const String _androidBanner = 'ca-app-pub-3940256099942544/9214589741';
  static const String _androidInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const String _androidRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const String _iosBanner = 'ca-app-pub-3940256099942544/2435281174';
  static const String _iosInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const String _iosRewarded = 'ca-app-pub-3940256099942544/1712485313';

  static bool get _ios => defaultTargetPlatform == TargetPlatform.iOS;

  static String get banner => _ios ? _iosBanner : _androidBanner;

  static String get interstitial => _ios ? _iosInterstitial : _androidInterstitial;

  static String get rewarded => _ios ? _iosRewarded : _androidRewarded;

  static List<String> get all => <String>[
        _androidBanner,
        _androidInterstitial,
        _androidRewarded,
        _iosBanner,
        _iosInterstitial,
        _iosRewarded,
      ];
}
