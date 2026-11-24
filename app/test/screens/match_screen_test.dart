import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/settings_model.dart';
import 'package:tehillah/game/hud/match_hud.dart';
import 'package:tehillah/game/input/dive_layer.dart';
import 'package:tehillah/game/input/flick_layer.dart';
import 'package:tehillah/game/input/timing_bar_layer.dart';
import 'package:tehillah/game/match_controller.dart';
import 'package:tehillah/game/tehillah_game.dart';
import 'package:tehillah/providers/match_provider.dart';
import 'package:tehillah/screens/match_screen.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/icon_chip.dart';

import '../fakes/fake_storage.dart';
import '../support/match_helpers.dart';
import '../support/test_surface.dart';
import '../support/widget_harness.dart';

String _selahWith(int n) => 'Selah, $n left';
String _zone(int c, int r) => 'zone $c $r';

const MatchHudLabels hudLabels = MatchHudLabels(
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

const MatchScreenLabels screenLabels = MatchScreenLabels(
  hud: hudLabels,
  zoneLabel: _zone,
  flickHint: 'Swipe up toward the goal',
  stopLabel: 'Stop the bar',
  pauseTitle: 'Paused',
  resume: 'Resume',
  leave: 'Leave match',
);

const Size surface = Size(360, 640);

final class Rig {
  Rig({MatchMode mode = MatchMode.friendly, int seed = 3}) {
    match = MatchProvider(FakeLog());
    game = TehillahGame(palette: AppPalette.light);
    controller = MatchController(
      match: match,
      world: game.scene,
      autoKickDelay: const Duration(milliseconds: 100),
    );
    match.start(configFor(mode: mode, seed: seed));
  }

  late final MatchProvider match;
  late final TehillahGame game;
  late final MatchController controller;
  int finished = 0;
  int quit = 0;
  int rejected = 0;

  void dispose() {
    controller.dispose();
    match.dispose();
  }
}

Widget host(Rig rig, InputScheme scheme, {double textScale = 1, TextDirection d = TextDirection.ltr, PaletteMode mode = PaletteMode.light}) {
  return harness(
    SizedBox.expand(
      child: Navigator(
        onGenerateRoute: (RouteSettings settings) => PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (BuildContext c, Animation<double> a, Animation<double> s) => MatchScreen(
            labels: screenLabels,
            match: rig.match,
            controller: rig.controller,
            game: rig.game,
            scheme: scheme,
            onFinished: () => rig.finished++,
            onQuit: () => rig.quit++,
            onFlickRejected: () => rig.rejected++,
          ),
        ),
      ),
    ),
    size: surface,
    textScale: textScale,
    direction: d,
    mode: mode,
  );
}

Future<Rig> pumpScreen(
  WidgetTester tester, {
  MatchMode mode = MatchMode.friendly,
  InputScheme scheme = InputScheme.flick,
}) async {
  useSurface(tester, surface);
  final Rig rig = Rig(mode: mode);
  addTearDown(rig.dispose);
  await tester.pumpWidget(host(rig, scheme));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return rig;
}

Future<void> leave(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  testWidgets('draws the pitch, the HUD and the swipe area', (WidgetTester tester) async {
    final Rig rig = await pumpScreen(tester);
    expect(find.byType(GameWidget<TehillahGame>), findsOneWidget);
    expect(find.byType(MatchHud), findsOneWidget);
    expect(find.byType(FlickLayer), findsOneWidget);
    expect(find.text('Swipe to shoot'), findsOneWidget);
    expect(rig.game.palette, AppPalette.light);
    expect(tester.takeException(), isNull);
    await leave(tester);
  });

  testWidgets('a swipe takes the kick and closes input while it plays', (WidgetTester tester) async {
    final Rig rig = await pumpScreen(tester);
    final Offset start = tester.getCenter(find.byType(FlickLayer)) + const Offset(0, 200);
    final TestGesture g = await tester.startGesture(start);
    await g.moveBy(const Offset(0, -60), timeStamp: const Duration(milliseconds: 50));
    await g.moveBy(const Offset(0, -60), timeStamp: const Duration(milliseconds: 100));
    await g.up(timeStamp: const Duration(milliseconds: 100));
    await tester.pump();
    expect(rig.match.value.history.length, 1);
    expect(rig.controller.busy.value, isTrue);
    expect(find.byType(FlickLayer), findsNothing);
    await leave(tester);
  });

  testWidgets('a swipe that is too short is reported, not taken', (WidgetTester tester) async {
    final Rig rig = await pumpScreen(tester);
    final TestGesture g = await tester.startGesture(tester.getCenter(find.byType(FlickLayer)));
    await g.moveBy(const Offset(0, -8), timeStamp: const Duration(milliseconds: 40));
    await g.up(timeStamp: const Duration(milliseconds: 40));
    await tester.pump();
    expect(rig.match.value.history, isEmpty);
    expect(rig.rejected, 1);
    await leave(tester);
  });

  testWidgets('the timing bar scheme shows the bar instead of the swipe area', (WidgetTester tester) async {
    await pumpScreen(tester, scheme: InputScheme.timingBar);
    expect(find.byType(TimingBarLayer), findsOneWidget);
    expect(find.byType(FlickLayer), findsNothing);
    await leave(tester);
  });

  testWidgets('Watchman asks for a dive, and a zone tap dives', (WidgetTester tester) async {
    final SemanticsHandle h = tester.ensureSemantics();
    final Rig rig = await pumpScreen(tester, mode: MatchMode.watchman);
    expect(find.byType(DiveLayer), findsOneWidget);
    expect(find.byType(FlickLayer), findsNothing);
    expect(find.text('Choose where to dive'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('zone 1 1'));
    await tester.pump();
    expect(rig.match.value.history.length, 1);
    h.dispose();
    await leave(tester);
  });

  testWidgets('pause opens a sheet and holds the match; Resume carries on', (WidgetTester tester) async {
    final Rig rig = await pumpScreen(tester);
    await tester.tap(find.byType(IconChip));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Leave match'), findsOneWidget);
    expect(rig.controller.isPaused, isTrue);
    expect(rig.controller.inputEnabled.value, isFalse);
    await tester.tap(find.text('Resume'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Paused'), findsNothing);
    expect(rig.controller.isPaused, isFalse);
    expect(rig.controller.inputEnabled.value, isTrue);
    expect(rig.quit, 0);
    await leave(tester);
  });

  testWidgets('Leave tells the caller and does not resume', (WidgetTester tester) async {
    final Rig rig = await pumpScreen(tester);
    await tester.tap(find.byType(IconChip));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Leave match'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(rig.quit, 1);
    expect(rig.controller.isPaused, isTrue);
    await leave(tester);
  });

  testWidgets('a whole match played through the screen is reported finished once', (WidgetTester tester) async {
    final Rig rig = await pumpScreen(tester);
    for (int i = 0; i < 6000 && rig.finished == 0; i++) {
      if (rig.controller.inputEnabled.value) {
        rig.controller.submitShot(centreShot);
      }
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(rig.finished, 1);
    expect(rig.match.value.finished, isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(rig.finished, 1);
    await leave(tester);
  });

  testWidgets('leaving the screen detaches the controller', (WidgetTester tester) async {
    final Rig rig = await pumpScreen(tester);
    expect(rig.controller.isAttached, isTrue);
    await leave(tester);
    expect(rig.controller.isAttached, isFalse);
  });

  for (final PaletteMode mode in PaletteMode.values) {
    for (final TextDirection d in TextDirection.values) {
      testWidgets('holds at 3.1x text, $mode, $d', (WidgetTester tester) async {
        useSurface(tester, surface);
        final Rig rig = Rig();
        addTearDown(rig.dispose);
        await tester.pumpWidget(host(rig, InputScheme.flick, textScale: 3.1, d: d, mode: mode));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(tester.takeException(), isNull);
        await leave(tester);
      });
    }
  }
}
