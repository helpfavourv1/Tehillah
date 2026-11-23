import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/input/flick_strategy.dart';
import 'package:tehillah/core/input/timing_bar_strategy.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/shot_params.dart';
import 'package:tehillah/game/geometry/pitch_projection.dart';
import 'package:tehillah/game/input/dive_layer.dart';
import 'package:tehillah/game/input/flick_layer.dart';
import 'package:tehillah/game/input/timing_bar_layer.dart';
import 'package:tehillah/game/input/zone_grid.dart';
import 'package:tehillah/theme/tokens.dart';
import 'package:tehillah/widgets/pressable.dart';

import '../support/widget_harness.dart';

String zoneName(int c, int r) => 'zone $c $r';

PitchProjection projectionFor(Size s) => PitchProjection.fit(s.width, s.height);

/// Turns a point in the layer's own space into a global one.
Offset at(WidgetTester tester, Finder layer, double x, double y) =>
    tester.getTopLeft(layer) + Offset(x, y);

void main() {
  group('ZoneGrid', () {
    for (final Size size in const <Size>[Size(360, 720), Size(800, 360), Size(412, 560)]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}: six zones, each at least 48 high, none overlapping',
          (WidgetTester tester) async {
        await tester.pumpWidget(harness(
          SizedBox.expand(
            child: ZoneGrid(
              projection: projectionFor(size),
              zoneLabel: zoneName,
              onSelect: (int c, int r) {},
            ),
          ),
          size: size,
        ));
        final List<Rect> rects = <Rect>[
          for (final Element e in find.byType(Pressable).evaluate())
            (e.renderObject! as RenderBox).localToGlobal(Offset.zero) &
                (e.renderObject! as RenderBox).size,
        ];
        expect(rects.length, 6);
        for (final Rect r in rects) {
          expect(r.height, greaterThanOrEqualTo(Metrics.touchTarget - 0.01));
        }
        for (int i = 0; i < rects.length; i++) {
          for (int j = i + 1; j < rects.length; j++) {
            final Rect overlap = rects[i].intersect(rects[j]);
            expect(overlap.width <= 0.5 || overlap.height <= 0.5, isTrue, reason: '$i $j');
          }
        }
      });
    }

    testWidgets('tapping the middle of the drawn goal zone selects that zone', (WidgetTester tester) async {
      const Size size = Size(360, 720);
      final PitchProjection p = projectionFor(size);
      final List<String> picked = <String>[];
      await tester.pumpWidget(harness(
        SizedBox.expand(
          child: ZoneGrid(
            projection: p,
            zoneLabel: zoneName,
            onSelect: (int c, int r) => picked.add('$c$r'),
          ),
        ),
        size: size,
      ));
      final Finder layer = find.byType(ZoneGrid);
      for (int r = 0; r < 2; r++) {
        for (int c = 0; c < 3; c++) {
          final ScreenRect z = p.zoneRect(c, r, columns: 3, rows: 2);
          await tester.tapAt(at(tester, layer, (z.left + z.right) / 2, (z.top + z.bottom) / 2));
        }
      }
      expect(picked, <String>['00', '10', '20', '01', '11', '21']);
    });

    testWidgets('a short lower zone can be hit just below the goal, the upper just above',
        (WidgetTester tester) async {
      const Size size = Size(800, 360);
      final PitchProjection p = projectionFor(size);
      final List<String> picked = <String>[];
      await tester.pumpWidget(harness(
        SizedBox.expand(
          child: ZoneGrid(
            projection: p,
            zoneLabel: zoneName,
            onSelect: (int c, int r) => picked.add('$c$r'),
          ),
        ),
        size: size,
      ));
      final Finder layer = find.byType(ZoneGrid);
      final ScreenRect low = p.zoneRect(1, 0, columns: 3, rows: 2);
      final ScreenRect high = p.zoneRect(1, 1, columns: 3, rows: 2);
      expect(low.bottom - low.top, lessThan(Metrics.touchTarget));
      await tester.tapAt(at(tester, layer, (low.left + low.right) / 2, low.bottom + 20));
      await tester.tapAt(at(tester, layer, (high.left + high.right) / 2, high.top - 20));
      expect(picked, <String>['10', '11']);
    });

    testWidgets('without onSelect the zones are display-only', (WidgetTester tester) async {
      await tester.pumpWidget(harness(
        SizedBox.expand(
          child: ZoneGrid(projection: projectionFor(const Size(360, 720)), zoneLabel: zoneName, onSelect: null),
        ),
      ));
      await tester.tapAt(tester.getCenter(find.byType(ZoneGrid)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('each zone has its label for screen readers', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await tester.pumpWidget(harness(
        SizedBox.expand(
          child: ZoneGrid(projection: projectionFor(const Size(360, 720)), zoneLabel: zoneName, onSelect: (int c, int r) {}),
        ),
      ));
      expect(find.bySemanticsLabel('zone 2 1'), findsOneWidget);
      expect(find.bySemanticsLabel('zone 0 0'), findsOneWidget);
      h.dispose();
    });
  });

  group('DiveLayer', () {
    test('the six zones map to the six dives', () {
      expect(diveForZone(0, 0), KeeperDive.leftLow);
      expect(diveForZone(0, 1), KeeperDive.leftHigh);
      expect(diveForZone(1, 0), KeeperDive.centerLow);
      expect(diveForZone(1, 1), KeeperDive.centerHigh);
      expect(diveForZone(2, 0), KeeperDive.rightLow);
      expect(diveForZone(2, 1), KeeperDive.rightHigh);
    });

    testWidgets('tapping a zone dives there; disabled draws nothing', (WidgetTester tester) async {
      const Size size = Size(360, 720);
      final PitchProjection p = projectionFor(size);
      final List<KeeperDive> dives = <KeeperDive>[];
      Widget build({required bool enabled}) => harness(
            SizedBox.expand(
              child: DiveLayer(projection: p, zoneLabel: zoneName, onDive: dives.add, enabled: enabled),
            ),
            size: size,
          );
      await tester.pumpWidget(build(enabled: true));
      final ScreenRect z = p.zoneRect(2, 1, columns: 3, rows: 2);
      await tester.tapAt(at(tester, find.byType(DiveLayer), (z.left + z.right) / 2, (z.top + z.bottom) / 2));
      expect(dives, <KeeperDive>[KeeperDive.rightHigh]);
      await tester.pumpWidget(build(enabled: false));
      expect(find.byType(Pressable), findsNothing);
    });
  });

  group('FlickLayer', () {
    Future<(FlickStrategy, List<ShotParams>, List<int>)> pump(
      WidgetTester tester, {
      bool enabled = true,
    }) async {
      final FlickStrategy strategy = FlickStrategy();
      final List<ShotParams> shots = <ShotParams>[];
      final List<int> rejected = <int>[];
      strategy.shots.listen(shots.add);
      addTearDown(strategy.dispose);
      await tester.pumpWidget(harness(
        SizedBox.expand(
          child: FlickLayer(
            strategy: strategy,
            semanticLabel: 'Swipe up',
            enabled: enabled,
            onRejected: () => rejected.add(1),
          ),
        ),
      ));
      return (strategy, shots, rejected);
    }

    testWidgets('a clean swipe up makes a shot', (WidgetTester tester) async {
      final (FlickStrategy _, List<ShotParams> shots, List<int> rejected) = await pump(tester);
      final Offset start = tester.getCenter(find.byType(FlickLayer)) + const Offset(0, 200);
      final TestGesture g = await tester.startGesture(start);
      await g.moveBy(const Offset(0, -60), timeStamp: const Duration(milliseconds: 50));
      await g.moveBy(const Offset(0, -60), timeStamp: const Duration(milliseconds: 100));
      await g.up(timeStamp: const Duration(milliseconds: 100));
      expect(shots.length, 1);
      expect(shots.single.direction.abs(), lessThan(0.05));
      expect(shots.single.power, greaterThan(0));
      expect(rejected, isEmpty);
    });

    testWidgets('a swipe to the right aims right', (WidgetTester tester) async {
      final (FlickStrategy _, List<ShotParams> shots, List<int> _) = await pump(tester);
      final Offset start = tester.getCenter(find.byType(FlickLayer)) + const Offset(0, 200);
      final TestGesture g = await tester.startGesture(start);
      await g.moveBy(const Offset(40, -60), timeStamp: const Duration(milliseconds: 50));
      await g.moveBy(const Offset(40, -60), timeStamp: const Duration(milliseconds: 100));
      await g.up(timeStamp: const Duration(milliseconds: 100));
      expect(shots.single.direction, greaterThan(0.3));
    });

    testWidgets('a tiny swipe is rejected and says so', (WidgetTester tester) async {
      final (FlickStrategy _, List<ShotParams> shots, List<int> rejected) = await pump(tester);
      final TestGesture g = await tester.startGesture(tester.getCenter(find.byType(FlickLayer)));
      await g.moveBy(const Offset(0, -8), timeStamp: const Duration(milliseconds: 40));
      await g.up(timeStamp: const Duration(milliseconds: 40));
      expect(shots, isEmpty);
      expect(rejected.length, 1);
    });

    testWidgets('a swipe downwards is rejected', (WidgetTester tester) async {
      final (FlickStrategy _, List<ShotParams> shots, List<int> rejected) = await pump(tester);
      final TestGesture g = await tester.startGesture(tester.getCenter(find.byType(FlickLayer)));
      await g.moveBy(const Offset(0, 120), timeStamp: const Duration(milliseconds: 80));
      await g.up(timeStamp: const Duration(milliseconds: 80));
      expect(shots, isEmpty);
      expect(rejected.length, 1);
    });

    testWidgets('only the first finger counts', (WidgetTester tester) async {
      final (FlickStrategy _, List<ShotParams> shots, List<int> _) = await pump(tester);
      final Offset start = tester.getCenter(find.byType(FlickLayer)) + const Offset(0, 200);
      final TestGesture first = await tester.startGesture(start);
      final TestGesture second = await tester.startGesture(start + const Offset(60, 0));
      await second.moveBy(const Offset(0, -200), timeStamp: const Duration(milliseconds: 80));
      await second.up(timeStamp: const Duration(milliseconds: 80));
      expect(shots, isEmpty);
      await first.moveBy(const Offset(0, -120), timeStamp: const Duration(milliseconds: 90));
      await first.up(timeStamp: const Duration(milliseconds: 90));
      expect(shots.length, 1);
    });

    testWidgets('a cancelled touch makes nothing and does not count as rejected', (WidgetTester tester) async {
      final (FlickStrategy s, List<ShotParams> shots, List<int> rejected) = await pump(tester);
      final TestGesture g = await tester.startGesture(tester.getCenter(find.byType(FlickLayer)));
      await g.moveBy(const Offset(0, -100), timeStamp: const Duration(milliseconds: 50));
      await g.cancel();
      expect(shots, isEmpty);
      expect(rejected, isEmpty);
      expect(s.isActive, isFalse);
    });

    testWidgets('disabled ignores the swipe', (WidgetTester tester) async {
      final (FlickStrategy _, List<ShotParams> shots, List<int> rejected) = await pump(tester, enabled: false);
      final TestGesture g = await tester.startGesture(tester.getCenter(find.byType(FlickLayer)) + const Offset(0, 100));
      await g.moveBy(const Offset(0, -120), timeStamp: const Duration(milliseconds: 80));
      await g.up(timeStamp: const Duration(milliseconds: 80));
      expect(shots, isEmpty);
      expect(rejected, isEmpty);
    });

    testWidgets('being disabled mid-swipe abandons it', (WidgetTester tester) async {
      final FlickStrategy strategy = FlickStrategy();
      addTearDown(strategy.dispose);
      Widget build(bool enabled) => harness(
            SizedBox.expand(
              child: FlickLayer(strategy: strategy, semanticLabel: 'x', enabled: enabled),
            ),
          );
      await tester.pumpWidget(build(true));
      final TestGesture g = await tester.startGesture(tester.getCenter(find.byType(FlickLayer)) + const Offset(0, 100));
      await g.moveBy(const Offset(0, -50), timeStamp: const Duration(milliseconds: 40));
      expect(strategy.isActive, isTrue);
      await tester.pumpWidget(build(false));
      expect(strategy.isActive, isFalse);
      await g.up(timeStamp: const Duration(milliseconds: 80));
    });

    testWidgets('the area is described for screen readers', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pump(tester);
      expect(find.bySemanticsLabel('Swipe up'), findsOneWidget);
      h.dispose();
    });
  });

  group('TimingBarLayer', () {
    const Size size = Size(360, 720);

    Future<(TimingBarStrategy, List<ShotParams>)> pump(WidgetTester tester, {bool enabled = true}) async {
      final TimingBarStrategy strategy = TimingBarStrategy();
      final List<ShotParams> shots = <ShotParams>[];
      strategy.shots.listen(shots.add);
      addTearDown(strategy.dispose);
      await tester.pumpWidget(harness(
        SizedBox.expand(
          child: TimingBarLayer(
            strategy: strategy,
            projection: projectionFor(size),
            zoneLabel: zoneName,
            stopLabel: 'Tap to stop',
            enabled: enabled,
          ),
        ),
        size: size,
      ));
      return (strategy, shots);
    }

    Future<void> pickZone(WidgetTester tester, int c, int r) async {
      final ScreenRect z = projectionFor(size).zoneRect(c, r, columns: 3, rows: 2);
      await tester.tapAt(at(tester, find.byType(TimingBarLayer), (z.left + z.right) / 2, (z.top + z.bottom) / 2));
      await tester.pump();
    }

    testWidgets('picking a zone starts the bar; a tap stops it and makes the shot', (WidgetTester tester) async {
      final (TimingBarStrategy s, List<ShotParams> shots) = await pump(tester);
      expect(find.text('Tap to stop'), findsNothing);
      await pickZone(tester, 2, 1);
      expect(s.phase, TimingPhase.running);
      expect(s.column, 2);
      expect(s.row, 1);
      expect(find.text('Tap to stop'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      expect(s.position, greaterThan(0));
      await tester.tapAt(tester.getCenter(find.byType(TimingBarLayer)));
      await tester.pump();
      expect(shots.length, 1);
      expect(shots.single.direction, greaterThan(0));
      expect(s.phase, TimingPhase.aiming);
      expect(find.text('Tap to stop'), findsNothing);
    });

    testWidgets('the bar moves while it runs', (WidgetTester tester) async {
      final (TimingBarStrategy s, List<ShotParams> _) = await pump(tester);
      await pickZone(tester, 1, 0);
      await tester.pump(const Duration(milliseconds: 100));
      final double early = s.position;
      await tester.pump(const Duration(milliseconds: 300));
      expect(s.position, isNot(early));
      await tester.tapAt(tester.getCenter(find.byType(TimingBarLayer)));
      await tester.pump();
    });

    testWidgets('a second tap on a zone while running does nothing new', (WidgetTester tester) async {
      final (TimingBarStrategy s, List<ShotParams> shots) = await pump(tester);
      await pickZone(tester, 0, 0);
      expect(s.column, 0);
      await tester.tapAt(tester.getCenter(find.byType(TimingBarLayer)));
      await tester.pump();
      expect(shots.length, 1);
    });

    testWidgets('disabled draws nothing and a running bar is reset', (WidgetTester tester) async {
      final TimingBarStrategy strategy = TimingBarStrategy();
      addTearDown(strategy.dispose);
      Widget build(bool enabled) => harness(
            SizedBox.expand(
              child: TimingBarLayer(
                strategy: strategy,
                projection: projectionFor(size),
                zoneLabel: zoneName,
                stopLabel: 'Tap to stop',
                enabled: enabled,
              ),
            ),
            size: size,
          );
      await tester.pumpWidget(build(true));
      await pickZone(tester, 1, 1);
      expect(strategy.phase, TimingPhase.running);
      await tester.pumpWidget(build(false));
      expect(strategy.phase, TimingPhase.aiming);
      expect(find.byType(Pressable), findsNothing);
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('the stop target is announced as a button', (WidgetTester tester) async {
      final SemanticsHandle h = tester.ensureSemantics();
      await pump(tester);
      await pickZone(tester, 1, 0);
      expect(find.bySemanticsLabel('Tap to stop'), findsWidgets);
      await tester.tapAt(tester.getCenter(find.byType(TimingBarLayer)));
      await tester.pump();
      h.dispose();
    });

    testWidgets('holds in right to left and at 3.1x text', (WidgetTester tester) async {
      final TimingBarStrategy strategy = TimingBarStrategy();
      addTearDown(strategy.dispose);
      await tester.pumpWidget(harness(
        SizedBox.expand(
          child: TimingBarLayer(
            strategy: strategy,
            projection: projectionFor(size),
            zoneLabel: zoneName,
            stopLabel: 'Tap to stop and keep the ball inside the goal',
          ),
        ),
        size: size,
        direction: TextDirection.rtl,
        textScale: 3.1,
      ));
      await pickZone(tester, 1, 0);
      expect(tester.takeException(), isNull);
      await tester.tapAt(tester.getCenter(find.byType(TimingBarLayer)));
      await tester.pump();
    });
  });
}
