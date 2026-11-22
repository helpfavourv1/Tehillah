import 'dart:async';

import 'package:tehillah/core/models/bible_pack.dart';
import 'package:tehillah/core/models/pack_manifest.dart';
import 'package:tehillah/core/models/remote_flags.dart';
import 'package:tehillah/core/ports/ads_port.dart';
import 'package:tehillah/core/ports/audio_port.dart';
import 'package:tehillah/core/ports/billing_port.dart';
import 'package:tehillah/core/ports/connectivity_port.dart';
import 'package:tehillah/core/ports/consent_port.dart';
import 'package:tehillah/core/ports/flags_port.dart';
import 'package:tehillah/core/ports/haptics_port.dart';
import 'package:tehillah/core/ports/notification_port.dart';
import 'package:tehillah/core/ports/pack_port.dart';
import 'package:tehillah/core/ports/share_port.dart';
import 'package:tehillah/core/ports/url_port.dart';

final class FakeConsent implements ConsentPort {
  ConsentSnapshot next = ConsentSnapshot.unknown;
  ConsentSnapshot stored = ConsentSnapshot.unknown;
  ConsentSnapshot optionsResult = ConsentSnapshot.unknown;
  bool failRefresh = false;
  bool failCurrent = false;
  int refreshes = 0;

  @override
  Future<ConsentSnapshot> refresh() async {
    refreshes++;
    if (failRefresh) {
      throw StateError('offline');
    }
    return next;
  }

  @override
  Future<ConsentSnapshot> current() async {
    if (failCurrent) {
      throw StateError('no state');
    }
    return stored;
  }

  @override
  Future<ConsentSnapshot> showPrivacyOptions() async => optionsResult;
}

final class FakeAds implements AdsPort {
  bool initializes = true;
  final StreamController<BannerState> _banner = StreamController<BannerState>.broadcast();
  final List<String> calls = <String>[];

  void emitBanner(BannerState state) => _banner.add(state);

  @override
  Future<bool> initialize() async {
    calls.add('initialize');
    return initializes;
  }

  @override
  Future<void> loadBanner({required int widthDp}) async => calls.add('banner');

  @override
  Stream<BannerState> get bannerState => _banner.stream;

  @override
  void disposeBanner() => calls.add('disposeBanner');

  @override
  Future<bool> loadInterstitial() async {
    calls.add('loadInterstitial');
    return initializes;
  }

  @override
  Future<bool> showInterstitial() async {
    calls.add('showInterstitial');
    return initializes;
  }

  @override
  Future<bool> loadRewarded() async {
    calls.add('loadRewarded');
    return initializes;
  }

  @override
  Future<RewardResult> showRewarded() async {
    calls.add('showRewarded');
    return initializes ? RewardResult.earned : RewardResult.unavailable;
  }
}

class FakeBilling implements BillingPort {
  EntitlementStatus status = EntitlementStatus.notOwned;
  PurchaseOutcome buyOutcome = PurchaseOutcome.started;
  final StreamController<EntitlementStatus> _changes =
      StreamController<EntitlementStatus>.broadcast();

  void emit(EntitlementStatus value) {
    status = value;
    _changes.add(value);
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> priceLabel() async => '\$2.99';

  @override
  Future<PurchaseOutcome> buyRemoveAds() async => buyOutcome;

  @override
  Future<void> restore() async {}

  @override
  Future<EntitlementStatus> currentEntitlement() async => status;

  @override
  Stream<EntitlementStatus> get entitlementChanges => _changes.stream;
}

class FakeNotifications implements NotificationPort {
  NotificationPermission state = NotificationPermission.unknown;
  NotificationPermission onRequest = NotificationPermission.granted;
  int? scheduledMinute;
  String? launch;
  final StreamController<String> _taps = StreamController<String>.broadcast();

  void tap(String payload) => _taps.add(payload);

  @override
  Future<NotificationPermission> permission() async => state;

  @override
  Future<NotificationPermission> requestPermission() async => state = onRequest;

  @override
  Future<void> scheduleDaily({
    required int minuteOfDay,
    required String title,
    required String body,
    required String payload,
  }) async =>
      scheduledMinute = minuteOfDay;

  @override
  Future<void> cancelDaily() async => scheduledMinute = null;

  @override
  Stream<String> get taps => _taps.stream;

  @override
  Future<String?> launchPayload() async => launch;
}

final class FakeAudio implements AudioPort {
  final List<SoundEffect> played = <SoundEffect>[];
  bool soundEnabled = true;
  bool musicEnabled = true;

  @override
  Future<void> preload() async {}

  @override
  Future<void> play(SoundEffect effect) async {
    if (soundEnabled) {
      played.add(effect);
    }
  }

  @override
  Future<void> startMenuLoop() async {}

  @override
  Future<void> stopMenuLoop() async {}

  @override
  void setSoundEnabled({required bool enabled}) => soundEnabled = enabled;

  @override
  void setMusicEnabled({required bool enabled}) => musicEnabled = enabled;

  @override
  Future<void> dispose() async {}
}

final class FakeHaptics implements HapticsPort {
  final List<HapticKind> played = <HapticKind>[];
  bool enabled = true;

  @override
  void setEnabled({required bool enabled}) => this.enabled = enabled;

  @override
  Future<void> play(HapticKind kind) async {
    if (enabled) {
      played.add(kind);
    }
  }
}

final class FakeShare implements SharePort {
  final List<String> shared = <String>[];
  bool works = true;

  @override
  Future<bool> shareText(String text, {String? subject}) async {
    shared.add(text);
    return works;
  }
}

final class FakeConnectivity implements ConnectivityPort {
  ConnectionKind kind = ConnectionKind.wifi;
  final StreamController<ConnectionKind> _changes = StreamController<ConnectionKind>.broadcast();

  void change(ConnectionKind value) {
    kind = value;
    _changes.add(value);
  }

  @override
  Future<ConnectionKind> current() async => kind;

  @override
  Stream<ConnectionKind> get changes => _changes.stream;
}

final class FakeUrl implements UrlPort {
  final List<String> opened = <String>[];

  @override
  Future<bool> openMail({required String to, String? subject, String? body}) async {
    opened.add('mailto:$to');
    return true;
  }

  @override
  Future<bool> openLink(String url) async {
    opened.add(url);
    return true;
  }
}

class FakeFlags implements FlagsPort {
  RemoteFlags flags = RemoteFlags.defaults;

  @override
  Future<RemoteFlags> load() async => flags;
}

final class FakePacks implements PackPort {
  PackManifest? manifest;
  final Map<String, BiblePack> installed = <String, BiblePack>{};
  final Map<String, String> notices = <String, String>{};
  Object? downloadError;

  @override
  Future<PackManifest> fetchManifest() async {
    final PackManifest? m = manifest;
    if (m == null) {
      throw StateError('no manifest');
    }
    return m;
  }

  @override
  Future<Set<String>> installedLanguages() async => installed.keys.toSet();

  @override
  Stream<PackProgress> download(PackManifestEntry entry) async* {
    yield const PackProgress(0, 100);
    final Object? error = downloadError;
    if (error != null) {
      throw error;
    }
    yield const PackProgress(100, 100);
  }

  @override
  Future<BiblePack?> load(String language) async => installed[language];

  @override
  Future<String?> readNotice(String language) async => notices[language];

  @override
  Future<void> delete(String language) async {
    installed.remove(language);
    notices.remove(language);
  }
}
