import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/game/input/sling_aim_layer.dart';
import 'package:tehillah/game/sling_controller.dart';
import 'package:tehillah/game/sling_game.dart';
import 'package:tehillah/screens/sling_screen.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/icon_chip.dart';
import 'package:tehillah/widgets/star_row.dart';

import '../support/test_surface.dart';
import '../support/widget_harness.dart';

String _targets(int h, int t) => '$h of $t';
String _stars(int s, int t) => '$s of $t stars';
String _summary(int h, int t) => 'You hit $h of $t targets.';

const SlingLabels labels = SlingLabels(
  pause: 'Pause',
  pauseTitle: 'Paused',
  resume: 'Resume',
  leave: 'Leave',
  stones: 'Stones',
  targets: 'Targets',
  targetsValue: _targets,
  aimHint: 'Drag to aim, lift to throw',
  aimArea: 'Aim at the targets',
  roundDone: 'Round over',
  roundPerfect: 'Every target down',
  starsLabel: _stars,
  playAgain: 'Play again',
  extraStones: 'Watch for 3 more stones',
  summary: _summary,
);

const Size surface = Size(360, 640);

class Rig {
  Rig({this.watch}) {
    game = SlingGame(palette: AppPalette.light);
    controller = SlingController(world: game.scene);
  }

  late final SlingGame game;
  late final SlingController controller;
  final Future<bool> Function()? watch;
  final List<int> again = <int>[];
  final List<int> left = <int>[];
  int quit = 0;

  void dispose() => controller.dispose();
}

Widget host(Rig rig, {double textScale = 1, TextDirection d = TextDirection.ltr, PaletteMode mode = PaletteMode.light}) {
  return harness(
    SizedBox.expand(
      child: Navigator(
        onGenerateRoute: (RouteSettings settings) => PageRouteBuilder<void>(
          settings: settings,
          pageBuilder: (BuildContext c, Animation<double> a, Animation<double> s) => SlingScreen(
            labels: labels,
            controller: rig.controller,
            game: rig.game,
            onPlayAgain: rig.again.add,
            onLeave: rig.left.add,
            onQuit: () => rig.quit++,
            onWatchForStones: rig.watch,
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

Future<Rig> pumpScreen(WidgetTester tester, {Future<bool> Function()? watch, double textScale = 1}) async {
  useSurface(tester, surface);
  final Rig rig = Rig(watch: watch);
  addTearDown(rig.dispose);
  await tester.pumpWidget(host(rig, textScale: textScale));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  rig.controller.start(3);
  await tester.pump();
  return rig;
}

Future<void> slide(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> leave(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

/// Throws a stone at the top edge (always a miss) and lets it land.
Future<void> missOnce(WidgetTester tester, Rig rig) async {
  rig.controller.release(direction: 0, elevation: 1);
  for (int i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Future<void> endRound(WidgetTester tester, Rig rig) async {
  for (int i = 0; i < 7; i++) {
    await missOnce(tester, rig);
  }
}

void main() {
  testWidgets('shows the stones, the targets and the aiming hint', (WidgetTester tester) async {
    final Rig rig = await pumpScreen(tester);
    expect(find.text('Stones'), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(find.text('0 of 5'), findsOneWidget);
    expect(find.text('Drag to aim, lift to throw'), findsOneWidget);
    expect(find.byType(SlingAimLayer), findsOneWidget);
    expect(rig.controller.inputEnabled.value, isTrue);
    await leave(tester);
  });

  testWidgets('a throw updates the stones when the stone lands', (WidgetTester tester) async {
    final Rig rig = await pumpScreen(tester);
    await missOnce(tester, rig);
    expect(find.text('6'), findsOneWidget);
    await leave(tester);
  });

  testWidgets('a real drag and release throws a stone', (WidgetTester tester) async {
    final Rig rig = await pumpScreen(tester);
    final TestGesture g = await tester.startGesture(const Offset(180, 300));
    await g.moveTo(const Offset(190, 290));
    await g.up();
    expect(rig.controller.state.value!.thrown, 0);
    expect(rig.game.scene.flight, isNotNull);
    for (int i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(rig.controller.state.value!.thrown, 1);
    await leave(tester);
  });

  testWidgets('the end panel appears when the stones run out, with stars and buttons', (WidgetTester tester) async {
    final Rig rig = await pumpScreen(tester);
    await endRound(tester, rig);
    expect(find.text('Round over'), findsOneWidget);
    expect(find.text('You hit 0 of 5 targets.'), findsOneWidget);
    expect(find.byType(StarRow), findsOneWidget);
    expect(find.text('Play again'), findsOneWidget);
    expect(find.text('Leave'), findsOneWidget);
    expect(find.byType(SlingAimLayer), findsNothing);
    expect(find.text('Drag to aim, lift to throw'), findsNothing);
    await leave(tester);
  });

  testWidgets('Play again and Leave report the stars once each', (WidgetTester tester) async {
    final Rig rig = await pumpScreen(tester);
    await endRound(tester, rig);
    await tester.tap(find.text('Play again'));
    await tester.tap(find.text('Leave'));
    expect(rig.again, <int>[0]);
    expect(rig.left, <int>[0]);
    expect(rig.quit, 0);
    await leave(tester);
  });

  testWidgets('with no rewarded ad there is no extra-stones button', (WidgetTester tester) async {
    final Rig rig = await pumpScreen(tester);
    await endRound(tester, rig);
    expect(find.text('Watch for 3 more stones'), findsNothing);
    await leave(tester);
  });

  testWidgets('an earned reward adds three stones and reopens the round', (WidgetTester tester) async {
    final Rig rig = await pumpScreen(tester, watch: () async => true);
    await endRound(tester, rig);
    await tester.tap(find.text('Watch for 3 more stones'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Round over'), findsNothing);
    expect(find.text('3'), findsOneWidget);
    expect(rig.controller.inputEnabled.value, isTrue);
    await leave(tester);
  });

  testWidgets('a reward that is not earned leaves the panel as it was', (WidgetTester tester) async {
    final Rig rig = await pumpScreen(tester, watch: () async => false);
    await endRound(tester, rig);
    await tester.tap(find.text('Watch for 3 more stones'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Round over'), findsOneWidget);
    expect(rig.controller.state.value!.stonesLeft, 0);
    await leave(tester);
  });

  testWidgets('the extra-stones offer is gone after it has been used', (WidgetTester tester) async {
    final Rig rig = await pumpScreen(tester, watch: () async => true);
    await endRound(tester, rig);
    await tester.tap(find.text('Watch for 3 more stones'));
    await tester.pump();
    await tester.pump();
    for (int i = 0; i < 3; i++) {
      await missOnce(tester, rig);
    }
    expect(find.text('Round over'), findsOneWidget);
    expect(find.text('Watch for 3 more stones'), findsNothing);
    await leave(tester);
  });

  testWidgets('pause opens a sheet and holds the round; Resume carries on', (WidgetTester tester) async {
    final Rig rig = await pumpScreen(tester);
    await tester.tap(find.byType(IconChip));
    await slide(tester);
    expect(find.text('Paused'), findsOneWidget);
    expect(rig.controller.isPaused, isTrue);
    expect(rig.controller.inputEnabled.value, isFalse);
    await tester.tap(find.text('Resume'));
    await slide(tester);
    expect(find.text('Paused'), findsNothing);
    expect(rig.controller.isPaused, isFalse);
    expect(rig.controller.inputEnabled.value, isTrue);
    expect(rig.quit, 0);
    await leave(tester);
  });

  testWidgets('Leave from the pause sheet quits and records nothing', (WidgetTester tester) async {
    final Rig rig = await pumpScreen(tester);
    await tester.tap(find.byType(IconChip));
    await slide(tester);
    await tester.tap(find.text('Leave'));
    await slide(tester);
    expect(rig.quit, 1);
    expect(rig.again, isEmpty);
    expect(rig.left, isEmpty);
    await leave(tester);
  });

  testWidgets('the pause chip is a labelled 48 point target', (WidgetTester tester) async {
    final SemanticsHandle h = tester.ensureSemantics();
    await pumpScreen(tester);
    expect(find.bySemanticsLabel('Pause'), findsOneWidget);
    final Size s = tester.getSize(find.byType(IconChip));
    expect(s.width, greaterThanOrEqualTo(Metrics.touchTarget));
    expect(s.height, greaterThanOrEqualTo(Metrics.touchTarget));
    h.dispose();
    await leave(tester);
  });

  for (final PaletteMode mode in PaletteMode.values) {
    for (final TextDirection d in TextDirection.values) {
      testWidgets('the end panel holds at 3.1x text, $mode, $d', (WidgetTester tester) async {
        useSurface(tester, surface);
        final Rig rig = Rig(watch: () async => true);
        addTearDown(rig.dispose);
        await tester.pumpWidget(host(rig, textScale: 3.1, d: d, mode: mode));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        rig.controller.start(3);
        await tester.pump();
        await endRound(tester, rig);
        expect(find.text('Round over'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await leave(tester);
      });
    }
  }
}
