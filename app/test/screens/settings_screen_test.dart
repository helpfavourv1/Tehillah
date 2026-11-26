import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/models/settings_model.dart';
import 'package:tehillah/screens/app_language_sheet.dart';
import 'package:tehillah/screens/onboarding_screen.dart';
import 'package:tehillah/screens/reminder_time_sheet.dart';
import 'package:tehillah/screens/settings_screen.dart';

import '../support/test_surface.dart';
import '../support/widget_harness.dart';

String _count(int n) => '$n downloaded';
String _time(int h, int m) => '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

const SettingsLabels labels = SettingsLabels(
  title: 'Settings',
  back: 'Back',
  appearance: 'Appearance',
  theme: 'Theme',
  themeSystem: 'System',
  themeLight: 'Light',
  themeDark: 'Dark',
  language: 'Language',
  play: 'Play',
  inputScheme: 'Kick control',
  inputFlick: 'Flick',
  inputTiming: 'Timing bar',
  sound: 'Sound effects',
  music: 'Music',
  haptics: 'Vibration',
  daily: 'Daily Bread',
  reminders: 'Daily reminder',
  remindersDetail: 'One notice a day',
  reminderTime: 'Reminder time',
  reading: 'Reading',
  bibleReader: 'Bible reader',
  bibleReaderDetail: 'Read any chapter',
  purchases: 'Purchases',
  removeAds: 'Remove ads',
  adsRemoved: 'Ads removed',
  restore: 'Restore purchase',
  restoring: 'Restoring',
  privacyChoices: 'Privacy choices',
  data: 'Data',
  deleteBibles: 'Delete downloaded Bibles',
  deleteBiblesNone: 'None downloaded',
  deleteBiblesCount: _count,
  emailLog: 'Send debug log',
  emailLogDetail: 'Opens an email to support',
  about: 'About',
  licenses: 'Licenses',
  privacyPolicy: 'Privacy policy',
  support: 'Support',
  version: 'Version 1.0.0 (1)',
);

Widget settings({
  List<String>? log,
  ThemeChoice theme = ThemeChoice.system,
  bool reminders = false,
  bool adsRemoved = false,
  bool restoring = false,
  bool privacy = false,
  int bibles = 0,
  double textScale = 1,
  TextDirection direction = TextDirection.ltr,
}) {
  void l(String s) => log?.add(s);
  return harness(
    SettingsScreen(
      labels: labels,
      themeChoice: theme,
      onTheme: (ThemeChoice t) => l('theme:${t.name}'),
      appLanguageName: 'English',
      onAppLanguage: () => l('language'),
      inputScheme: InputScheme.flick,
      onInputScheme: (InputScheme s) => l('input:${s.name}'),
      soundOn: true,
      onSound: (bool v) => l('sound:$v'),
      musicOn: true,
      onMusic: (bool v) => l('music:$v'),
      hapticsOn: true,
      onHaptics: (bool v) => l('haptics:$v'),
      remindersOn: reminders,
      onReminders: (bool v) => l('reminders:$v'),
      reminderTimeLabel: '18:00',
      onReminderTime: () => l('time'),
      onOpenReader: () => l('reader'),
      adsRemoved: adsRemoved,
      priceLabel: r'$2.99',
      onUpgrade: () => l('upgrade'),
      restoring: restoring,
      onRestore: () => l('restore'),
      showPrivacyChoices: privacy,
      onPrivacyChoices: () => l('privacy-choices'),
      downloadedBibles: bibles,
      onDeleteBibles: () => l('delete'),
      onEmailLog: () => l('log'),
      onLicenses: () => l('licenses'),
      onPrivacyPolicy: () => l('policy'),
      onSupport: () => l('support'),
      onBack: () => l('back'),
    ),
    textScale: textScale,
    direction: direction,
    size: const Size(360, 3000),
  );
}

void main() {
  languageSheetTests();
  group('SettingsScreen', () {
    testWidgets('renders every section', (WidgetTester tester) async {
      await tester.pumpWidget(settings());
      for (final String s in <String>[
        'APPEARANCE',
        'PLAY',
        'DAILY BREAD',
        'READING',
        'PURCHASES',
        'DATA',
        'ABOUT',
      ]) {
        expect(find.text(s), findsOneWidget, reason: s);
      }
      expect(find.text('Version 1.0.0 (1)'), findsOneWidget);
    });

    testWidgets('theme and input choices report their value', (WidgetTester tester) async {
      useSurface(tester, const Size(360, 3000));
      final List<String> log = <String>[];
      await tester.pumpWidget(settings(log: log));
      await tester.tap(find.text('Dark'));
      await tester.tap(find.text('Timing bar'));
      expect(log, <String>['theme:dark', 'input:timingBar']);
    });

    testWidgets('toggles report the new value', (WidgetTester tester) async {
      useSurface(tester, const Size(360, 3000));
      final List<String> log = <String>[];
      await tester.pumpWidget(settings(log: log));
      await tester.tap(find.text('Sound effects'));
      await tester.tap(find.text('Music'));
      await tester.tap(find.text('Vibration'));
      await tester.tap(find.text('Daily reminder'));
      expect(log, <String>['sound:false', 'music:false', 'haptics:false', 'reminders:true']);
    });

    testWidgets('reminder time shows only while reminders are on', (WidgetTester tester) async {
      await tester.pumpWidget(settings());
      expect(find.text('Reminder time'), findsNothing);
      await tester.pumpWidget(settings(reminders: true));
      expect(find.text('Reminder time'), findsOneWidget);
      expect(find.text('18:00'), findsOneWidget);
    });

    testWidgets('navigation rows report', (WidgetTester tester) async {
      useSurface(tester, const Size(360, 3000));
      final List<String> log = <String>[];
      await tester.pumpWidget(settings(log: log));
      await tester.tap(find.text('Language'));
      await tester.tap(find.text('Bible reader'));
      await tester.tap(find.text('Remove ads'));
      await tester.tap(find.text('Send debug log'));
      await tester.tap(find.text('Licenses'));
      await tester.tap(find.text('Privacy policy'));
      await tester.tap(find.text('Support'));
      expect(log, <String>[
        'language',
        'reader',
        'upgrade',
        'log',
        'licenses',
        'policy',
        'support',
      ]);
    });

    testWidgets('Restore purchase is always visible and works', (WidgetTester tester) async {
      useSurface(tester, const Size(360, 3000));
      final List<String> log = <String>[];
      await tester.pumpWidget(settings(log: log, adsRemoved: true));
      expect(find.text('Ads removed'), findsOneWidget);
      await tester.tap(find.text('Restore purchase'));
      expect(log, <String>['restore']);
    });

    testWidgets('restoring changes the words and blocks a second tap', (WidgetTester tester) async {
      useSurface(tester, const Size(360, 3000));
      final List<String> log = <String>[];
      await tester.pumpWidget(settings(log: log, restoring: true));
      await tester.tap(find.text('Restoring'), warnIfMissed: false);
      expect(log, isEmpty);
    });

    testWidgets('Privacy choices appears only when required', (WidgetTester tester) async {
      await tester.pumpWidget(settings());
      expect(find.text('Privacy choices'), findsNothing);
      await tester.pumpWidget(settings(privacy: true));
      expect(find.text('Privacy choices'), findsOneWidget);
    });

    testWidgets('delete Bibles is disabled at zero and counts otherwise', (WidgetTester tester) async {
      useSurface(tester, const Size(360, 3000));
      final List<String> log = <String>[];
      await tester.pumpWidget(settings(log: log));
      expect(find.text('None downloaded'), findsOneWidget);
      await tester.tap(find.text('Delete downloaded Bibles'), warnIfMissed: false);
      expect(log, isEmpty);
      await tester.pumpWidget(settings(log: log, bibles: 2));
      expect(find.text('2 downloaded'), findsOneWidget);
      await tester.tap(find.text('Delete downloaded Bibles'));
      expect(log, <String>['delete']);
    });

    testWidgets('survives 3x text and right-to-left', (WidgetTester tester) async {
      await tester.pumpWidget(
        settings(textScale: 3, direction: TextDirection.rtl, reminders: true, privacy: true, bibles: 3),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ReminderTimeSheet', () {
    const ReminderTimeLabels l = ReminderTimeLabels(
      hour: 'Hour',
      minute: 'Minute',
      earlier: 'Earlier',
      later: 'Later',
      timeOf: _time,
      save: 'Save',
    );

    Widget build(int minuteOfDay, List<int> saved) => harness(
          ReminderTimeSheet(labels: l, minuteOfDay: minuteOfDay, onSave: saved.add),
          scroll: true,
        );

    testWidgets('shows the current time and saves it unchanged', (WidgetTester tester) async {
      useSurface(tester);
      final List<int> saved = <int>[];
      await tester.pumpWidget(build(1080, saved));
      expect(find.text('18:00'), findsOneWidget);
      await tester.tap(find.text('Save'));
      expect(saved, <int>[1080]);
    });

    testWidgets('hours step by one and wrap past midnight', (WidgetTester tester) async {
      useSurface(tester);
      final List<int> saved = <int>[];
      await tester.pumpWidget(build(23 * 60, saved));
      await tester.tap(find.text('Later').first);
      await tester.pump();
      expect(find.text('00:00'), findsOneWidget);
      await tester.tap(find.text('Earlier').first);
      await tester.tap(find.text('Earlier').first);
      await tester.pump();
      expect(find.text('22:00'), findsOneWidget);
    });

    testWidgets('minutes step by five and wrap', (WidgetTester tester) async {
      useSurface(tester);
      await tester.pumpWidget(build(8 * 60 + 55, <int>[]));
      await tester.tap(find.text('Later').last);
      await tester.pump();
      expect(find.text('08:00'), findsOneWidget);
      await tester.tap(find.text('Earlier').last);
      await tester.pump();
      expect(find.text('08:55'), findsOneWidget);
    });

    testWidgets('an off-grid saved minute snaps down to five', (WidgetTester tester) async {
      await tester.pumpWidget(build(7 * 60 + 33, <int>[]));
      expect(find.text('07:30'), findsOneWidget);
    });

    testWidgets('saving reports hour times sixty plus minute', (WidgetTester tester) async {
      useSurface(tester);
      final List<int> saved = <int>[];
      await tester.pumpWidget(build(8 * 60, saved));
      await tester.tap(find.text('Later').first);
      await tester.tap(find.text('Later').last);
      await tester.tap(find.text('Save'));
      expect(saved, <int>[9 * 60 + 5]);
    });
  });
}

void languageSheetTests() {
  group('AppLanguageSheet', () {
    const AppLanguageLabels l = AppLanguageLabels(
      followDevice: 'Same as device',
      followDeviceDetail: 'Currently English',
      selected: 'Selected',
    );
    const List<OnboardingLanguage> langs = <OnboardingLanguage>[
      OnboardingLanguage(code: 'en', name: 'English'),
      OnboardingLanguage(code: 'he', name: 'עברית'),
    ];

    Widget build(String? selected, List<String?> log) => harness(
          AppLanguageSheet(labels: l, languages: langs, selectedCode: selected, onPick: log.add),
          scroll: true,
        );

    testWidgets('null selection marks Same as device', (WidgetTester tester) async {
      await tester.pumpWidget(build(null, <String?>[]));
      expect(find.bySemanticsLabel('Same as device. Selected'), findsOneWidget);
    });

    testWidgets('a code selection marks that language only', (WidgetTester tester) async {
      await tester.pumpWidget(build('he', <String?>[]));
      expect(find.bySemanticsLabel('עברית. Selected'), findsOneWidget);
      expect(find.bySemanticsLabel('Same as device'), findsOneWidget);
    });

    testWidgets('picking reports the code, and null for the device', (WidgetTester tester) async {
      useSurface(tester);
      final List<String?> log = <String?>[];
      await tester.pumpWidget(build('en', log));
      await tester.tap(find.text('עברית'));
      await tester.tap(find.text('Same as device'));
      expect(log, <String?>['he', null]);
    });
  });
}
