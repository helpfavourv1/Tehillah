import 'package:tehillah/core/models/remote_flags.dart';
import 'package:tehillah/core/ports/billing_port.dart';

/// Everything the ad decision reads, gathered in one value so the rules below
/// are a pure function that tests can run through a truth table.
final class AdInputs {
  const AdInputs({
    required this.canRequestAds,
    required this.entitlement,
    required this.flags,
    required this.sessions,
    this.sinceLastInterstitial,
  });

  /// UMP's answer. False until consent is known, and while a form is required
  /// and unanswered.
  final bool canRequestAds;

  final EntitlementStatus entitlement;
  final RemoteFlags flags;

  /// How many times the app has been opened, this launch included.
  final int sessions;

  /// Time since the last interstitial was shown, or null if none this run.
  final Duration? sinceLastInterstitial;
}

/// The ad rules from the blueprint, section 7.
abstract final class AdPolicy {
  /// The minimum gap between two interstitials.
  static const Duration interstitialGap = Duration(minutes: 10);

  /// Banner and interstitial ads may be requested. They need consent, the
  /// remote switch, and a store answer of "not owned": while the store has not
  /// answered (or a purchase is pending) no ad is requested, so a buyer never
  /// sees one flash up.
  static bool bannerAndInterstitialBase(AdInputs i) =>
      i.canRequestAds &&
      i.flags.adsEnabled &&
      i.entitlement == EntitlementStatus.notOwned;

  static bool banner(AdInputs i) => bannerAndInterstitialBase(i);

  /// An interstitial may be loaded now.
  static bool interstitialLoad(AdInputs i) =>
      bannerAndInterstitialBase(i) && i.flags.interstitialsEnabled;

  /// An interstitial may be shown now: never in the first session, and at
  /// most one per [interstitialGap].
  static bool interstitialShow(AdInputs i) {
    if (!interstitialLoad(i) || i.sessions <= 1) {
      return false;
    }
    final Duration? since = i.sinceLastInterstitial;
    return since == null || since >= interstitialGap;
  }

  /// A rewarded ad may be offered. It is the player's own choice, so it stays
  /// available after Remove Ads, but it still needs consent and the switch.
  static bool rewarded(AdInputs i) =>
      i.canRequestAds && i.flags.adsEnabled && i.flags.rewardedEnabled;
}
