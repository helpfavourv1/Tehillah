import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/screens/journey_map_screen.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_card.dart';

import '../support/test_surface.dart';
import '../support/widget_harness.dart';
import 'screen_labels.dart';

List<JourneyStageItem> stages() => <JourneyStageItem>[
      const JourneyStageItem(
        id: 1,
        name: 'Garden',
        status: StageStatus.cleared,
        stars: 9,
        maxStars: 12,
        roundsCleared: 4,
        rounds: 4,
      ),
      const JourneyStageItem(
        id: 2,
        name: 'Ararat',
        status: StageStatus.open,
        stars: 2,
        maxStars: 12,
        roundsCleared: 2,
        rounds: 4,
      ),
      const JourneyStageItem(
        id: 3,
        name: 'Red Sea Shore',
        status: StageStatus.locked,
        stars: 0,
        maxStars: 12,
        roundsCleared: 0,
        rounds: 4,
      ),
      const JourneyStageItem(
        id: 6,
        name: 'Valley of Elah',
        status: StageStatus.open,
        stars: 1,
        maxStars: 12,
        roundsCleared: 1,
        rounds: 4,
        isBoss: true,
      ),
    ];

JourneyMapScreen screen({List<int>? taps, Widget? bottom}) => JourneyMapScreen(
      labels: journeyLabels,
      stages: stages(),
      onStage: (int id) => taps?.add(id),
      onBack: () => taps?.add(-1),
      bottom: bottom,
    );

void main() {
  testWidgets('summarises lamps and stars from the stages', (WidgetTester tester) async {
    await tester.pumpWidget(harness(screen()));
    expect(find.text('1 of 4 lamps, 12 stars'), findsOneWidget);
    expect(find.text('Journey'), findsOneWidget);
  });

  testWidgets('each state has its own text and icon', (WidgetTester tester) async {
    await tester.pumpWidget(harness(screen(), scroll: false));
    expect(find.text('Cleared'), findsOneWidget);
    expect(find.text('2 of 4 rounds'), findsOneWidget);
    expect(find.text('9 of 12 stars'), findsOneWidget);
    expect(find.text('Clear the stage before it to open'), findsOneWidget);
    expect(find.textContaining('Boss stage'), findsOneWidget);
    final Iterable<String> glyphs = find
        .byType(Text)
        .evaluate()
        .map((Element e) => (e.widget as Text).data ?? '')
        .where((String d) => d.length == 1);
    expect(glyphs.contains(String.fromCharCode(AppIcons.locked.codePoint)), isTrue);
    expect(glyphs.contains(String.fromCharCode(AppIcons.lamp.codePoint)), isTrue);
  });

  testWidgets('a locked stage shows no stars and ignores taps', (WidgetTester tester) async {
    useSurface(tester);
    final List<int> taps = <int>[];
    await tester.pumpWidget(harness(screen(taps: taps)));
    expect(find.text('0 of 12 stars'), findsNothing);
    await tester.tap(find.text('Red Sea Shore'));
    expect(taps, isEmpty);
  });

  testWidgets('tapping a cleared or open stage reports its id', (WidgetTester tester) async {
    useSurface(tester);
    final List<int> taps = <int>[];
    await tester.pumpWidget(harness(screen(taps: taps)));
    await tester.tap(find.text('Garden'));
    await tester.tap(find.text('Ararat'));
    await tester.tap(find.text('Valley of Elah'));
    expect(taps, <int>[1, 2, 6]);
  });

  testWidgets('chevrons only on stages that open', (WidgetTester tester) async {
    await tester.pumpWidget(harness(screen()));
    expect(find.byType(AppCard), findsNWidgets(4));
  });

  testWidgets('the bottom slot sits under the list', (WidgetTester tester) async {
    await tester.pumpWidget(harness(screen(bottom: const SizedBox(key: Key('slot'), height: 50))));
    expect(find.byKey(const Key('slot')), findsOneWidget);
  });

  for (final PaletteMode mode in PaletteMode.values) {
    for (final TextDirection d in TextDirection.values) {
      testWidgets('holds at 3.1x text, $mode, $d', (WidgetTester tester) async {
        await tester.pumpWidget(harness(screen(), textScale: 3.1, direction: d, mode: mode));
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -3000));
        await tester.pump();
        expect(find.text('Valley of Elah'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
