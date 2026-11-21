import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/ports/audio_port.dart';
import 'package:tehillah/core/ports/connectivity_port.dart';
import 'package:tehillah/platform/audio_service.dart';
import 'package:tehillah/platform/connectivity_service.dart';
import 'package:tehillah/platform/notification_service.dart';
import 'package:tehillah/platform/url_service.dart';

void main() {
  group('connectionKindOf', () {
    test('Wi-Fi and Ethernet count as Wi-Fi, even with mobile also active', () {
      expect(connectionKindOf(<ConnectivityResult>[ConnectivityResult.wifi]), ConnectionKind.wifi);
      expect(connectionKindOf(<ConnectivityResult>[ConnectivityResult.ethernet]), ConnectionKind.wifi);
      expect(
        connectionKindOf(<ConnectivityResult>[ConnectivityResult.mobile, ConnectivityResult.wifi]),
        ConnectionKind.wifi,
      );
    });

    test('mobile, offline and other', () {
      expect(connectionKindOf(<ConnectivityResult>[ConnectivityResult.mobile]), ConnectionKind.mobile);
      expect(connectionKindOf(<ConnectivityResult>[]), ConnectionKind.none);
      expect(connectionKindOf(<ConnectivityResult>[ConnectivityResult.none]), ConnectionKind.none);
      expect(connectionKindOf(<ConnectivityResult>[ConnectivityResult.vpn]), ConnectionKind.other);
    });
  });

  group('nextDailyComponents', () {
    test('a time later today is today', () {
      final DateTime next = nextDailyComponents(DateTime(2026, 11, 21, 10, 30), 18 * 60);
      expect((next.year, next.month, next.day, next.hour, next.minute), (2026, 11, 21, 18, 0));
    });

    test('a time already past, or right now, is tomorrow', () {
      final DateTime past = nextDailyComponents(DateTime(2026, 11, 21, 19, 0), 18 * 60);
      expect((past.day, past.hour), (22, 18));
      final DateTime now = nextDailyComponents(DateTime(2026, 11, 21, 18, 0), 18 * 60);
      expect(now.day, 22);
    });

    test('rolls over the end of a month and a year', () {
      final DateTime month = nextDailyComponents(DateTime(2026, 11, 30, 23, 0), 60);
      expect((month.month, month.day), (12, 1));
      final DateTime year = nextDailyComponents(DateTime(2026, 12, 31, 23, 0), 0);
      expect((year.year, year.month, year.day), (2027, 1, 1));
    });

    test('midnight and the last minute are valid; out of range is rejected', () {
      expect(nextDailyComponents(DateTime(2026, 11, 21, 12), 1439).hour, 23);
      expect(() => nextDailyComponents(DateTime(2026, 11, 21), -1), throwsArgumentError);
      expect(() => nextDailyComponents(DateTime(2026, 11, 21), 1440), throwsArgumentError);
    });
  });

  group('url service', () {
    test('mail links encode spaces as %20 and keep the address readable', () {
      final Uri uri = buildMailUri(to: 'a@b.co', subject: 'Tehillah Soccer report', body: 'line 1\nline 2 & more');
      expect(
        uri.toString(),
        'mailto:a@b.co?subject=Tehillah%20Soccer%20report&body=line%201%0Aline%202%20%26%20more',
      );
    });

    test('a mail link without subject or body is just the address', () {
      expect(buildMailUri(to: 'a@b.co').toString(), 'mailto:a@b.co');
    });

    test('a bad address is rejected', () {
      for (final String bad in <String>['', 'nope', 'a@b', 'a b@c.de', 'a@b.co,x@y.zz']) {
        expect(() => buildMailUri(to: bad), throwsArgumentError, reason: bad);
      }
    });

    test('only http and https links are opened', () async {
      final List<Uri> launched = <Uri>[];
      final UrlService service = UrlService(launcher: (Uri u) async {
        launched.add(u);
        return true;
      });
      expect(await service.openLink('https://tehillah.helpfavourv1.workers.dev/privacy'), isTrue);
      expect(await service.openLink('javascript:alert(1)'), isFalse);
      expect(await service.openLink('file:///etc/passwd'), isFalse);
      expect(await service.openLink('not a url'), isFalse);
      expect(await service.openLink('https://'), isFalse);
      expect(launched.length, 1);
    });

    test('a launcher that fails gives false, never throws', () async {
      final UrlService service = UrlService(launcher: (Uri u) async => throw StateError('no app'));
      expect(await service.openMail(to: 'a@b.co'), isFalse);
      expect(await service.openLink('https://example.com'), isFalse);
    });
  });

  test('every sound effect has its own asset', () {
    final Set<String> assets = <String>{for (final SoundEffect e in SoundEffect.values) AudioService.assetFor(e)};
    expect(assets.length, SoundEffect.values.length);
    expect(AudioService.assetFor(SoundEffect.goal), 'audio/goal.wav');
  });
}
