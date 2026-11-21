enum NotificationPermission { unknown, granted, denied, deniedForever }

/// Local reminders only; there is no push service.
abstract interface class NotificationPort {
  Future<NotificationPermission> permission();

  /// Asks the system. Called only when the user turns reminders on.
  Future<NotificationPermission> requestPermission();

  /// Schedules one notice every day at [minuteOfDay] (0 to 1439), replacing any
  /// earlier one. [payload] comes back on [taps].
  Future<void> scheduleDaily({
    required int minuteOfDay,
    required String title,
    required String body,
    required String payload,
  });

  Future<void> cancelDaily();

  /// Payloads of notices the user tapped while the app was running.
  Stream<String> get taps;

  /// The payload of the notice that launched the app, if any.
  Future<String?> launchPayload();
}
