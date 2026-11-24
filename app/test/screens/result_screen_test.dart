import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/screens/result_screen.dart';
import 'package:tehillah/screens/stage_intro_screen.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/app_chip.dart';
import 'package:tehillah/widgets/verse_card.dart';

import '../support/test_surface.dart';
import '../support/widget_harness.dart';

String _score(int a, int b) => '$a to $b';
String _stars(int s, int t) => '$s of $t stars';

const ResultLabels labels = ResultLabels(
  win: 'You won',
  loss: 'Keep going',
  you: 'You',
  opponent: 'Rival',
  scoreLine: _score,
  starsLabel: _stars,
  readChapter: 'Read chapter',
  share: 'Share',
);

ResultScreen result({
  bool won = true,
  int stars = 2,
  List<String>? log,
  Future<void> Function()? beforeLeave,
  bool withSecondary = true,
  bool withRewarded = false,
  bool withVerse = true,
  List<IntroFact> earned = const <IntroFact>[
    IntroFact(label: 'Lamp 3 earned', icon: AppIcons.lamp, tone: ChipTone.success),
  ],
}) {
  return ResultScreen(
    labels: labels,
    won: won,
    playerScore: 3,
    opponentScore: 2,
    stars: stars,
    earned: earned,
    verse: withVerse
        ? IntroVerse(
            text: 'The Lord is my shepherd.',
            reference: 'Psalm 23:1',
            language: 'en',
            onShare: () => log?.add('share'),
          )
        : null,
    primaryLabel: 'Continue',
    onPrimary: () => log?.add('primary'),
    secondaryLabel: withSecondary ? 'Play again' : null,
    onSecondary: withSecondary ? () => log?.add('secondary') : null,
    rewardedRetryLabel: withRewarded ? 'Watch an ad to retry' : null,
    onRewardedRetry: withRewarded ? () => log?.add('rewarded') : null,
    beforeLeave: beforeLeave,
  );
}

void main() {
  testWidgets('a win shows the headline, score, stars, what was earned and the verse', (WidgetTester tester) async {
    await tester.pumpWidget(harness(result()));
    expect(find.text('You won'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('2 of 3 stars'), findsWidgets);
    expect(find.text('Lamp 3 earned'), findsOneWidget);
    expect(find.byType(VerseCard), findsOneWidget);
  });

  testWidgets('a loss is met with encouragement and zero stars in words', (WidgetTester tester) async {
    await tester.pumpWidget(harness(result(won: false, stars: 0)));
    expect(find.text('Keep going'), findsOneWidget);
    expect(find.text('You won'), findsNothing);
    expect(find.text('0 of 3 stars'), findsWidgets);
  });

  testWidgets('earned chips and the verse are simply absent when there is nothing', (WidgetTester tester) async {
    await tester.pumpWidget(harness(result(earned: const <IntroFact>[], withVerse: false)));
    expect(find.byType(AppChip), findsNothing);
    expect(find.byType(VerseCard), findsNothing);
  });

  testWidgets('the score is spoken as one phrase', (WidgetTester tester) async {
    final SemanticsHandle h = tester.ensureSemantics();
    await tester.pumpWidget(harness(result()));
    expect(find.bySemanticsLabel('3 to 2'), findsOneWidget);
    h.dispose();
  });

  testWidgets('primary and secondary reach their callbacks', (WidgetTester tester) async {
    useSurface(tester);
    final List<String> log = <String>[];
    await tester.pumpWidget(harness(result(log: log)));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(log, <String>['primary']);
  });

  testWidgets('the secondary button leaves by its own callback', (WidgetTester tester) async {
    useSurface(tester);
    final List<String> log = <String>[];
    await tester.pumpWidget(harness(result(log: log)));
    await tester.tap(find.text('Play again'));
    await tester.pump();
    expect(log, <String>['secondary']);
  });

  testWidgets('without a secondary there is only one button', (WidgetTester tester) async {
    await tester.pumpWidget(harness(result(withSecondary: false)));
    expect(find.text('Play again'), findsNothing);
  });

  testWidgets('the break runs first, once, and a second tap while it runs is ignored', (WidgetTester tester) async {
    useSurface(tester);
    final List<String> log = <String>[];
    final Completer<void> gate = Completer<void>();
    int breaks = 0;
    await tester.pumpWidget(harness(result(
      log: log,
      beforeLeave: () {
        breaks++;
        return gate.future;
      },
    )));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.tap(find.text('Play again'));
    await tester.pump();
    expect(log, isEmpty);
    expect(breaks, 1);
    gate.complete();
    await tester.pump();
    expect(log, <String>['primary']);
  });

  testWidgets('the rewarded retry is offered only when given, and is not a leave', (WidgetTester tester) async {
    useSurface(tester);
    await tester.pumpWidget(harness(result(won: false, stars: 0)));
    expect(find.text('Watch an ad to retry'), findsNothing);
    final List<String> log = <String>[];
    await tester.pumpWidget(harness(result(won: false, stars: 0, withRewarded: true, log: log, beforeLeave: () async => log.add('break'))));
    await tester.tap(find.text('Watch an ad to retry'));
    await tester.pump();
    expect(log, <String>['rewarded']);
  });

  testWidgets('the share chip on the verse card works', (WidgetTester tester) async {
    useSurface(tester);
    final List<String> log = <String>[];
    await tester.pumpWidget(harness(result(log: log)));
    await tester.tap(find.text('Share'));
    expect(log, <String>['share']);
  });

  for (final PaletteMode mode in PaletteMode.values) {
    for (final TextDirection d in TextDirection.values) {
      testWidgets('holds at 3.1x text, $mode, $d', (WidgetTester tester) async {
        await tester.pumpWidget(harness(result(withRewarded: true), textScale: 3.1, direction: d, mode: mode));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
