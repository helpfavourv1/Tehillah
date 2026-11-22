import 'package:flutter/foundation.dart';
import 'package:tehillah/core/logic/daily_seed.dart';
import 'package:tehillah/core/logic/date_key.dart';
import 'package:tehillah/core/logic/progression_rules.dart';
import 'package:tehillah/core/models/daily_challenge.dart';
import 'package:tehillah/core/models/settings_model.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/core/ports/notification_port.dart';
import 'package:tehillah/providers/progress_provider.dart';
import 'package:tehillah/providers/safe_notifier.dart';
import 'package:tehillah/providers/settings_provider.dart';

enum ReminderOutcome { enabled, denied, deniedForever, failed }

/// Today's Daily Bread and its reminder.
@immutable
final class DailyState {
  const DailyState({
    required this.challenge,
    required this.record,
    required this.streak,
    required this.remindersOn,
    required this.reminderMinuteOfDay,
  });

  final DailyChallenge challenge;

  /// Today's result, or null if today has not been played.
  final DailyRecord? record;

  /// Consecutive days with a result, ending today (or yesterday if today is
  /// still open).
  final int streak;

  final bool remindersOn;
  final int reminderMinuteOfDay;

  bool get completed => record != null;

  @override
  bool operator ==(Object other) =>
      other is DailyState &&
      other.challenge.dateKey == challenge.dateKey &&
      other.record?.dateKey == record?.dateKey &&
      other.record?.won == record?.won &&
      other.record?.goals == record?.goals &&
      other.streak == streak &&
      other.remindersOn == remindersOn &&
      other.reminderMinuteOfDay == reminderMinuteOfDay;

  @override
  int get hashCode => Object.hash(
        challenge.dateKey,
        record?.won,
        record?.goals,
        streak,
        remindersOn,
        reminderMinuteOfDay,
      );
}

/// Daily Bread: the seeded challenge for the device's own day, whether it is
/// done, the streak, and the opt-in reminder. Reminder text is passed in by the
/// caller because it is localized.
final class DailyProvider extends SafeNotifier<DailyState> {
  DailyProvider({
    required ProgressProvider progress,
    required SettingsProvider settings,
    required NotificationPort notifications,
    required LogPort log,
    DateTime Function()? clock,
  })  : _progress = progress,
        _settings = settings,
        _notifications = notifications,
        _log = log,
        _clock = clock ?? DateTime.now,
        super(_derive(progress, settings, (clock ?? DateTime.now)())) {
    _progress.addListener(_sync);
    _settings.addListener(_sync);
  }

  /// The payload carried by the reminder; the router opens Daily Bread for it.
  static const String payload = 'daily_bread';

  final ProgressProvider _progress;
  final SettingsProvider _settings;
  final NotificationPort _notifications;
  final LogPort _log;
  final DateTime Function() _clock;

  static DailyState _derive(ProgressProvider progress, SettingsProvider settings, DateTime now) {
    final DailyChallenge challenge = DailySeed.forDate(now);
    final SettingsModel s = settings.value;
    return DailyState(
      challenge: challenge,
      record: progress.progress.dailyHistory[challenge.dateKey],
      streak: ProgressionRules.currentDailyStreak(progress.progress, DateKey.of(now)),
      remindersOn: s.remindersOn,
      reminderMinuteOfDay: s.reminderMinuteOfDay,
    );
  }

  void _sync() => value = _derive(_progress, _settings, _clock());

  /// Moves to the new day when midnight passes. Call when the app resumes.
  void refreshDay() => _sync();

  /// Asks for notification permission if needed, then schedules the daily
  /// reminder. The setting turns on only when scheduling worked.
  Future<ReminderOutcome> enableReminders({required String title, required String body}) async {
    try {
      NotificationPermission permission = await _notifications.permission();
      if (permission == NotificationPermission.deniedForever) {
        return ReminderOutcome.deniedForever;
      }
      if (permission != NotificationPermission.granted) {
        permission = await _notifications.requestPermission();
      }
      switch (permission) {
        case NotificationPermission.granted:
          await _notifications.scheduleDaily(
            minuteOfDay: _settings.value.reminderMinuteOfDay,
            title: title,
            body: body,
            payload: payload,
          );
          _settings.update((SettingsModel s) => s.copyWith(remindersOn: true));
          return ReminderOutcome.enabled;
        case NotificationPermission.deniedForever:
          return ReminderOutcome.deniedForever;
        case NotificationPermission.denied:
        case NotificationPermission.unknown:
          return ReminderOutcome.denied;
      }
    } on Object catch (error) {
      _log.log(LogLevel.error, 'daily', 'enabling reminders failed: $error');
      return ReminderOutcome.failed;
    }
  }

  Future<void> disableReminders() async {
    try {
      await _notifications.cancelDaily();
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'daily', 'cancelling reminder failed: $error');
    }
    _settings.update((SettingsModel s) => s.copyWith(remindersOn: false));
  }

  /// Changes the reminder time and reschedules if reminders are on.
  Future<void> setReminderTime(int minuteOfDay, {required String title, required String body}) async {
    if (minuteOfDay < 0 || minuteOfDay >= 1440) {
      return;
    }
    _settings.update((SettingsModel s) => s.copyWith(reminderMinuteOfDay: minuteOfDay));
    if (_settings.value.remindersOn) {
      await _reschedule(title, body);
    }
  }

  /// Run on launch (and when the language changes) so the saved reminder
  /// matches the system: rescheduled with current text when permission still
  /// holds, switched off when the player has revoked it.
  Future<void> syncReminder({required String title, required String body}) async {
    if (!_settings.value.remindersOn) {
      return;
    }
    try {
      final NotificationPermission permission = await _notifications.permission();
      if (permission == NotificationPermission.granted) {
        await _reschedule(title, body);
      } else {
        await _notifications.cancelDaily();
        _settings.update((SettingsModel s) => s.copyWith(remindersOn: false));
      }
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'daily', 'reminder sync failed: $error');
    }
  }

  Future<void> _reschedule(String title, String body) async {
    try {
      await _notifications.scheduleDaily(
        minuteOfDay: _settings.value.reminderMinuteOfDay,
        title: title,
        body: body,
        payload: payload,
      );
    } on Object catch (error) {
      _log.log(LogLevel.warning, 'daily', 'reschedule failed: $error');
    }
  }

  @override
  void dispose() {
    _progress.removeListener(_sync);
    _settings.removeListener(_sync);
    super.dispose();
  }
}
