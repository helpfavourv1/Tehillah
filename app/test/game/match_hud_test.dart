import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/logic/match_engine.dart';
import 'package:tehillah/core/models/kick_record.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/match_state.dart';
import 'package:tehillah/game/hud/match_hud.dart';
import 'package:tehillah/providers/match_provider.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/widgets/icon_chip.dart';
import 'package:tehillah/widgets/nerve_meter_view.dart';

import '../fakes/fake_storage.dart';
import '../support/match_helpers.dart';
import '../support/widget_harness.dart';

const MatchHudLabels labels = MatchHudLabels(
  you: 'You',
  opponent: 'Rival',
  pause: 'Pause',
  selah: 'Selah',
  selahWithCharges: _selahWith,
  nerve: 'Nerve',
  nerveCalm: 'Calm',
  nerveTense: 'Tense',
  nerveFull: 'Overwhelmed',
  suddenDeath: 'Sudden death',
  promptShot: 'Swipe to shoot',
  promptDive: 'Choose where to dive',
  promptWatch: 'Watch the kick',
  kickScored: 'Scored',
  kickMissed: 'Missed',
  kickPending: 'To come',
);

String _selahWith(int n) => 'Selah, $n left';

MatchView viewOf({
  MatchState? state,
  List<KickRecord> history = const <KickRecord>[],
  KickPrompt prompt = KickPrompt.humanShot,
  bool canUseSelah = true,
}) {
  return MatchView(
    config: configFor(),
    state: state ?? stateOf(),
    history: history,
    prompt: prompt,
    canUseSelah: canUseSelah,
    version: 1,
  );
}

bool hasIcon(Widget w, IconData symbol) => w is AppIcon && w.symbol == symbol;

Widget hud(
  MatchView view, {
  VoidCallback? onPause,
  VoidCallback? onSelah,
  bool enabled = true,
}) {
  return SizedBox.expand(
    child: MatchHud(
      view: view,
      labels: labels,
      onPause: onPause ?? () {},
      onSelah: onSelah ?? () {},
      enabled: enabled,
    ),
  );
}

void main() {
  testWidgets('before a match there is nothing to draw', (WidgetTester tester) async {
    await tester.pumpWidget(harness(hud(const MatchView())));
    expect(find.byType(IconChip), findsNothing);
    expect(find.text('You'), findsNothing);
  });

  testWidgets('shows the score, the prompt and the pressure', (WidgetTester tester) async {
    await tester.pumpWidget(harness(hud(viewOf(
      state: stateOf(playerScore: 2, opponentScore: 1, playerKicks: 3, opponentKicks: 2, nerve: 0.3),
    ))));
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Swipe to shoot'), findsOneWidget);
    expect(find.text('Nerve · Calm'), findsOneWidget);
  });

  testWidgets('the prompt follows what is being asked', (WidgetTester tester) async {
    await tester.pumpWidget(harness(hud(viewOf(prompt: KickPrompt.humanDive, canUseSelah: false))));
    expect(find.text('Choose where to dive'), findsOneWidget);
    await tester.pumpWidget(harness(hud(viewOf(prompt: KickPrompt.automatic, canUseSelah: false))));
    expect(find.text('Watch the kick'), findsOneWidget);
    await tester.pumpWidget(harness(hud(viewOf(prompt: KickPrompt.finished, canUseSelah: false))));
    expect(find.text('Swipe to shoot'), findsNothing);
    expect(find.text('Watch the kick'), findsNothing);
    expect(find.text('Choose where to dive'), findsNothing);
  });

  testWidgets('the pressure reads calm, tense and overwhelmed in words', (WidgetTester tester) async {
    for (final (double, String) c in <(double, String)>[
      (0.0, 'Calm'),
      (NerveMeterView.calmBelow, 'Tense'),
      (NerveMeterView.tenseAt, 'Overwhelmed'),
      (1.0, 'Overwhelmed'),
    ]) {
      await tester.pumpWidget(harness(hud(viewOf(state: stateOf(nerve: c.$1)))));
      expect(find.text('Nerve · ${c.$2}'), findsOneWidget, reason: '${c.$1}');
    }
  });

  testWidgets('each side shows its kicks: ticks for goals, crosses for misses, rings to come', (WidgetTester tester) async {
    final List<KickRecord> history = <KickRecord>[
      kickRecord(MatchSide.player, 1, goal: true),
      kickRecord(MatchSide.opponent, 1, goal: false),
      kickRecord(MatchSide.player, 2, goal: false),
    ];
    await tester.pumpWidget(harness(hud(viewOf(
      state: stateOf(playerScore: 1, playerKicks: 2, opponentKicks: 1),
      history: history,
    ))));
    expect(find.byWidgetPredicate((Widget w) => hasIcon(w, AppIcons.check)), findsNWidgets(1));
    expect(find.byWidgetPredicate((Widget w) => hasIcon(w, AppIcons.close)), findsNWidgets(2));
    final SemanticsHandle h = tester.ensureSemantics();
    expect(find.bySemanticsLabel('To come'), findsNWidgets(3 + 4));
    expect(find.bySemanticsLabel('Scored'), findsOneWidget);
    expect(find.bySemanticsLabel('Missed'), findsNWidgets(2));
    h.dispose();
  });

  testWidgets('sudden death adds more slots and a labelled chip', (WidgetTester tester) async {
    final MatchState tied = stateOf(
      playerScore: 3,
      opponentScore: 3,
      playerKicks: 5,
      opponentKicks: 5,
    );
    expect(tied.isSuddenDeath, isTrue);
    await tester.pumpWidget(harness(hud(viewOf(state: tied))));
    expect(find.text('Sudden death'), findsOneWidget);
    await tester.pumpWidget(harness(hud(viewOf())));
    expect(find.text('Sudden death'), findsNothing);
  });

  testWidgets('Selah is pressable only when allowed, and says how many are left', (WidgetTester tester) async {
    int used = 0;
    await tester.pumpWidget(harness(hud(viewOf(), onSelah: () => used++)));
    expect(find.text('Selah · 3'), findsOneWidget);
    await tester.tap(find.text('Selah · 3'));
    expect(used, 1);
    final SemanticsHandle h = tester.ensureSemantics();
    expect(find.bySemanticsLabel('Selah, 3 left'), findsOneWidget);
    h.dispose();

    await tester.pumpWidget(harness(hud(viewOf(canUseSelah: false), onSelah: () => used++)));
    await tester.tap(find.text('Selah · 3'));
    expect(used, 1);

    await tester.pumpWidget(harness(hud(viewOf(), onSelah: () => used++, enabled: false)));
    await tester.tap(find.text('Selah · 3'));
    expect(used, 1);
  });

  testWidgets('pause fires', (WidgetTester tester) async {
    int paused = 0;
    await tester.pumpWidget(harness(hud(viewOf(), onPause: () => paused++)));
    await tester.tap(find.byType(IconChip));
    expect(paused, 1);
  });

  testWidgets('the HUD stays out of the way: empty areas pass touches through', (WidgetTester tester) async {
    int taps = 0;
    await tester.pumpWidget(harness(
      Stack(
        children: <Widget>[
          Positioned.fill(
            child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => taps++),
          ),
          Positioned.fill(child: hud(viewOf())),
        ],
      ),
    ));
    await tester.tapAt(tester.getCenter(find.byType(MatchHud)));
    expect(taps, 1);
  });

  for (final TextDirection d in TextDirection.values) {
    testWidgets('holds at 3.1x text, $d', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        hud(viewOf(
          state: stateOf(playerScore: 3, opponentScore: 3, playerKicks: 5, opponentKicks: 5, nerve: 0.9),
          history: <KickRecord>[
            for (int i = 1; i <= 5; i++) kickRecord(MatchSide.player, i, goal: i.isEven),
            for (int i = 1; i <= 5; i++) kickRecord(MatchSide.opponent, i, goal: i.isOdd),
          ],
        )),
        textScale: 3.1,
        direction: d,
        size: const Size(360, 720),
      ));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('works with a real match from the provider', (WidgetTester tester) async {
    final MatchProvider match = MatchProvider(FakeLog());
    addTearDown(match.dispose);
    match.start(configFor(seed: 4));
    await tester.pumpWidget(harness(hud(match.value)));
    expect(find.text('You'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
