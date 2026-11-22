import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as ads;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:tehillah/core/config/app_config.dart';
import 'package:tehillah/core/models/remote_flags.dart';
import 'package:tehillah/core/ports/billing_port.dart';
import 'package:tehillah/core/ports/consent_port.dart';
import 'package:tehillah/platform/ad_unit_ids.dart';
import 'package:tehillah/platform/billing_service.dart';
import 'package:tehillah/platform/consent_service.dart';
import 'package:tehillah/platform/flags_service.dart';

import '../fakes/fake_storage.dart';

const String _id = AppConfig.removeAdsProductId;

PurchaseEvent _e(PurchaseStatus s, {String id = _id}) => (productId: id, status: s);

void main() {
  group('AppConfig', () {
    test('identifiers agree with each other', () {
      expect(AppConfig.removeAdsProductId, startsWith('${AppConfig.applicationId}.'));
      for (final String url in <String>[
        AppConfig.manifestUrl,
        AppConfig.flagsUrl,
        AppConfig.privacyUrl,
        AppConfig.supportUrl,
      ]) {
        expect(url, startsWith('https://'));
        expect(url, startsWith(AppConfig.siteOrigin));
      }
      expect(AppConfig.siteOrigin.endsWith('/'), isFalse);
    });
  });

  group('AdUnitIds', () {
    test('are well-formed Google sample units while production IDs are not supplied', () {
      expect(AdUnitIds.production, isFalse);
      final RegExp format = RegExp(r'^ca-app-pub-3940256099942544/\d{10}$');
      expect(AdUnitIds.all.length, 6);
      expect(AdUnitIds.all.toSet().length, 6);
      for (final String id in AdUnitIds.all) {
        expect(format.hasMatch(id), isTrue, reason: id);
      }
      expect(AdUnitIds.banner, isNot(AdUnitIds.interstitial));
      expect(AdUnitIds.interstitial, isNot(AdUnitIds.rewarded));
    });
  });

  group('consentStatusFrom', () {
    test('maps every platform status', () {
      expect(consentStatusFrom(ads.ConsentStatus.notRequired), ConsentStatus.notRequired);
      expect(consentStatusFrom(ads.ConsentStatus.obtained), ConsentStatus.obtained);
      expect(consentStatusFrom(ads.ConsentStatus.required), ConsentStatus.required);
      expect(consentStatusFrom(ads.ConsentStatus.unknown), ConsentStatus.unknown);
    });
  });

  group('entitlementAfter', () {
    EntitlementStatus after(EntitlementStatus current, List<PurchaseEvent> events, {bool restore = false}) =>
        entitlementAfter(current, events, productId: _id, restoreInFlight: restore);

    test('purchased and restored mean owned', () {
      expect(after(EntitlementStatus.unknown, <PurchaseEvent>[_e(PurchaseStatus.purchased)]), EntitlementStatus.owned);
      expect(after(EntitlementStatus.notOwned, <PurchaseEvent>[_e(PurchaseStatus.restored)]), EntitlementStatus.owned);
    });

    test('pending shows pending but never downgrades an owned purchase', () {
      expect(after(EntitlementStatus.notOwned, <PurchaseEvent>[_e(PurchaseStatus.pending)]), EntitlementStatus.pending);
      expect(after(EntitlementStatus.owned, <PurchaseEvent>[_e(PurchaseStatus.pending)]), EntitlementStatus.owned);
    });

    test('a cancelled or failed pending purchase falls back to not owned', () {
      expect(after(EntitlementStatus.pending, <PurchaseEvent>[_e(PurchaseStatus.canceled)]), EntitlementStatus.notOwned);
      expect(after(EntitlementStatus.pending, <PurchaseEvent>[_e(PurchaseStatus.error)]), EntitlementStatus.notOwned);
    });

    test('a cancel or error never takes away something already owned', () {
      expect(after(EntitlementStatus.owned, <PurchaseEvent>[_e(PurchaseStatus.canceled)]), EntitlementStatus.owned);
      expect(after(EntitlementStatus.owned, <PurchaseEvent>[_e(PurchaseStatus.error)]), EntitlementStatus.owned);
    });

    test('an empty answer to our own restore means the store holds no purchase', () {
      expect(after(EntitlementStatus.owned, <PurchaseEvent>[], restore: true), EntitlementStatus.notOwned);
      expect(after(EntitlementStatus.owned, <PurchaseEvent>[]), EntitlementStatus.owned);
    });

    test('other products change nothing', () {
      expect(
        after(EntitlementStatus.notOwned, <PurchaseEvent>[_e(PurchaseStatus.purchased, id: 'other')]),
        EntitlementStatus.notOwned,
      );
    });

    test('one good event wins over an error in the same batch', () {
      expect(
        after(EntitlementStatus.unknown, <PurchaseEvent>[_e(PurchaseStatus.error), _e(PurchaseStatus.restored)]),
        EntitlementStatus.owned,
      );
    });
  });

  group('FlagsService', () {
    late FakeStorage storage;

    setUp(() => storage = FakeStorage());

    FlagsService serviceFor(Future<String> Function(Uri) fetch) => FlagsService(storage, fetcher: fetch);

    test('reads and caches a good answer', () async {
      final FlagsService service = serviceFor((Uri u) async => '{"adsEnabled":false}');
      expect((await service.load()).adsEnabled, isFalse);
      expect(storage.values[FlagsService.cacheKey], '{"adsEnabled":false}');
    });

    test('offline uses the last good answer', () async {
      await serviceFor((Uri u) async => '{"adsEnabled":false}').load();
      final RemoteFlags flags = await serviceFor((Uri u) async => throw TimeoutException('slow')).load();
      expect(flags.adsEnabled, isFalse);
    });

    test('offline with nothing cached gives the defaults', () async {
      expect(await serviceFor((Uri u) async => throw StateError('offline')).load(), RemoteFlags.defaults);
    });

    test('a login page never overwrites a good cache', () async {
      await serviceFor((Uri u) async => '{"adsEnabled":false}').load();
      final RemoteFlags flags = await serviceFor((Uri u) async => '<html>Sign in to Wi-Fi</html>').load();
      expect(flags.adsEnabled, isFalse);
      expect(storage.values[FlagsService.cacheKey], '{"adsEnabled":false}');
    });

    test('a JSON answer that is not an object is ignored', () async {
      final RemoteFlags flags = await serviceFor((Uri u) async => '[1,2]').load();
      expect(flags, RemoteFlags.defaults);
      expect(storage.values.containsKey(FlagsService.cacheKey), isFalse);
    });

    test('a broken cache does not break loading', () async {
      storage.values[FlagsService.cacheKey] = 'garbage';
      expect(await serviceFor((Uri u) async => throw StateError('offline')).load(), RemoteFlags.defaults);
    });

    test('the shipped flags file is valid and everything is on', () {
      expect(jsonDecode('{"adsEnabled":true}'), isA<Map<String, Object?>>());
    });
  });
}
