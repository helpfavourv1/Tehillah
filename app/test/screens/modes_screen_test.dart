import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/screens/modes_screen.dart';
import 'package:tehillah/theme/tokens.dart';

import '../support/test_surface.dart';
import '../support/widget_harness.dart';
import 'screen_labels.dart';

List<ModeEntry> entries() => const <ModeEntry>[
      ModeEntry(
        mode: MatchMode.friendly,
        name: 'Friendly',
        subtitle: 'A quick match',
        unlocked: true,
      ),
      ModeEntry(
        mode: MatchMode.jericho,
        name: 'Jericho',
        subtitle: 'Seven rounds',
        value: 'Round 3 of 7',
        unlocked: true,
      ),
      ModeEntry(
        mode: MatchMode.slingAndStone,
        name: 'Sling and Stone',
        subtitle: 'Hit the targets',
        value: 'Best 2 stars',
        unlocked: false,
        lockedHint: 'Clear Valley of Elah to unlock',
      ),
      ModeEntry(
        mode: MatchMode.watchman,
        name: 'Watchman',
        subtitle: 'Keep goal',
        unlocked: false,
      ),
    ];

ModesScreen screen({List<MatchMode>? taps}) => ModesScreen(
      labels: modesLabels,
      entries: entries(),
      onSelect: (MatchMode m) => taps?.add(m),
      onBack: () {},
    );

void main() {
  testWidgets('open modes show their line and value', (WidgetTester tester) async {
    await tester.pumpWidget(harness(screen()));
    expect(find.text('A quick match'), findsOneWidget);
    expect(find.text('Seven rounds'), findsOneWidget);
    expect(find.text('Round 3 of 7'), findsOneWidget);
  });

  testWidgets('a locked mode shows how to open it and hides its value', (WidgetTester tester) async {
    await tester.pumpWidget(harness(screen()));
    expect(find.text('Clear Valley of Elah to unlock'), findsOneWidget);
    expect(find.text('Hit the targets'), findsNothing);
    expect(find.text('Best 2 stars'), findsNothing);
  });

  testWidgets('a locked mode with no hint falls back to its line', (WidgetTester tester) async {
    await tester.pumpWidget(harness(screen()));
    expect(find.text('Keep goal'), findsOneWidget);
  });

  testWidgets('only open modes can be selected', (WidgetTester tester) async {
    useSurface(tester);
    final List<MatchMode> taps = <MatchMode>[];
    await tester.pumpWidget(harness(screen(taps: taps)));
    await tester.tap(find.text('Friendly'));
    await tester.tap(find.text('Jericho'));
    await tester.tap(find.text('Sling and Stone'));
    await tester.tap(find.text('Watchman'));
    expect(taps, <MatchMode>[MatchMode.friendly, MatchMode.jericho]);
  });

  test('every mode has an icon', () {
    for (final MatchMode m in MatchMode.values) {
      expect(ModesScreen.iconFor(m), isNotNull);
    }
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
