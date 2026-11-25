import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/screens/stage_intro_screen.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_chip.dart';
import 'package:tehillah/widgets/verse_card.dart';

import '../support/test_surface.dart';
import '../support/widget_harness.dart';
import 'screen_labels.dart';

StageIntroScreen intro({
  Map<String, int>? taps,
  bool withVerse = true,
  String? gear,
  String? round = 'Round 2 of 4',
  List<IntroFact> facts = const <IntroFact>[
    IntroFact(label: 'Boss stage', icon: AppIcons.warning, tone: ChipTone.warning),
    IntroFact(label: 'Windy', icon: AppIcons.info),
  ],
}) {
  void tap(String k) => taps?.update(k, (int v) => v + 1, ifAbsent: () => 1);
  return StageIntroScreen(
    labels: introLabels,
    title: 'Ararat',
    roundLabel: round,
    opponentName: 'Dan Cole',
    opponentTeam: 'Ararat Athletic',
    facts: facts,
    verse: withVerse
        ? IntroVerse(
            text: 'Be strong and courageous.',
            reference: 'Joshua 1:9',
            language: 'en',
            translationLabel: 'BSB',
            onReadChapter: () => tap('read'),
            onShare: () => tap('share'),
          )
        : null,
    ballName: 'Love',
    gearName: gear,
    onStart: () => tap('start'),
    onChangeLoadout: () => tap('loadout'),
    onBack: () => tap('back'),
  );
}

void main() {
  modeIntroTests();
  testWidgets('shows who you face, the facts, the verse and the loadout', (WidgetTester tester) async {
    await tester.pumpWidget(harness(intro()));
    expect(find.text('Ararat'), findsOneWidget);
    expect(find.text('Round 2 of 4'), findsOneWidget);
    expect(find.text('Dan Cole'), findsOneWidget);
    expect(find.text('Ararat Athletic'), findsOneWidget);
    expect(find.text('Boss stage'), findsOneWidget);
    expect(find.text('Windy'), findsOneWidget);
    expect(find.byType(VerseCard), findsOneWidget);
    expect(find.text('Love'), findsOneWidget);
    expect(find.text('No gear'), findsOneWidget);
  });

  testWidgets('without a verse, a round or facts those parts are simply absent', (WidgetTester tester) async {
    await tester.pumpWidget(harness(intro(withVerse: false, round: null, facts: const <IntroFact>[], gear: 'Belt of Truth')));
    expect(find.byType(VerseCard), findsNothing);
    expect(find.textContaining('Round'), findsNothing);
    expect(find.byType(AppChip), findsNothing);
    expect(find.text('Belt of Truth'), findsOneWidget);
    expect(find.text('No gear'), findsNothing);
  });

  testWidgets('start, loadout, back, read and share each reach their callback', (WidgetTester tester) async {
    useSurface(tester);
    final Map<String, int> taps = <String, int>{};
    await tester.pumpWidget(harness(intro(taps: taps)));
    await tester.tap(find.text('Start match'));
    await tester.tap(find.text('Love'));
    await tester.tap(find.text('Read chapter'));
    await tester.tap(find.text('Share'));
    expect(taps, <String, int>{'start': 1, 'loadout': 1, 'read': 1, 'share': 1});
    final SemanticsHandle h = tester.ensureSemantics();
    await tester.tap(find.bySemanticsLabel('Back'));
    expect(taps['back'], 1);
    h.dispose();
  });

  testWidgets('Start stays on screen at the bottom while the content scrolls', (WidgetTester tester) async {
    await tester.pumpWidget(harness(intro(), textScale: 3.1));
    expect(tester.takeException(), isNull);
    final double before = tester.getTopLeft(find.text('Start match')).dy;
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1500));
    await tester.pump();
    expect(tester.getTopLeft(find.text('Start match')).dy, before);
  });

  for (final PaletteMode mode in PaletteMode.values) {
    for (final TextDirection d in TextDirection.values) {
      testWidgets('holds at 3.1x text, $mode, $d', (WidgetTester tester) async {
        await tester.pumpWidget(harness(intro(gear: 'Breastplate of Righteousness'), textScale: 3.1, direction: d, mode: mode));
        expect(tester.takeException(), isNull);
      });
    }
  }
}

void modeIntroTests() {
  testWidgets('with no opponent the section is absent and the rules show', (WidgetTester tester) async {
    await tester.pumpWidget(harness(StageIntroScreen(
      labels: introLabels,
      title: 'Sling and Stone',
      rules: const <String>['Seven stones.', 'Hit five targets.'],
      ballName: 'Love',
      onStart: () {},
      onChangeLoadout: () {},
      onBack: () {},
    )));
    expect(find.text('Opponent'), findsNothing);
    expect(find.text('How it plays'), findsNothing); // upper-cased by the header
    expect(find.text('HOW IT PLAYS'), findsOneWidget);
    expect(find.text('Seven stones.'), findsOneWidget);
    expect(find.text('Hit five targets.'), findsOneWidget);
  });

  testWidgets('a plain Journey intro shows no rules section', (WidgetTester tester) async {
    await tester.pumpWidget(harness(intro()));
    expect(find.text('HOW IT PLAYS'), findsNothing);
    expect(find.text('OPPONENT'), findsOneWidget);
  });
}
