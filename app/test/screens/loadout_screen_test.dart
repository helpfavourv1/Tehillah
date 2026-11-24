import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/catalog/ball_catalog.dart';
import 'package:tehillah/core/catalog/gear_catalog.dart';
import 'package:tehillah/core/models/loadout.dart';
import 'package:tehillah/providers/loadout_provider.dart';
import 'package:tehillah/screens/loadout_screen.dart';
import 'package:tehillah/theme/app_icon.dart';
import 'package:tehillah/theme/icon_aliases.dart';
import 'package:tehillah/theme/tokens.dart';

import '../support/test_surface.dart';
import '../support/widget_harness.dart';
import 'screen_labels.dart';

LoadoutState stateWith({
  Loadout selected = Loadout.starter,
  Set<String> balls = const <String>{'love'},
  Set<String> gear = const <String>{},
}) =>
    LoadoutState(selected: selected, unlockedBalls: balls, unlockedGear: gear);

Widget screen(
  ValueNotifier<LoadoutState> s, {
  List<String>? log,
}) {
  return LoadoutScreen(
    labels: loadoutLabels,
    state: s,
    onSelectBall: (String id) => log?.add('ball:$id'),
    onSelectGear: (String? id) => log?.add('gear:$id'),
    onBack: () => log?.add('back'),
  );
}

Future<void> tapAfterScroll(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await tester.pump();
}

void main() {
  testWidgets('lists every ball and every piece of gear with what it gives and costs', (WidgetTester tester) async {
    final ValueNotifier<LoadoutState> s = ValueNotifier<LoadoutState>(stateWith());
    addTearDown(s.dispose);
    await tester.pumpWidget(harness(screen(s)));
    for (final b in BallCatalog.all) {
      expect(find.text('Ball ${b.id}'), findsOneWidget);
      expect(find.textContaining('Benefit: gain ${b.id}'), findsOneWidget);
      expect(find.textContaining('Trade-off: cost ${b.id}'), findsOneWidget);
    }
    for (final g in GearCatalog.all) {
      expect(find.text('Gear ${g.id}'), findsOneWidget);
    }
    expect(find.text('No gear'), findsOneWidget);
  });

  testWidgets('the chosen ball says Selected in words and shows a tick', (WidgetTester tester) async {
    final ValueNotifier<LoadoutState> s = ValueNotifier<LoadoutState>(stateWith());
    addTearDown(s.dispose);
    await tester.pumpWidget(harness(screen(s)));
    expect(find.text('Selected'), findsNWidgets(2));
    expect(find.byWidgetPredicate((Widget w) => w is AppIcon && w.symbol == AppIcons.check), findsNWidgets(2));
  });

  testWidgets('locked items say how many lamps and cannot be chosen', (WidgetTester tester) async {
    useSurface(tester);
    final ValueNotifier<LoadoutState> s = ValueNotifier<LoadoutState>(stateWith());
    addTearDown(s.dispose);
    final List<String> log = <String>[];
    await tester.pumpWidget(harness(screen(s, log: log)));
    final int lockedBalls = BallCatalog.all.where((b) => b.unlockLamps > 0).length;
    expect(find.byWidgetPredicate((Widget w) => w is AppIcon && w.symbol == AppIcons.locked),
        findsNWidgets(lockedBalls + GearCatalog.all.length));
    expect(find.textContaining('Earn 1 lamps to unlock'), findsWidgets);
    await tapAfterScroll(tester, find.text('Ball ${BallCatalog.all[1].id}'));
    await tapAfterScroll(tester, find.text('Gear ${GearCatalog.all.first.id}'));
    expect(log, isEmpty);
  });

  testWidgets('unlocked items can be chosen, and No gear clears the gear', (WidgetTester tester) async {
    useSurface(tester);
    final ValueNotifier<LoadoutState> s = ValueNotifier<LoadoutState>(stateWith(
      balls: <String>{'love', BallCatalog.all[1].id},
      gear: <String>{GearCatalog.all.first.id},
    ));
    addTearDown(s.dispose);
    final List<String> log = <String>[];
    await tester.pumpWidget(harness(screen(s, log: log)));
    await tapAfterScroll(tester, find.text('Ball ${BallCatalog.all[1].id}'));
    await tapAfterScroll(tester, find.text('Gear ${GearCatalog.all.first.id}'));
    await tapAfterScroll(tester, find.text('No gear'));
    expect(log, <String>['ball:${BallCatalog.all[1].id}', 'gear:${GearCatalog.all.first.id}', 'gear:null']);
  });

  testWidgets('it follows the provider when the choice changes', (WidgetTester tester) async {
    final ValueNotifier<LoadoutState> s = ValueNotifier<LoadoutState>(stateWith(
      balls: <String>{'love', BallCatalog.all[1].id},
    ));
    addTearDown(s.dispose);
    await tester.pumpWidget(harness(screen(s)));
    s.value = stateWith(
      selected: Loadout(ballId: BallCatalog.all[1].id),
      balls: <String>{'love', BallCatalog.all[1].id},
    );
    await tester.pump();
    expect(find.text('Selected'), findsNWidgets(2));
    expect(find.byWidgetPredicate((Widget w) => w is AppIcon && w.symbol == AppIcons.check), findsNWidgets(2));
    expect(find.text('Selected').evaluate().length, 2);
  });

  testWidgets('back reaches its callback', (WidgetTester tester) async {
    final ValueNotifier<LoadoutState> s = ValueNotifier<LoadoutState>(stateWith());
    addTearDown(s.dispose);
    final List<String> log = <String>[];
    final SemanticsHandle h = tester.ensureSemantics();
    await tester.pumpWidget(harness(screen(s, log: log)));
    await tester.tap(find.bySemanticsLabel('Back'));
    expect(log, <String>['back']);
    h.dispose();
  });

  for (final PaletteMode mode in PaletteMode.values) {
    for (final TextDirection d in TextDirection.values) {
      testWidgets('holds at 3.1x text, $mode, $d', (WidgetTester tester) async {
        final ValueNotifier<LoadoutState> s = ValueNotifier<LoadoutState>(stateWith());
        addTearDown(s.dispose);
        await tester.pumpWidget(harness(screen(s), textScale: 3.1, direction: d, mode: mode));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
