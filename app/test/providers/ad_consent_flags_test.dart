import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/ads/consent_tracker.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/models/remote_flags.dart';
import 'package:tehillah/core/ports/ads_port.dart';
import 'package:tehillah/core/ports/billing_port.dart';
import 'package:tehillah/core/ports/consent_port.dart';
import 'package:tehillah/core/storage/progress_store.dart';
import 'package:tehillah/providers/ad_provider.dart';
import 'package:tehillah/providers/consent_provider.dart';
import 'package:tehillah/providers/entitlement_provider.dart';
import 'package:tehillah/providers/flags_provider.dart';
import 'package:tehillah/providers/progress_provider.dart';

import '../fakes/fake_ports.dart';
import '../fakes/fake_storage.dart';

const ConsentSnapshot _allowed = ConsentSnapshot(
  status: ConsentStatus.obtained,
  canRequestAds: true,
  privacyOptionsRequired: true,
);
const ConsentSnapshot _blocked = ConsentSnapshot(
  status: ConsentStatus.required,
  canRequestAds: false,
  privacyOptionsRequired: true,
);

Future<void> _settle() async {
  for (int i = 0; i < 6; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late FakeStorage storage;
  late FakeLog log;
  late FakeConsent consentPort;
  late FakeAds ads;
  late FakeBilling billing;
  late FakeFlags flagsPort;
  late ConsentProvider consent;
  late EntitlementProvider entitlement;
  late FlagsProvider flags;
  late ProgressProvider progress;
  late DateTime now;
  late AdProvider adProvider;

  Future<void> build({int sessions = 3}) async {
    storage = FakeStorage();
    log = FakeLog();
    consentPort = FakeConsent();
    ads = FakeAds();
    billing = FakeBilling();
    flagsPort = FakeFlags();
    consent = ConsentProvider(ConsentTracker(consentPort, storage, log));
    entitlement = EntitlementProvider(billing, log);
    flags = FlagsProvider(flagsPort, log);
    progress = ProgressProvider(ProgressStore(storage, log), log);
    await progress.load();
    progress.update((Progress p) => p.copyWith(sessions: sessions));
    now = DateTime.utc(2026, 11, 22, 12);
    adProvider = AdProvider(
      ads: ads,
      consent: consent,
      entitlement: entitlement,
      flags: flags,
      progress: progress,
      log: log,
      clock: () => now,
    );
  }

  tearDown(() {
    adProvider.dispose();
    consent.dispose();
    entitlement.dispose();
    flags.dispose();
    progress.dispose();
  });

  group('ConsentProvider', () {
    test('a launch refresh publishes the answer', () async {
      await build();
      consentPort.next = _allowed;
      await consent.refreshOnLaunch();
      expect(consent.value.refreshed, isTrue);
      expect(consent.value.canRequestAds, isTrue);
      expect(consent.value.privacyOptionsRequired, isTrue);
    });

    test('an offline refresh keeps the saved consent that allows ads', () async {
      await build();
      consentPort.next = _allowed;
      await consent.refreshOnLaunch();
      final ConsentProvider second = ConsentProvider(ConsentTracker(consentPort, storage, log));
      consentPort.failRefresh = true;
      await second.refreshOnLaunch();
      expect(second.value.canRequestAds, isTrue);
      second.dispose();
    });

    test('no saved answer and a failed refresh means no ads', () async {
      await build();
      consentPort.failRefresh = true;
      await consent.refreshOnLaunch();
      expect(consent.value.canRequestAds, isFalse);
      expect(consent.value.refreshed, isTrue);
    });

    test('withdrawing consent in Privacy choices applies at once', () async {
      await build();
      consentPort.next = _allowed;
      await consent.refreshOnLaunch();
      consentPort.optionsResult = _blocked;
      await consent.openPrivacyOptions();
      expect(consent.value.canRequestAds, isFalse);
      expect(consent.value.busy, isFalse);
    });
  });

  group('FlagsProvider', () {
    test('starts at the defaults and takes the fetched flags', () async {
      await build();
      expect(flags.value, RemoteFlags.defaults);
      flagsPort.flags = const RemoteFlags(adsEnabled: false);
      await flags.refresh();
      expect(flags.value.adsEnabled, isFalse);
    });

    test('a failing fetch keeps the current flags', () async {
      await build();
      final FlagsProvider broken = FlagsProvider(_ThrowingFlags(), log);
      await broken.refresh();
      expect(broken.value, RemoteFlags.defaults);
      broken.dispose();
    });
  });

  group('AdProvider', () {
    test('nothing is requested before consent', () async {
      await build();
      await entitlement.start();
      adProvider.requestBanner(360);
      await _settle();
      expect(ads.calls, isEmpty);
      expect(adProvider.value.bannerVisible, isFalse);
      expect(adProvider.value.bannerHeightDp, 0);
    });

    test('after consent and a not-owned answer the SDK starts and the banner loads', () async {
      await build();
      await entitlement.start();
      adProvider.requestBanner(360);
      consentPort.next = _allowed;
      await consent.refreshOnLaunch();
      await _settle();
      expect(ads.calls, containsAll(<String>['initialize', 'banner', 'loadInterstitial', 'loadRewarded']));
      expect(adProvider.value.initialized, isTrue);
      expect(adProvider.value.interstitialReady, isTrue);
      expect(adProvider.value.rewardedReady, isTrue);
    });

    test('the slot has height only while a banner is ready', () async {
      await build();
      await entitlement.start();
      adProvider.requestBanner(360);
      consentPort.next = _allowed;
      await consent.refreshOnLaunch();
      await _settle();
      expect(adProvider.value.bannerVisible, isFalse);
      ads.emitBanner(const BannerState(BannerStatus.loading, 0));
      await _settle();
      expect(adProvider.value.bannerHeightDp, 0);
      ads.emitBanner(const BannerState(BannerStatus.ready, 50));
      await _settle();
      expect(adProvider.value.bannerVisible, isTrue);
      expect(adProvider.value.bannerHeightDp, 50);
      adProvider.setKeyboardOpen(true);
      expect(adProvider.value.bannerVisible, isFalse);
      expect(adProvider.value.bannerHeightDp, 0);
      adProvider.setKeyboardOpen(false);
      expect(adProvider.value.bannerHeightDp, 50);
      ads.emitBanner(BannerState.hidden);
      await _settle();
      expect(adProvider.value.bannerHeightDp, 0);
    });

    test('an owned entitlement removes the banner and stops interstitials', () async {
      await build();
      billing.status = EntitlementStatus.owned;
      await entitlement.start();
      adProvider.requestBanner(360);
      consentPort.next = _allowed;
      await consent.refreshOnLaunch();
      await _settle();
      expect(ads.calls.contains('banner'), isFalse);
      expect(ads.calls.contains('loadInterstitial'), isFalse);
      expect(adProvider.canShowInterstitial, isFalse);
    });

    test('buying while a banner is up disposes it', () async {
      await build();
      await entitlement.start();
      adProvider.requestBanner(360);
      consentPort.next = _allowed;
      await consent.refreshOnLaunch();
      await _settle();
      ads.emitBanner(const BannerState(BannerStatus.ready, 50));
      await _settle();
      billing.emit(EntitlementStatus.owned);
      await _settle();
      expect(ads.calls, contains('disposeBanner'));
      expect(adProvider.value.bannerHeightDp, 0);
    });

    test('withdrawn consent collapses the banner', () async {
      await build();
      await entitlement.start();
      adProvider.requestBanner(360);
      consentPort.next = _allowed;
      await consent.refreshOnLaunch();
      await _settle();
      ads.emitBanner(const BannerState(BannerStatus.ready, 50));
      await _settle();
      consentPort.optionsResult = _blocked;
      await consent.openPrivacyOptions();
      await _settle();
      expect(adProvider.value.bannerVisible, isFalse);
      expect(adProvider.value.interstitialReady, isFalse);
    });

    test('the remote switch turns everything off', () async {
      await build();
      flagsPort.flags = const RemoteFlags(adsEnabled: false);
      await flags.refresh();
      await entitlement.start();
      consentPort.next = _allowed;
      await consent.refreshOnLaunch();
      adProvider.requestBanner(360);
      await _settle();
      expect(ads.calls, isEmpty);
    });

    test('an SDK that fails to start leaves the slot collapsed and does not throw', () async {
      await build();
      ads.initializes = false;
      await entitlement.start();
      adProvider.requestBanner(360);
      consentPort.next = _allowed;
      await consent.refreshOnLaunch();
      await _settle();
      expect(adProvider.value.initialized, isFalse);
      expect(adProvider.value.bannerHeightDp, 0);
      expect(await adProvider.showInterstitial(), isFalse);
      expect(await adProvider.showRewarded(), RewardResult.unavailable);
    });

    test('an interstitial shows once, then waits ten minutes', () async {
      await build();
      await entitlement.start();
      consentPort.next = _allowed;
      await consent.refreshOnLaunch();
      await _settle();
      expect(adProvider.canShowInterstitial, isTrue);
      expect(await adProvider.showInterstitial(), isTrue);
      await _settle();
      expect(adProvider.canShowInterstitial, isFalse);
      now = now.add(const Duration(minutes: 9));
      expect(adProvider.canShowInterstitial, isFalse);
      now = now.add(const Duration(minutes: 1));
      expect(adProvider.canShowInterstitial, isTrue);
    });

    test('no interstitial in the first session', () async {
      await build(sessions: 1);
      await entitlement.start();
      consentPort.next = _allowed;
      await consent.refreshOnLaunch();
      await _settle();
      expect(await adProvider.showInterstitial(), isFalse);
      expect(ads.calls.contains('showInterstitial'), isFalse);
    });

    test('rewarded works after Remove Ads', () async {
      await build();
      billing.status = EntitlementStatus.owned;
      await entitlement.start();
      consentPort.next = _allowed;
      await consent.refreshOnLaunch();
      await _settle();
      expect(await adProvider.showRewarded(), RewardResult.earned);
    });

    test('rewarded is unavailable without consent', () async {
      await build();
      await entitlement.start();
      await _settle();
      expect(await adProvider.showRewarded(), RewardResult.unavailable);
    });
  });
}

final class _ThrowingFlags extends FakeFlags {
  @override
  Future<RemoteFlags> load() async => throw StateError('offline');
}
