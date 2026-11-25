import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/screens/achievements_screen.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';

import '../support/widget_harness.dart';
import 'screen_labels.dart';

List<AchievementEntry> entries() => const <AchievementEntry>[
      AchievementEntry(
        id: 'love',
        name: 'Love',
        description: 'Win 10 matches',
        value: 12,
        threshold: 10,
        unlocked: true,
      ),
      AchievementEntry(
        id: 'joy',
        name: 'Joy',
        description: 'Score 50 goals',
        value: 20,
        threshold: 50,
        unlocked: false,
      ),
      AchievementEntry(
        id: 'peace',
        name: 'Peace',
        description: 'Keep 3 clean sheets',
        value: 0,
        threshold: 3,
        unlocked: false,
      ),
    ];

AchievementsScreen screen({List<AchievementEntry>? list}) => AchievementsScreen(
      labels: achievementsLabels,
      entries: list ?? entries(),
      onBack: () {},
    );

void main() {
  testWidgets('summarises how many are unlocked', (WidgetTester tester) async {
    await tester.pumpWidget(harness(screen()));
    expect(find.text('1 of 3 unlocked'), findsOneWidget);
  });

  testWidgets('earned ones say Unlocked and the rest show progress', (WidgetTester tester) async {
    await tester.pumpWidget(harness(screen()));
    expect(find.text('Unlocked'), findsOneWidget);
    expect(find.text('20 of 50'), findsOneWidget);
    expect(find.text('0 of 3'), findsOneWidget);
    expect(find.text('Score 50 goals'), findsOneWidget);
  });

  testWidgets('progress never reads above the target', (WidgetTester tester) async {
    await tester.pumpWidget(harness(screen(list: const <AchievementEntry>[
      AchievementEntry(
        id: 'x',
        name: 'X',
        description: 'd',
        value: 99,
        threshold: 10,
        unlocked: false,
      ),
    ])));
    expect(find.text('10 of 10'), findsOneWidget);
  });

  testWidgets('cards are display-only', (WidgetTester tester) async {
    await tester.pumpWidget(harness(screen()));
    expect(find.byType(AppCard), findsNWidgets(3));
  });

  for (final PaletteMode mode in PaletteMode.values) {
    for (final TextDirection d in TextDirection.values) {
      testWidgets('holds at 3.1x text, $mode, $d', (WidgetTester tester) async {
        await tester.pumpWidget(harness(screen(), textScale: 3.1, direction: d, mode: mode));
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
        await tester.pump();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
