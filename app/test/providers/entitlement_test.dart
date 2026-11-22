import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/ports/billing_port.dart';
import 'package:tehillah/providers/entitlement_provider.dart';

import '../fakes/fake_ports.dart';
import '../fakes/fake_storage.dart';

final class _RestoringBilling extends FakeBilling {
  EntitlementStatus? answer;
  bool throwOnRestore = false;
  bool throwOnInit = false;
  bool throwOnBuy = false;

  @override
  Future<void> initialize() async {
    if (throwOnInit) {
      throw StateError('store down');
    }
  }

  @override
  Future<PurchaseOutcome> buyRemoveAds() async {
    if (throwOnBuy) {
      throw StateError('boom');
    }
    return super.buyRemoveAds();
  }

  @override
  Future<void> restore() async {
    if (throwOnRestore) {
      throw StateError('boom');
    }
    final EntitlementStatus? a = answer;
    if (a != null) {
      scheduleMicrotask(() => emit(a));
    }
  }
}

void main() {
  late _RestoringBilling billing;
  late FakeLog log;
  late EntitlementProvider entitlement;

  setUp(() {
    billing = _RestoringBilling();
    log = FakeLog();
    entitlement = EntitlementProvider(billing, log, restoreTimeout: const Duration(milliseconds: 50));
  });

  tearDown(() => entitlement.dispose());

  test('before start nothing is owned and ads are not removed', () {
    expect(entitlement.value.status, EntitlementStatus.unknown);
    expect(entitlement.value.adsRemoved, isFalse);
  });

  test('start reads the owned state and the price', () async {
    billing.status = EntitlementStatus.owned;
    await entitlement.start();
    expect(entitlement.value.adsRemoved, isTrue);
    expect(entitlement.value.priceLabel, '\$2.99');
  });

  test('not owned keeps ads', () async {
    await entitlement.start();
    expect(entitlement.value.status, EntitlementStatus.notOwned);
    expect(entitlement.value.adsRemoved, isFalse);
  });

  test('a billing failure on start leaves the status unknown and is logged', () async {
    billing.throwOnInit = true;
    await entitlement.start();
    expect(entitlement.value.status, EntitlementStatus.unknown);
    expect(log.lines.any((String l) => l.contains('billing unavailable')), isTrue);
  });

  test('a purchase shows pending, and only the store event confirms ownership', () async {
    await entitlement.start();
    expect(await entitlement.buy(), PurchaseOutcome.started);
    expect(entitlement.value.status, EntitlementStatus.pending);
    expect(entitlement.value.adsRemoved, isFalse);
    billing.emit(EntitlementStatus.owned);
    await Future<void>.delayed(Duration.zero);
    expect(entitlement.value.adsRemoved, isTrue);
  });

  test('a cancelled purchase changes nothing', () async {
    await entitlement.start();
    billing.buyOutcome = PurchaseOutcome.cancelled;
    expect(await entitlement.buy(), PurchaseOutcome.cancelled);
    expect(entitlement.value.status, EntitlementStatus.notOwned);
  });

  test('a purchase that throws is reported as failed', () async {
    await entitlement.start();
    billing.throwOnBuy = true;
    expect(await entitlement.buy(), PurchaseOutcome.failed);
    expect(entitlement.value.status, EntitlementStatus.notOwned);
  });

  test('restore shows progress and ends when the store answers', () async {
    await entitlement.start();
    billing.answer = EntitlementStatus.owned;
    final Future<void> done = entitlement.restore();
    expect(entitlement.value.restoring, isTrue);
    await done;
    expect(entitlement.value.restoring, isFalse);
    expect(entitlement.value.adsRemoved, isTrue);
  });

  test('restore stops showing progress when the store never answers', () async {
    await entitlement.start();
    await entitlement.restore();
    expect(entitlement.value.restoring, isFalse);
    expect(entitlement.value.status, EntitlementStatus.notOwned);
  });

  test('restore that throws ends cleanly', () async {
    await entitlement.start();
    billing.throwOnRestore = true;
    await entitlement.restore();
    expect(entitlement.value.restoring, isFalse);
    expect(log.lines.any((String l) => l.contains('restore failed')), isTrue);
  });

  test('a refund arriving later removes ownership', () async {
    billing.status = EntitlementStatus.owned;
    await entitlement.start();
    billing.emit(EntitlementStatus.notOwned);
    await Future<void>.delayed(Duration.zero);
    expect(entitlement.value.adsRemoved, isFalse);
  });

  test('events after dispose are ignored', () async {
    await entitlement.start();
    entitlement.dispose();
    billing.emit(EntitlementStatus.owned);
    await Future<void>.delayed(Duration.zero);
    expect(entitlement.isDisposed, isTrue);
  });
}
