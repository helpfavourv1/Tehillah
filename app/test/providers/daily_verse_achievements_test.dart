import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/logic/date_key.dart';
import 'package:tehillah/core/models/curated_verse.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/models/settings_model.dart';
import 'package:tehillah/core/models/verse.dart';
import 'package:tehillah/core/ports/notification_port.dart';
import 'package:tehillah/core/storage/progress_store.dart';
import 'package:tehillah/core/verses/verse_repository.dart';
import 'package:tehillah/providers/achievements_provider.dart';
import 'package:tehillah/providers/daily_provider.dart';
import 'package:tehillah/providers/locale_provider.dart';
import 'package:tehillah/providers/progress_provider.dart';
import 'package:tehillah/providers/settings_provider.dart';
import 'package:tehillah/providers/verse_provider.dart';

import '../fakes/fake_ports.dart';
import '../fakes/fake_storage.dart';

String _texts(String language, Map<String, String> texts) => jsonEncode(<String, Object?>{
      'schemaVersion': 1,
      'language': language,
      'translationId': language.toUpperCase(),
      'texts': texts,
    });

VerseRepository _repo() {
  const List<String> ids = <String>['a', 'b', 'c'];
  return VerseRepository.parse(
    curatedJson: jsonEncode(<String, Object?>{
      'schemaVersion': 1,
      'verses': <Map<String, Object?>>[
        <String, Object?>{'id': 'a', 'ref': 'Gen.1.1', 'moments': <String>['miss']},
        <String, Object?>{'id': 'b', 'ref': 'Ps.46.10', 'moments': <String>['miss']},
        <String, Object?>{'id': 'c', 'ref': 'John.3.16', 'moments': <String>['win']},
      ],
    }),
    textJsonByLanguage: <String, String>{
      'en': _texts('en', <String, String>{for (final String i in ids) i: 'en $i'}),
      'es': _texts('es', <String, String>{for (final String i in ids) i: 'es $i'}),
    },
  );
}

void main() {
  late FakeStorage storage;
  late FakeLog log;
  late SettingsProvider settings;
  late ProgressProvider progress;

  setUp(() async {
    storage = FakeStorage();
    log = FakeLog();
    settings = SettingsProvider(storage, log);
    await settings.load();
    progress = ProgressProvider(ProgressStore(storage, log), log);
    await progress.load();
  });

  tearDown(() {
    settings.dispose();
    progress.dispose();
  });

  group('DailyProvider', () {
    late FakeNotifications notifications;
    late DateTime now;
    late DailyProvider daily;

    setUp(() {
      notifications = FakeNotifications();
      now = DateTime(2026, 11, 22, 9);
      daily = DailyProvider(
        progress: progress,
        settings: settings,
        notifications: notifications,
        log: log,
        clock: () => now,
      );
    });

    tearDown(() => daily.dispose());

    test('today is the seeded challenge for the device day and starts open', () {
      expect(daily.value.challenge.dateKey, '2026-11-22');
      expect(daily.value.completed, isFalse);
      expect(daily.value.streak, 0);
      expect(daily.value.remindersOn, isFalse);
    });

    test('finishing today marks it done and starts a streak', () {
      progress.applyDaily(daily.value.challenge, won: true, goals: 3);
      expect(daily.value.completed, isTrue);
      expect(daily.value.record!.goals, 3);
      expect(daily.value.streak, 1);
    });

    test('the streak survives to the next morning and the new day is open', () {
      progress.applyDaily(daily.value.challenge, won: true, goals: 3);
      now = DateTime(2026, 11, 23, 8);
      daily.refreshDay();
      expect(daily.value.challenge.dateKey, '2026-11-23');
      expect(daily.value.completed, isFalse);
      expect(daily.value.streak, 1);
      now = DateTime(2026, 11, 25, 8);
      daily.refreshDay();
      expect(daily.value.streak, 0);
    });

    test('enabling reminders asks for permission, schedules and turns the setting on', () async {
      final ReminderOutcome r = await daily.enableReminders(title: 'T', body: 'B');
      expect(r, ReminderOutcome.enabled);
      expect(notifications.scheduledMinute, 1080);
      expect(settings.value.remindersOn, isTrue);
      expect(daily.value.remindersOn, isTrue);
    });

    test('a refusal leaves reminders off', () async {
      notifications.onRequest = NotificationPermission.denied;
      expect(await daily.enableReminders(title: 'T', body: 'B'), ReminderOutcome.denied);
      expect(settings.value.remindersOn, isFalse);
      expect(notifications.scheduledMinute, isNull);
    });

    test('denied forever is reported without asking again', () async {
      notifications.state = NotificationPermission.deniedForever;
      expect(await daily.enableReminders(title: 'T', body: 'B'), ReminderOutcome.deniedForever);
      expect(settings.value.remindersOn, isFalse);
    });

    test('a failing scheduler is reported as failed and leaves the setting off', () async {
      final DailyProvider broken = DailyProvider(
        progress: progress,
        settings: settings,
        notifications: _ThrowingNotifications(),
        log: log,
      );
      expect(await broken.enableReminders(title: 'T', body: 'B'), ReminderOutcome.failed);
      expect(settings.value.remindersOn, isFalse);
      broken.dispose();
    });

    test('disabling cancels and turns the setting off', () async {
      await daily.enableReminders(title: 'T', body: 'B');
      await daily.disableReminders();
      expect(notifications.scheduledMinute, isNull);
      expect(settings.value.remindersOn, isFalse);
    });

    test('changing the time reschedules only when reminders are on', () async {
      await daily.setReminderTime(480, title: 'T', body: 'B');
      expect(notifications.scheduledMinute, isNull);
      expect(settings.value.reminderMinuteOfDay, 480);
      await daily.enableReminders(title: 'T', body: 'B');
      await daily.setReminderTime(600, title: 'T', body: 'B');
      expect(notifications.scheduledMinute, 600);
      await daily.setReminderTime(2000, title: 'T', body: 'B');
      expect(settings.value.reminderMinuteOfDay, 600);
    });

    test('on launch a revoked permission turns the reminder off', () async {
      await daily.enableReminders(title: 'T', body: 'B');
      notifications.state = NotificationPermission.denied;
      await daily.syncReminder(title: 'T', body: 'B');
      expect(settings.value.remindersOn, isFalse);
      expect(notifications.scheduledMinute, isNull);
    });

    test('on launch a granted permission reschedules with the current text', () async {
      await daily.enableReminders(title: 'T', body: 'B');
      notifications.scheduledMinute = null;
      await daily.syncReminder(title: 'T2', body: 'B2');
      expect(notifications.scheduledMinute, 1080);
      expect(settings.value.remindersOn, isTrue);
    });
  });

  group('VerseProvider', () {
    test('serves verses in the interface language', () {
      final LocaleProvider locale = LocaleProvider(settings);
      final VerseProvider verses = VerseProvider(_repo(), locale, () => <String>['es']);
      expect(verses.value, 'es');
      expect(verses.verseFor(VerseMoment.win, seed: 1)!.text, 'es c');
      verses.dispose();
      locale.dispose();
    });

    test('a language with no bundled text falls back to English', () {
      final LocaleProvider locale = LocaleProvider(settings);
      final VerseProvider verses = VerseProvider(_repo(), locale, () => <String>['ja']);
      expect(verses.value, 'en');
      verses.dispose();
      locale.dispose();
    });

    test('changing the interface language switches the verse language', () {
      final LocaleProvider locale = LocaleProvider(settings);
      final VerseProvider verses = VerseProvider(_repo(), locale, () => <String>['en']);
      expect(verses.value, 'en');
      locale.setAppLanguage('es');
      expect(verses.value, 'es');
      locale.followDeviceLanguage();
      expect(verses.value, 'en');
      verses.dispose();
      locale.dispose();
    });

    test('the same moment does not repeat a verse until the pool runs out', () {
      final LocaleProvider locale = LocaleProvider(settings);
      final VerseProvider verses = VerseProvider(_repo(), locale, () => <String>['en']);
      final Verse first = verses.verseFor(VerseMoment.miss, seed: 5)!;
      final Verse second = verses.verseFor(VerseMoment.miss, seed: 5)!;
      expect(second.ref, isNot(first.ref));
      final Verse third = verses.verseFor(VerseMoment.miss, seed: 5)!;
      expect(<Object>{first.ref, second.ref, third.ref}.length, greaterThanOrEqualTo(2));
      verses.dispose();
      locale.dispose();
    });

    test('a moment with no verse gives null and the library lists everything', () {
      final LocaleProvider locale = LocaleProvider(settings);
      final VerseProvider verses = VerseProvider(_repo(), locale, () => <String>['en']);
      expect(verses.verseFor(VerseMoment.goal, seed: 1), isNull);
      expect(verses.library().length, 3);
      expect(verses.library(moment: VerseMoment.win).length, 1);
      verses.dispose();
      locale.dispose();
    });
  });

  group('AchievementsProvider', () {
    test('held achievements are not announced; new ones queue until acknowledged', () async {
      progress.update((Progress p) => p.copyWith(achievements: <String>{'love'}));
      final AchievementsProvider ach = AchievementsProvider(progress);
      expect(ach.value.unlocked, <String>{'love'});
      expect(ach.value.pending, isEmpty);
      progress.update((Progress p) => p.copyWith(achievements: <String>{'love', 'joy', 'peace'}));
      expect(ach.value.pending, <String>['joy', 'peace']);
      ach.acknowledge('joy');
      expect(ach.value.pending, <String>['peace']);
      ach.acknowledge('unknown');
      expect(ach.value.pending, <String>['peace']);
      ach.dispose();
      await progress.flush();
    });

    test('a provider built before the career loads baselines when it loads', () async {
      storage.files.clear();
      final ProgressProvider early = ProgressProvider(ProgressStore(storage, log), log);
      final AchievementsProvider ach = AchievementsProvider(early);
      expect(ach.value.unlocked, isEmpty);
      await early.load();
      expect(ach.value.pending, isEmpty);
      ach.dispose();
      early.dispose();
    });
  });

  test('date keys line up with the provider day', () {
    expect(DateKey.of(DateTime(2026, 11, 22, 23, 59)), '2026-11-22');
  });
}

final class _ThrowingNotifications extends FakeNotifications {
  @override
  Future<NotificationPermission> permission() async => throw StateError('no notifications');
}
