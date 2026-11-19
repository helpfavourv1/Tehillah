import 'package:flutter_test/flutter_test.dart';

import 'package:tehillah/core/errors/app_error.dart';

void main() {
  test('every class maps to its defined treatment', () {
    const List<(AppError, bool, bool, ErrorCause, ErrorTreatment)> table =
        <(AppError, bool, bool, ErrorCause, ErrorTreatment)>[
      (
        UserRecoverableError('pack.declined', 'declined'),
        true,
        true,
        ErrorCause.user,
        ErrorTreatment.inlineRetry,
      ),
      (
        SystemRecoverableError('pack.hash_mismatch', 'mismatch'),
        true,
        true,
        ErrorCause.system,
        ErrorTreatment.inlineRetry,
      ),
      (
        ThirdPartyDegradedError('ads.init_failed', 'failed'),
        true,
        false,
        ErrorCause.thirdParty,
        ErrorTreatment.silentCollapse,
      ),
      (
        StorageDegradedError('storage.write_failed', 'failed'),
        true,
        true,
        ErrorCause.system,
        ErrorTreatment.warningBanner,
      ),
      (
        FatalError('unexpected', 'boom'),
        false,
        false,
        ErrorCause.system,
        ErrorTreatment.fullScreenFallback,
      ),
    ];
    for (final (
      AppError e,
      bool recoverable,
      bool retriable,
      ErrorCause cause,
      ErrorTreatment treatment,
    ) in table) {
      expect(e.recoverable, recoverable, reason: e.code);
      expect(e.retriable, retriable, reason: e.code);
      expect(e.errorCause, cause, reason: e.code);
      expect(e.treatment, treatment, reason: e.code);
    }
  });

  test('classify keeps an AppError and wraps anything else as fatal', () {
    const AppError original = StorageDegradedError('s', 'm');
    expect(identical(AppError.classify(original), original), isTrue);

    final Object thrown = StateError('bad state');
    final AppError wrapped = AppError.classify(thrown);
    expect(wrapped, isA<FatalError>());
    expect(wrapped.cause, thrown);
    expect(wrapped.code, 'unexpected');
    expect(wrapped.treatment, ErrorTreatment.fullScreenFallback);
  });

  test('toString names the class and code', () {
    expect(
      const FatalError('x.y', 'message').toString(),
      'FatalError(x.y): message',
    );
  });
}
