import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/ads/consent_tracker.dart';
import 'package:tehillah/core/models/remote_flags.dart';
import 'package:tehillah/core/ports/consent_port.dart';
import 'package:tehillah/core/ports/pack_port.dart';

import '../fakes/fake_ports.dart';
import '../fakes/fake_storage.dart';

const ConsentSnapshot _allowed = ConsentSnapshot(
  status: ConsentStatus.obtained,
  canRequestAds: true,
  privacyOptionsRequired: true,
);
const ConsentSnapshot _declined = ConsentSnapshot(
  status: ConsentStatus.obtained,
  canRequestAds: false,
  privacyOptionsRequired: true,
);
const ConsentSnapshot _needsAnswer = ConsentSnapshot(
  status: ConsentStatus.required,
  canRequestAds: false,
  privacyOptionsRequired: false,
);
const ConsentSnapshot _outsideRegion = ConsentSnapshot(
  status: ConsentStatus.notRequired,
  canRequestAds: true,
  privacyOptionsRequired: false,
);

void main() {
  group('ConsentTracker (consent matrix)', () {
    late FakeConsent port;
    late FakeStorage storage;
    late ConsentTracker tracker;

    setUp(() {
      port = FakeConsent();
      storage = FakeStorage();
      tracker = ConsentTracker(port, storage, FakeLog());
    });

    test('outside regulated regions ads may start with no form', () async {
      port.next = _outsideRegion;
      expect((await tracker.refresh()).canRequestAds, isTrue);
    });

    test('a region that needs an answer allows nothing until it is given', () async {
      port.next = _needsAnswer;
      expect((await tracker.refresh()).canRequestAds, isFalse);
    });

    test('a completed refresh that declines is honored', () async {
      port.next = _allowed;
      await tracker.refresh();
      port.next = _declined;
      expect(await tracker.refresh(), _declined);
    });

    test('an offline refresh keeps saved consent that allows ads', () async {
      port.next = _allowed;
      await tracker.refresh();
      port.failRefresh = true;
      final ConsentSnapshot kept = await ConsentTracker(port, storage, FakeLog()).refresh();
      expect(kept, _allowed);
    });

    test('an offline refresh never turns a saved decline into permission', () async {
      port.next = _declined;
      await tracker.refresh();
      port.failRefresh = true;
      expect((await tracker.refresh()).canRequestAds, isFalse);
    });

    test('with no saved answer a failed refresh uses the platform state', () async {
      port.failRefresh = true;
      port.stored = _allowed;
      expect(await tracker.refresh(), _allowed);
    });

    test('with nothing saved and nothing from the platform, ads stay off', () async {
      port.failRefresh = true;
      port.failCurrent = true;
      expect(await tracker.refresh(), ConsentSnapshot.unknown);
    });

    test('a damaged saved record reads as unknown, not as permission', () async {
      storage.values[ConsentTracker.storageKey] = '{"status":"obtained"';
      port.failRefresh = true;
      port.failCurrent = true;
      expect((await tracker.refresh()).canRequestAds, isFalse);
    });

    test('withdrawal in privacy options applies at once and is saved', () async {
      port.next = _allowed;
      await tracker.refresh();
      port.optionsResult = _declined;
      expect(await tracker.openPrivacyOptions(), _declined);
      port.failRefresh = true;
      expect(await ConsentTracker(port, storage, FakeLog()).refresh(), _declined);
    });

    test('saving failure does not break the refresh', () async {
      storage.failWrites = true;
      port.next = _allowed;
      expect(await tracker.refresh(), _allowed);
    });
  });

  group('ConsentSnapshot', () {
    test('round trips and rejects odd input', () {
      expect(ConsentSnapshot.decode(_allowed.encode()), _allowed);
      expect(ConsentSnapshot.decode(null), ConsentSnapshot.unknown);
      expect(ConsentSnapshot.decode('[]'), ConsentSnapshot.unknown);
      expect(
        ConsentSnapshot.decode('{"status":"maybe","canRequestAds":true,"privacyOptionsRequired":false}'),
        ConsentSnapshot.unknown,
      );
    });
  });

  group('RemoteFlags', () {
    test('defaults are on', () {
      expect(RemoteFlags.decode(null), RemoteFlags.defaults);
      expect(RemoteFlags.decode('garbage'), RemoteFlags.defaults);
    });

    test('reads each flag and ignores wrongly typed ones', () {
      final RemoteFlags f =
          RemoteFlags.decode('{"adsEnabled":false,"rewardedEnabled":"no","readerDownloadEnabled":false}');
      expect(f.adsEnabled, isFalse);
      expect(f.rewardedEnabled, isTrue);
      expect(f.readerDownloadEnabled, isFalse);
      expect(f.interstitialsEnabled, isTrue);
    });

    test('round trips', () {
      const RemoteFlags f = RemoteFlags(interstitialsEnabled: false);
      expect(RemoteFlags.decode(f.encode()), f);
    });
  });

  test('PackProgress fraction is clamped and safe for unknown size', () {
    expect(const PackProgress(50, 200).fraction, 0.25);
    expect(const PackProgress(5, 0).fraction, 0);
    expect(const PackProgress(300, 200).fraction, 1);
  });
}
