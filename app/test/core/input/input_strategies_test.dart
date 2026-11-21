import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/input/flick_strategy.dart';
import 'package:tehillah/core/input/timing_bar_strategy.dart';
import 'package:tehillah/core/models/shot_params.dart';

ShotParams? _swipe(
  FlickStrategy s,
  double sx,
  double sy,
  double ex,
  double ey,
  int ms, {
  List<({double x, double y})> via = const <({double x, double y})>[],
}) {
  s.begin(sx, sy, 0);
  for (final ({double x, double y}) p in via) {
    s.update(p.x, p.y, ms ~/ 2);
  }
  return s.end(ex, ey, ms);
}

void main() {
  group('FlickStrategy', () {
    test('a straight fast swipe up aims at the middle with power', () {
      final FlickStrategy s = FlickStrategy();
      final ShotParams? shot = _swipe(s, 360, 1200, 360, 800, 100);
      expect(shot, isNotNull);
      expect(shot!.direction, closeTo(0, 1e-9));
      expect(shot.power, 1.0);
      expect(shot.curve, closeTo(0, 1e-9));
      expect(shot.elevation, closeTo((400 - 60) / (420 - 60), 1e-9));
    });

    test('swiping to the right aims right and to the left aims left', () {
      final FlickStrategy s = FlickStrategy();
      final ShotParams right = _swipe(s, 360, 1200, 480, 900, 200)!;
      final ShotParams left = _swipe(s, 360, 1200, 240, 900, 200)!;
      expect(right.direction, greaterThan(0.3));
      expect(left.direction, closeTo(-right.direction, 1e-9));
      expect(_swipe(s, 360, 1200, 1000, 900, 200)!.direction, 1.0);
    });

    test('a slow swipe has less power than a fast one', () {
      final FlickStrategy s = FlickStrategy();
      final ShotParams slow = _swipe(s, 360, 1200, 360, 900, 800)!;
      final ShotParams fast = _swipe(s, 360, 1200, 360, 900, 150)!;
      expect(slow.power, lessThan(fast.power));
      expect(slow.power, greaterThanOrEqualTo(0));
    });

    test('a longer swipe lifts the ball higher', () {
      final FlickStrategy s = FlickStrategy();
      final ShotParams shortSwipe = _swipe(s, 360, 1200, 360, 1120, 200)!;
      final ShotParams longSwipe = _swipe(s, 360, 1300, 360, 800, 200)!;
      expect(longSwipe.elevation, greaterThan(shortSwipe.elevation));
      expect(longSwipe.elevation, lessThanOrEqualTo(1));
    });

    test('a path that bows right curls right and one that bows left curls left', () {
      final FlickStrategy s = FlickStrategy();
      final ShotParams right = _swipe(s, 360, 1200, 360, 800, 200,
          via: <({double x, double y})>[(x: 420, y: 1000)])!;
      final ShotParams left = _swipe(s, 360, 1200, 360, 800, 200,
          via: <({double x, double y})>[(x: 300, y: 1000)])!;
      expect(right.curve, greaterThan(0.3));
      expect(left.curve, closeTo(-right.curve, 1e-9));
    });

    test('taps, sideways swipes, downward swipes and slow drags are ignored', () {
      final FlickStrategy s = FlickStrategy();
      expect(_swipe(s, 360, 1200, 365, 1190, 80), isNull);
      expect(_swipe(s, 360, 1200, 700, 1180, 200), isNull);
      expect(_swipe(s, 360, 1200, 360, 1500, 200), isNull);
      expect(_swipe(s, 360, 1200, 360, 800, 1500), isNull);
      expect(_swipe(s, 360, 1200, 360, 800, 0), isNull);
    });

    test('end without begin, and after cancel, gives nothing', () {
      final FlickStrategy s = FlickStrategy();
      expect(s.end(360, 800, 100), isNull);
      s.begin(360, 1200, 0);
      s.cancel();
      expect(s.isActive, isFalse);
      expect(s.end(360, 800, 150), isNull);
    });

    test('shots are sent on the stream in order', () async {
      final FlickStrategy s = FlickStrategy();
      final List<ShotParams> seen = <ShotParams>[];
      final sub = s.shots.listen(seen.add);
      _swipe(s, 360, 1200, 360, 800, 150);
      _swipe(s, 360, 1200, 480, 900, 200);
      _swipe(s, 360, 1200, 365, 1190, 80);
      expect(seen.length, 2);
      await sub.cancel();
      s.dispose();
    });
  });

  group('TimingBarStrategy', () {
    test('choosing a zone starts the bar, which sweeps up and down', () {
      final TimingBarStrategy t = TimingBarStrategy();
      expect(t.phase, TimingPhase.aiming);
      t.selectZone(2, 1);
      expect(t.phase, TimingPhase.running);
      t.tick(0);
      expect(t.position, 0);
      t.tick(550);
      expect(t.position, closeTo(0.5, 1e-9));
      t.tick(1100);
      expect(t.position, closeTo(1, 1e-9));
      t.tick(1650);
      expect(t.position, closeTo(0.5, 1e-9));
      t.tick(2200);
      expect(t.position, closeTo(0, 1e-9));
    });

    test('a faster bar moves further in the same time', () {
      final TimingBarStrategy slow = TimingBarStrategy(speedFactor: 0.5)..selectZone(1, 0);
      final TimingBarStrategy fast = TimingBarStrategy(speedFactor: 2)..selectZone(1, 0);
      slow.tick(300);
      fast.tick(300);
      expect(fast.position, greaterThan(slow.position));
    });

    test('stopping at the sweet spot gives a clean shot to the chosen zone', () {
      final TimingBarStrategy t = TimingBarStrategy()..selectZone(0, 1);
      t.tick((0.78 * 1100).round());
      final ShotParams shot = t.stop()!;
      expect(shot.direction, closeTo(-0.8, 1e-3));
      expect(shot.elevation, closeTo(0.75, 1e-9));
      expect(shot.power, closeTo(0.78, 1e-3));
      expect(t.phase, TimingPhase.aiming);
    });

    test('a weak strike pulls the ball toward the middle and a top-of-bar strike skies it', () {
      final TimingBarStrategy weak = TimingBarStrategy()..selectZone(2, 0);
      weak.tick(200);
      expect(weak.stop()!.direction, lessThan(0.8));
      final TimingBarStrategy top = TimingBarStrategy()..selectZone(1, 1);
      top.tick(1100);
      final ShotParams shot = top.stop()!;
      expect(shot.elevation, closeTo(0.95, 1e-9));
      expect(shot.power, closeTo(1, 1e-9));
    });

    test('stopping with no zone gives nothing, and bad zones are rejected', () {
      final TimingBarStrategy t = TimingBarStrategy();
      expect(t.stop(), isNull);
      t.tick(500);
      expect(t.position, 0);
      expect(() => t.selectZone(3, 0), throwsRangeError);
      expect(() => t.selectZone(0, 2), throwsRangeError);
      t.selectZone(1, 0);
      t.reset();
      expect(t.phase, TimingPhase.aiming);
    });
  });
}
