import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:tehillah/core/ports/log_port.dart';
import 'package:tehillah/core/ports/notification_port.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// The wall-clock date and time of the next daily reminder. Only the year,
/// month, day, hour and minute of the result are meaningful: they are the
/// device's local time, and the caller builds the real zoned time from them.
/// A time that has already passed today gives tomorrow.
DateTime nextDailyComponents(DateTime now, int minuteOfDay) {
  if (minuteOfDay < 0 || minuteOfDay > 1439) {
    throw ArgumentError.value(minuteOfDay, 'minuteOfDay', 'must be 0 to 1439');
  }
  final DateTime today =
      DateTime.utc(now.year, now.month, now.day, minuteOfDay ~/ 60, minuteOfDay % 60);
  final DateTime nowMark = DateTime.utc(now.year, now.month, now.day, now.hour, now.minute);
  return today.isAfter(nowMark) ? today : today.add(const Duration(days: 1));
}

/// Daily Bread reminders: one local notification a day, no push service.
/// Android reminders are inexact (they may arrive a few minutes late), which
/// avoids the exact-alarm permission a reminder does not need.
final class NotificationService implements NotificationPort {
  NotificationService({FlutterLocalNotificationsPlugin? plugin, LogPort? log})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
        _log = log;

  static const int dailyId = 1001;

  final FlutterLocalNotificationsPlugin _plugin;
  final LogPort? _log;
  final StreamController<String> _taps = StreamController<String>.broadcast();
  Future<void>? _starting;
  bool _asked = false;
  NotificationPermission _lastIos = NotificationPermission.unknown;

  Future<void> _ensureReady() => _starting ??= _start();

  Future<void> _start() async {
    tz_data.initializeTimeZones();
    try {
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } on Object catch (error) {
      _log?.log(LogLevel.warning, 'notifications', 'time zone not found, using UTC: $error');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final String? payload = response.payload;
        if (payload != null) {
          _taps.add(payload);
        }
      },
    );
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => defaultTargetPlatform == TargetPlatform.android
      ? _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      : null;

  IOSFlutterLocalNotificationsPlugin? get _ios => defaultTargetPlatform == TargetPlatform.iOS
      ? _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
      : null;

  @override
  Future<NotificationPermission> permission() async {
    try {
      await _ensureReady();
      final AndroidFlutterLocalNotificationsPlugin? android = _android;
      if (android != null) {
        final bool? enabled = await android.areNotificationsEnabled();
        if (enabled ?? false) {
          return NotificationPermission.granted;
        }
        return _asked ? NotificationPermission.denied : NotificationPermission.unknown;
      }
      return _lastIos;
    } on Object catch (error) {
      _log?.log(LogLevel.warning, 'notifications', 'permission check failed: $error');
      return NotificationPermission.unknown;
    }
  }

  @override
  Future<NotificationPermission> requestPermission() async {
    try {
      await _ensureReady();
      _asked = true;
      bool? granted;
      final AndroidFlutterLocalNotificationsPlugin? android = _android;
      final IOSFlutterLocalNotificationsPlugin? ios = _ios;
      if (android != null) {
        granted = await android.requestNotificationsPermission();
      } else if (ios != null) {
        granted = await ios.requestPermissions(alert: true, sound: true);
        _lastIos = (granted ?? false) ? NotificationPermission.granted : NotificationPermission.denied;
        return _lastIos;
      }
      return (granted ?? false) ? NotificationPermission.granted : NotificationPermission.denied;
    } on Object catch (error) {
      _log?.log(LogLevel.warning, 'notifications', 'permission request failed: $error');
      return NotificationPermission.denied;
    }
  }

  @override
  Future<void> scheduleDaily({
    required int minuteOfDay,
    required String title,
    required String body,
    required String payload,
  }) async {
    await _ensureReady();
    await cancelDaily();
    final DateTime at = nextDailyComponents(tz.TZDateTime.now(tz.local), minuteOfDay);
    await _plugin.zonedSchedule(
      id: dailyId,
      scheduledDate: tz.TZDateTime(tz.local, at.year, at.month, at.day, at.hour, at.minute),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_bread',
          'Daily Bread',
          channelDescription: 'A daily reminder to play Daily Bread',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelDaily() async {
    await _ensureReady();
    await _plugin.cancel(id: dailyId);
  }

  @override
  Stream<String> get taps {
    unawaited(_ensureReady());
    return _taps.stream;
  }

  @override
  Future<String?> launchPayload() async {
    try {
      await _ensureReady();
      final NotificationAppLaunchDetails? details = await _plugin.getNotificationAppLaunchDetails();
      if (details != null && details.didNotificationLaunchApp) {
        return details.notificationResponse?.payload;
      }
    } on Object catch (error) {
      _log?.log(LogLevel.warning, 'notifications', 'launch details failed: $error');
    }
    return null;
  }

  Future<void> dispose() => _taps.close();
}
