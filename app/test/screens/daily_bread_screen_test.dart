import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/screens/daily_bread_screen.dart';
import 'package:tehillah/screens/stage_intro_screen.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_chip.dart';
import 'package:tehillah/widgets/toggle_row.dart';

import '../support/test_surface.dart';
import '../support/widget_harness.dart';

String _goals(int g) => '$g goals';
String _days(int d) => '$d days';
String _state(DayState s) => switch (s) {
      DayState.won => 'won',
      DayState.played => 'played',
      DayState.rescued => 'restored',
      DayState.missed => 'missed',
      DayState.today => 'today',
    };

const DailyBreadLabels labels = DailyBreadLabels(
  title: 'Daily Bread',
  back: 'Back',
  opponent: 'Today\'s opponent',
  recent: 'Last seven days',
  start: 'Play today\'s challenge',
  startAgain: 'Play again',
  firstCounts: 'Only your first result counts',
  resultWon: 'You won today',
  resultLost: 'Not today, keep going',
  goalsValue: _goals,
  streak: 'Streak',
  streakValue: _days,
  dayState: _state,
  reminder: 'Daily reminder',
  reminderDetail: 'One notice a day',
  rescue: 'Restore yesterday',
  rescueDetail: 'Watch a short ad',
  );

const List<DailyDay> week = <DailyDay>[
  DailyDay(label: 'Mon', state: DayState.won),
  DailyDay(label: 'Tue', state: DayState.played),
  DailyDay(label: 'Wed', state: DayState.rescued),
  DailyDay(label: 'Thu', state: DayState.missed),
  DailyDay(label: 'Fri', state: DayState.today),
];

DailyBreadScreen screen({
  DailyResult? result,
  VoidCallback? onRescue,
  bool reminders = false,
  Map<String, int>? taps,
  List<bool>? toggles,
}) {
  void tap(String k) => taps?.update(k, (int v) => v + 1, ifAbsent: () => 1);
  return DailyBreadScreen(
    labels: labels,
    opponentName: 'Dan Cole',
    opponentTeam: 'Ararat Athletic',
    facts: const <IntroFact>[IntroFact(label: 'Windy', icon: AppIcons.info)],
    result: result,
    streak: 4,
    days: week,
    remindersOn: reminders,
    onReminders: (bool v) => toggles?.add(v),
    onRescue: onRescue,
    onStart: () => tap('start'),
    onBack: () => tap('back'),
  );
}

void main() {
  testWidgets('before today is played: opponent, facts, streak and the start button', (WidgetTester tester) async {
    await tester.pumpWidget(harness(screen()));
    expect(find.text('Dan Cole'), findsOneWidget);
    expect(find.text('Windy'), findsOneWidget);
    expect(find.text('4 days'), findsOneWidget);
    expect(find.text('Play today\'s challenge'), findsOneWidget);
    expect(find.text('Only your first result counts'), findsNothing);
  });

  testWidgets('once played: the result, the note and Play again', (WidgetTester tester) async {
    await tester.pumpWidget(harness(screen(result: const DailyResult(won: true, goals: 3))));
    expect(find.text('You won today'), findsOneWidget);
    expect(find.text('3 goals'), findsOneWidget);
    expect(find.text('Only your first result counts'), findsOneWidget);
    expect(find.text('Play again'), findsOneWidget);
    await tester.pumpWidget(harness(screen(result: const DailyResult(won: false, goals: 1))));
    expect(find.text('Not today, keep going'), findsOneWidget);
  });

  testWidgets('the week strip has one chip per day and speaks each state', (WidgetTester tester) async {
    final SemanticsHandle h = tester.ensureSemantics();
    await tester.pumpWidget(harness(screen()));
    for (final DailyDay d in week) {
      expect(find.text(d.label), findsOneWidget);
    }
    expect(find.bySemanticsLabel('Wed, restored'), findsOneWidget);
    expect(find.bySemanticsLabel('Thu, missed'), findsOneWidget);
    expect(find.byType(AppChip), findsNWidgets(week.length + 1));
    h.dispose();
  });

  testWidgets('the rescue offer shows only when a day can be restored', (WidgetTester tester) async {
    await tester.pumpWidget(harness(screen()));
    expect(find.text('Restore yesterday'), findsNothing);
    await tester.pumpWidget(harness(screen(onRescue: () {})));
    expect(find.text('Restore yesterday'), findsOneWidget);
  });

  testWidgets('start, rescue, back and the reminder switch reach their callbacks', (WidgetTester tester) async {
    useSurface(tester);
    final Map<String, int> taps = <String, int>{};
    final List<bool> toggles = <bool>[];
    int rescues = 0;
    await tester.pumpWidget(harness(screen(
      taps: taps,
      toggles: toggles,
      onRescue: () => rescues++,
    )));
    await tester.tap(find.text('Restore yesterday'));
    await tester.tap(find.text('Daily reminder'));
    await tester.tap(find.text('Play today\'s challenge'));
    expect(rescues, 1);
    expect(toggles, <bool>[true]);
    expect(taps['start'], 1);
    await tester.pumpWidget(harness(screen(reminders: true, toggles: toggles)));
    await tester.tap(find.text('Daily reminder'));
    expect(toggles, <bool>[true, false]);
    expect(find.byType(ToggleRow), findsOneWidget);
  });

  testWidgets('Start stays put while the content scrolls', (WidgetTester tester) async {
    await tester.pumpWidget(harness(
      screen(result: const DailyResult(won: true, goals: 3), onRescue: () {}),
      textScale: 2,
    ));
    final Offset before = tester.getTopLeft(find.text('Play again'));
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pump();
    expect(tester.getTopLeft(find.text('Play again')), before);
  });

  for (final PaletteMode mode in PaletteMode.values) {
    for (final TextDirection d in TextDirection.values) {
      testWidgets('holds at 3.1x text, $mode, $d', (WidgetTester tester) async {
        await tester.pumpWidget(harness(
          screen(result: const DailyResult(won: true, goals: 3), onRescue: () {}),
          textScale: 3.1,
          direction: d,
          mode: mode,
        ));
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
        await tester.pump();
        expect(find.text('Daily reminder'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
