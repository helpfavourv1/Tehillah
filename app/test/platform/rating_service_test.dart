import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/platform/rating_service.dart';

import '../fakes/fake_storage.dart';

void main() {
  test('asks the store when the dialog is available', () async {
    int asked = 0;
    final RatingService s = RatingService(
      isAvailable: () async => true,
      request: () async => asked++,
    );
    expect(await s.requestReview(), isTrue);
    expect(asked, 1);
  });

  test('does nothing when the dialog is not available', () async {
    int asked = 0;
    final RatingService s = RatingService(
      isAvailable: () async => false,
      request: () async => asked++,
    );
    expect(await s.requestReview(), isFalse);
    expect(asked, 0);
  });

  test('a failing plugin is logged and answered with false', () async {
    final FakeLog log = FakeLog();
    final RatingService s = RatingService(
      isAvailable: () async => true,
      request: () async => throw StateError('boom'),
      log: log,
    );
    expect(await s.requestReview(), isFalse);
    expect(log.lines.single, contains('rating'));
  });
}
