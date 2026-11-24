import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/screens/home_screen.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/icon_chip.dart';

import '../support/widget_harness.dart';
import 'screen_labels.dart';

HomeScreen home({
  String? next = 'Garden',
  bool dailyDone = false,
  int streak = 0,
  Map<String, int>? taps,
  Widget? bottom,
}) {
  void tap(String k) => taps?.update(k, (int v) => v + 1, ifAbsent: () => 1);
  return HomeScreen(
    labels: homeLabels,
    nextStageName: next,
    lamps: 3,
    totalStages: 12,
    totalStars: 20,
    achievementsUnlocked: 2,
    achievementsTotal: 9,
    dailyDone: dailyDone,
    dailyStreak: streak,
    onPlay: () => tap('play'),
    onJourney: () => tap('journey'),
    onModes: () => tap('modes'),
    onDaily: () => tap('daily'),
    onVerses: () => tap('verses'),
    onAchievements: () => tap('achievements'),
    onSettings: () => tap('settings'),
    bottom: bottom,
  );
}

void main() {
  testWidgets('shows the brand once, the main button and every door', (WidgetTester tester) async {
    await tester.pumpWidget(harness(home()));
    expect(find.text('Tehillah Soccer'), findsOneWidget);
    expect(find.text('Continue: Garden'), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);
    expect(find.text('3 of 12 lamps, 20 stars'), findsOneWidget);
    expect(find.text('Modes'), findsOneWidget);
    expect(find.text('Daily Bread'), findsOneWidget);
    expect(find.text('Today\'s challenge is ready'), findsOneWidget);
    expect(find.text('Verse library'), findsOneWidget);
    expect(find.text('2 of 9'), findsOneWidget);
  });

  testWidgets('with every stage cleared the button just says Play', (WidgetTester tester) async {
    await tester.pumpWidget(harness(home(next: null)));
    expect(find.text('Play'), findsOneWidget);
    expect(find.textContaining('Continue'), findsNothing);
  });

  testWidgets('the daily card says done and shows a streak only when there is one', (WidgetTester tester) async {
    await tester.pumpWidget(harness(home(dailyDone: true, streak: 4)));
    expect(find.text('Done for today'), findsOneWidget);
    expect(find.text('4 day streak'), findsOneWidget);
    await tester.pumpWidget(harness(home()));
    expect(find.textContaining('streak'), findsNothing);
  });

  testWidgets('every control reaches its callback', (WidgetTester tester) async {
    final Map<String, int> taps = <String, int>{};
    await tester.pumpWidget(harness(home(taps: taps)));
    await tester.tap(find.text('Continue: Garden'));
    await tester.tap(find.text('Journey'));
    await tester.tap(find.text('Modes'));
    await tester.tap(find.text('Daily Bread'));
    await tester.tap(find.text('Verse library'));
    await tester.tap(find.text('Achievements'));
    await tester.tap(find.byType(IconChip));
    expect(taps, <String, int>{
      'play': 1,
      'journey': 1,
      'modes': 1,
      'daily': 1,
      'verses': 1,
      'achievements': 1,
      'settings': 1,
    });
  });

  testWidgets('the settings chip is a labelled 48 point target', (WidgetTester tester) async {
    final SemanticsHandle h = tester.ensureSemantics();
    await tester.pumpWidget(harness(home()));
    expect(find.bySemanticsLabel('Settings'), findsOneWidget);
    final Size s = tester.getSize(find.byType(IconChip));
    expect(s.width, greaterThanOrEqualTo(Metrics.touchTarget));
    expect(s.height, greaterThanOrEqualTo(Metrics.touchTarget));
    h.dispose();
  });

  testWidgets('the bottom slot is shown under the content', (WidgetTester tester) async {
    await tester.pumpWidget(harness(home(bottom: const SizedBox(key: Key('slot'), height: 50))));
    expect(find.byKey(const Key('slot')), findsOneWidget);
    expect(tester.getTopLeft(find.byKey(const Key('slot'))).dy, greaterThan(tester.getTopLeft(find.text('Verse library')).dy));
  });

  for (final PaletteMode mode in PaletteMode.values) {
    for (final TextDirection d in TextDirection.values) {
      testWidgets('holds at 3.1x text, $mode, $d', (WidgetTester tester) async {
        await tester.pumpWidget(harness(
          home(dailyDone: true, streak: 12),
          textScale: 3.1,
          direction: d,
          mode: mode,
        ));
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -2000));
        await tester.pump();
        expect(find.text('Achievements'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
