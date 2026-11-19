/// How an error is shown to the user.
enum ErrorTreatment {
  /// A message next to the failed action with a retry button.
  inlineRetry,

  /// The affected slot disappears; nothing is shown and nothing blocks.
  silentCollapse,

  /// A visible warning banner; the app keeps working from memory.
  warningBanner,

  /// A full-screen fallback with a retry button and a report link.
  fullScreenFallback,
}

/// Who or what caused the error.
enum ErrorCause { user, system, thirdParty }

/// The error taxonomy. Every error in the app is one of these classes, and each
/// class has exactly one defined treatment.
sealed class AppError implements Exception {
  const AppError(this.code, this.message, {this.cause});

  /// Short stable identifier, for example `pack.hash_mismatch`.
  final String code;

  /// English text for the local log. Never shown to the user directly.
  final String message;

  /// The underlying exception, when there is one.
  final Object? cause;

  /// Whether the app can carry on after this error.
  bool get recoverable;

  /// Whether trying the same action again can succeed.
  bool get retriable;

  ErrorCause get errorCause;

  ErrorTreatment get treatment;

  /// Classifies anything that was thrown. Unknown exceptions are fatal.
  static AppError classify(Object error, {String code = 'unexpected'}) {
    if (error is AppError) {
      return error;
    }
    return FatalError(code, error.toString(), cause: error);
  }

  @override
  String toString() => '$runtimeType($code): $message';
}

/// Recoverable and retriable, caused by the user's situation: a declined
/// download or no connection.
final class UserRecoverableError extends AppError {
  const UserRecoverableError(super.code, super.message, {super.cause});

  @override
  bool get recoverable => true;

  @override
  bool get retriable => true;

  @override
  ErrorCause get errorCause => ErrorCause.user;

  @override
  ErrorTreatment get treatment => ErrorTreatment.inlineRetry;
}

/// Recoverable and retriable, caused by the system: a hash mismatch or an
/// interrupted download.
final class SystemRecoverableError extends AppError {
  const SystemRecoverableError(super.code, super.message, {super.cause});

  @override
  bool get recoverable => true;

  @override
  bool get retriable => true;

  @override
  ErrorCause get errorCause => ErrorCause.system;

  @override
  ErrorTreatment get treatment => ErrorTreatment.inlineRetry;
}

/// A third-party component failed, for example the ad SDK. The slot collapses
/// and the app never blocks.
final class ThirdPartyDegradedError extends AppError {
  const ThirdPartyDegradedError(super.code, super.message, {super.cause});

  @override
  bool get recoverable => true;

  @override
  bool get retriable => false;

  @override
  ErrorCause get errorCause => ErrorCause.thirdParty;

  @override
  ErrorTreatment get treatment => ErrorTreatment.silentCollapse;
}

/// Saving failed. The app keeps working from memory and shows a warning.
final class StorageDegradedError extends AppError {
  const StorageDegradedError(super.code, super.message, {super.cause});

  @override
  bool get recoverable => true;

  @override
  bool get retriable => true;

  @override
  ErrorCause get errorCause => ErrorCause.system;

  @override
  ErrorTreatment get treatment => ErrorTreatment.warningBanner;
}

/// An unexpected failure. Neither recoverable nor retriable in place; the
/// global handler shows the full-screen fallback.
final class FatalError extends AppError {
  const FatalError(super.code, super.message, {super.cause});

  @override
  bool get recoverable => false;

  @override
  bool get retriable => false;

  @override
  ErrorCause get errorCause => ErrorCause.system;

  @override
  ErrorTreatment get treatment => ErrorTreatment.fullScreenFallback;
}
