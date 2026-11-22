import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/ads/ad_policy.dart';
import 'package:tehillah/core/models/remote_flags.dart';
import 'package:tehillah/core/ports/billing_port.dart';

AdInputs _in({
  bool consent = true,
  EntitlementStatus entitlement = EntitlementStatus.notOwned,
  RemoteFlags flags = RemoteFlags.defaults,
  int sessions = 3,
  Duration? since,
}) =>
    AdInputs(
      canRequestAds: consent,
      entitlement: entitlement,
      flags: flags,
      sessions: sessions,
      sinceLastInterstitial: since,
    );

void main() {
  group('banner', () {
    test('allowed with consent, not owned and the switch on', () {
      expect(AdPolicy.banner(_in()), isTrue);
    });

    test('blocked without consent', () {
      expect(AdPolicy.banner(_in(consent: false)), isFalse);
    });

    for (final EntitlementStatus s in <EntitlementStatus>[
      EntitlementStatus.owned,
      EntitlementStatus.unknown,
      EntitlementStatus.pending,
    ]) {
      test('blocked while the entitlement is ${s.name}', () {
        expect(AdPolicy.banner(_in(entitlement: s)), isFalse);
      });
    }

    test('blocked by the remote switch', () {
      expect(AdPolicy.banner(_in(flags: const RemoteFlags(adsEnabled: false))), isFalse);
    });
  });

  group('interstitial', () {
    test('never in the first session', () {
      expect(AdPolicy.interstitialShow(_in(sessions: 1)), isFalse);
      expect(AdPolicy.interstitialShow(_in(sessions: 2)), isTrue);
    });

    test('ten minutes apart, no sooner', () {
      expect(AdPolicy.interstitialShow(_in(since: const Duration(minutes: 9, seconds: 59))), isFalse);
      expect(AdPolicy.interstitialShow(_in(since: const Duration(minutes: 10))), isTrue);
      expect(AdPolicy.interstitialShow(_in()), isTrue);
    });

    test('blocked by its own switch, the master switch, consent and ownership', () {
      expect(AdPolicy.interstitialShow(_in(flags: const RemoteFlags(interstitialsEnabled: false))), isFalse);
      expect(AdPolicy.interstitialShow(_in(flags: const RemoteFlags(adsEnabled: false))), isFalse);
      expect(AdPolicy.interstitialShow(_in(consent: false)), isFalse);
      expect(AdPolicy.interstitialShow(_in(entitlement: EntitlementStatus.owned)), isFalse);
    });
  });

  group('rewarded', () {
    test('stays available after Remove Ads', () {
      expect(AdPolicy.rewarded(_in(entitlement: EntitlementStatus.owned)), isTrue);
    });

    test('still needs consent and both switches', () {
      expect(AdPolicy.rewarded(_in(consent: false)), isFalse);
      expect(AdPolicy.rewarded(_in(flags: const RemoteFlags(rewardedEnabled: false))), isFalse);
      expect(AdPolicy.rewarded(_in(flags: const RemoteFlags(adsEnabled: false))), isFalse);
    });
  });
}
