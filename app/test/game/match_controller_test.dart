import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/input/shot_input_strategy.dart';
import 'package:tehillah/core/logic/match_engine.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/shot_params.dart';
import 'package:tehillah/game/match_controller.dart';
import 'package:tehillah/game/match_world.dart';
import 'package:tehillah/providers/match_provider.dart';

import '../fakes/fake_storage.dart';
import '../support/match_helpers.dart';

class StreamInput implements ShotInputStrategy {
  final StreamController<ShotParams> controller = StreamController<ShotParams>.broadcast(sync: true);

  @override
  Stream<ShotParams> get shots => controller.stream;

  @override
  void dispose() {
    unawaited(controller.close());
  }
}

class Rig {
  Rig({MatchConfig? config, Duration auto = const Duration(milliseconds: 100)}) {
    match = MatchProvider(FakeLog());
    world = MatchWorld();
    controller = MatchController(match: match, world: world, autoKickDelay: auto);
    controller.onMatchFinished = () => finished++;
    match.start(config ?? configFor(seed: 3));
  }

  late final MatchProvider match;
  late final MatchWorld world;
  late final MatchController controller;
  int finished = 0;

  /// Plays out the picture of whatever kick is on screen.
  void drainWorld() {
    int guard = 0;
    while (world.isPlaying && guard++ < 2000) {
      world.update(1 / 30);
    }
  }

  void dispose() {
    controller.dispose();
    match.dispose();
  }
}

/// Plays the whole match through the controller the way a player and the
/// clock would.
Future<void> playOut(WidgetTester tester, Rig rig) async {
  for (int i = 0; i < 6000 && rig.finished == 0; i++) {
    if (rig.world.isPlaying) {
      rig.world.update(1 / 30);
    } else if (rig.controller.inputEnabled.value) {
      if (rig.match.value.prompt == KickPrompt.humanShot) {
        rig.controller.submitShot(centreShot);
      } else {
        rig.controller.submitDive(KeeperDive.leftLow);
      }
    } else {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }
}

/// Gets to the point where the computer is about to kick.
Future<void> reachAutomatic(WidgetTester tester, Rig rig) async {
  for (int i = 0; i < 100 && (rig.match.value.prompt != KickPrompt.automatic || rig.world.isPlaying); i++) {
    if (rig.world.isPlaying) {
      rig.drainWorld();
    } else if (rig.controller.inputEnabled.value) {
      rig.controller.submitShot(centreShot);
    } else {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }
  expect(rig.match.value.prompt, KickPrompt.automatic);
}

Future<void> reachHumanShot(WidgetTester tester, Rig rig) async {
  for (int i = 0; i < 100 && (rig.match.value.prompt != KickPrompt.humanShot || rig.world.isPlaying); i++) {
    if (rig.world.isPlaying) {
      rig.drainWorld();
    } else {
      await tester.pump(const Duration(milliseconds: 150));
    }
  }
  expect(rig.match.value.prompt, KickPrompt.humanShot);
  expect(rig.controller.inputEnabled.value, isTrue);
}

void main() {
  testWidgets('a whole friendly match plays through and is reported finished once', (WidgetTester tester) async {
    final Rig rig = Rig();
    addTearDown(rig.dispose);
    rig.controller.attach();
    await playOut(tester, rig);
    expect(rig.finished, 1);
    expect(rig.match.value.finished, isTrue);
    expect(rig.world.isPlaying, isFalse);
    expect(rig.controller.busy.value, isFalse);
    expect(rig.controller.inputEnabled.value, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(rig.finished, 1);
  });

  testWidgets('the result is shown only after the last kick has played', (WidgetTester tester) async {
    final Rig rig = Rig();
    addTearDown(rig.dispose);
    rig.controller.attach();
    for (int i = 0; i < 6000 && !rig.match.value.finished; i++) {
      if (rig.world.isPlaying) {
        rig.world.update(1 / 30);
      } else if (rig.controller.inputEnabled.value) {
        rig.controller.submitShot(centreShot);
      } else {
        await tester.pump(const Duration(milliseconds: 150));
      }
    }
    expect(rig.match.value.finished, isTrue);
    expect(rig.finished, 0);
    expect(rig.world.isPlaying, isTrue);
    expect(rig.controller.busy.value, isTrue);
    rig.drainWorld();
    expect(rig.finished, 1);
  });

  testWidgets('a shot is played on the pitch, closes input, and reopens it afterwards', (WidgetTester tester) async {
    final Rig rig = Rig();
    addTearDown(rig.dispose);
    rig.controller.attach();
    await reachHumanShot(tester, rig);
    final int before = rig.match.value.history.length;
    rig.controller.submitShot(centreShot);
    expect(rig.match.value.history.length, before + 1);
    expect(rig.world.isPlaying, isTrue);
    expect(rig.world.script!.record, rig.match.value.lastKick);
    expect(rig.controller.busy.value, isTrue);
    expect(rig.controller.inputEnabled.value, isFalse);
    rig.controller.submitShot(centreShot);
    expect(rig.match.value.history.length, before + 1);
    rig.drainWorld();
    expect(rig.controller.busy.value, isFalse);
    rig.controller.pause();
  });

  testWidgets('the computer kicks after a beat, not at once', (WidgetTester tester) async {
    final Rig rig = Rig(auto: const Duration(milliseconds: 400));
    addTearDown(rig.dispose);
    rig.controller.attach();
    await reachAutomatic(tester, rig);
    final int before = rig.match.value.history.length;
    await tester.pump(const Duration(milliseconds: 200));
    expect(rig.match.value.history.length, before);
    await tester.pump(const Duration(milliseconds: 250));
    expect(rig.match.value.history.length, before + 1);
    expect(rig.world.isPlaying, isTrue);
  });

  testWidgets('pausing holds the computer kick until resumed', (WidgetTester tester) async {
    final Rig rig = Rig();
    addTearDown(rig.dispose);
    rig.controller.attach();
    await reachAutomatic(tester, rig);
    rig.controller.pause();
    expect(rig.controller.isPaused, isTrue);
    expect(rig.controller.inputEnabled.value, isFalse);
    final int before = rig.match.value.history.length;
    await tester.pump(const Duration(seconds: 3));
    expect(rig.match.value.history.length, before);
    rig.controller.resume();
    await tester.pump(const Duration(milliseconds: 150));
    expect(rig.match.value.history.length, before + 1);
  });

  testWidgets('input is ignored while paused', (WidgetTester tester) async {
    final Rig rig = Rig();
    addTearDown(rig.dispose);
    rig.controller.attach();
    await reachHumanShot(tester, rig);
    rig.controller.pause();
    final int before = rig.match.value.history.length;
    rig.controller.submitShot(centreShot);
    expect(rig.controller.useSelah(), isFalse);
    expect(rig.match.value.history.length, before);
    rig.controller.resume();
    expect(rig.controller.inputEnabled.value, isTrue);
  });

  testWidgets('shots from an input scheme are taken when a shot is wanted', (WidgetTester tester) async {
    final Rig rig = Rig();
    addTearDown(rig.dispose);
    final StreamInput input = StreamInput();
    addTearDown(input.dispose);
    rig.controller.attach(input: input);
    await reachHumanShot(tester, rig);
    final int before = rig.match.value.history.length;
    input.controller.add(centreShot);
    expect(rig.match.value.history.length, before + 1);
  });

  testWidgets('switching the input scheme drops the old one', (WidgetTester tester) async {
    final Rig rig = Rig();
    addTearDown(rig.dispose);
    final StreamInput first = StreamInput();
    final StreamInput second = StreamInput();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    rig.controller.attach(input: first);
    rig.controller.setInput(second);
    expect(rig.controller.input, same(second));
    await reachHumanShot(tester, rig);
    final int before = rig.match.value.history.length;
    first.controller.add(centreShot);
    expect(rig.match.value.history.length, before);
    second.controller.add(centreShot);
    expect(rig.match.value.history.length, before + 1);
  });

  testWidgets('a dive is ignored when a shot is wanted, and a shot when a dive is', (WidgetTester tester) async {
    final Rig rig = Rig();
    addTearDown(rig.dispose);
    rig.controller.attach();
    await reachHumanShot(tester, rig);
    final int before = rig.match.value.history.length;
    rig.controller.submitDive(KeeperDive.leftLow);
    expect(rig.match.value.history.length, before);
  });

  testWidgets('Selah steadies the nerves without replaying the last kick', (WidgetTester tester) async {
    final Rig rig = Rig();
    addTearDown(rig.dispose);
    rig.controller.attach();
    await reachHumanShot(tester, rig);
    expect(rig.match.value.canUseSelah, isTrue);
    final int charges = rig.match.value.state!.selahCharges;
    expect(rig.controller.useSelah(), isTrue);
    expect(rig.match.value.state!.selahCharges, charges - 1);
    expect(rig.world.isPlaying, isFalse);
    expect(rig.controller.busy.value, isFalse);
    expect(rig.controller.inputEnabled.value, isTrue);
  });

  testWidgets('Watchman: the player dives, the opponent is the one kicking', (WidgetTester tester) async {
    final Rig rig = Rig(config: configFor(mode: MatchMode.watchman, seed: 5));
    addTearDown(rig.dispose);
    rig.controller.attach();
    await playOut(tester, rig);
    expect(rig.finished, 1);
    expect(rig.match.value.history.every((k) => k.side == MatchSide.opponent || k.side == MatchSide.player), isTrue);
    expect(rig.match.value.history.any((k) => k.side == MatchSide.opponent), isTrue);
  });

  testWidgets('the shooter waiting at the ball is whoever is next', (WidgetTester tester) async {
    final Rig rig = Rig();
    addTearDown(rig.dispose);
    rig.controller.attach();
    expect(rig.world.idleShooter, rig.match.value.state!.turn);
  });

  testWidgets('abandoning the match clears the pitch and closes input', (WidgetTester tester) async {
    final Rig rig = Rig();
    addTearDown(rig.dispose);
    rig.controller.attach();
    await reachHumanShot(tester, rig);
    rig.controller.submitShot(centreShot);
    expect(rig.world.isPlaying, isTrue);
    rig.match.abandon();
    expect(rig.world.isPlaying, isFalse);
    expect(rig.controller.busy.value, isFalse);
    expect(rig.controller.inputEnabled.value, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(rig.finished, 0);
  });

  testWidgets('a new match after an old one starts clean', (WidgetTester tester) async {
    final Rig rig = Rig();
    addTearDown(rig.dispose);
    rig.controller.attach();
    await playOut(tester, rig);
    expect(rig.finished, 1);
    rig.match.start(configFor(seed: 9));
    expect(rig.controller.busy.value, isFalse);
    await playOut(tester, rig..finished = 0);
    expect(rig.finished, 1);
  });

  testWidgets('detaching stops everything', (WidgetTester tester) async {
    final Rig rig = Rig();
    addTearDown(rig.dispose);
    rig.controller.attach();
    await reachAutomatic(tester, rig);
    rig.controller.detach();
    expect(rig.controller.isAttached, isFalse);
    expect(rig.world.onKickFinished, isNull);
    final int before = rig.match.value.history.length;
    await tester.pump(const Duration(seconds: 3));
    expect(rig.match.value.history.length, before);
    expect(rig.controller.inputEnabled.value, isFalse);
    rig.controller.submitShot(centreShot);
    expect(rig.match.value.history.length, before);
  });

  testWidgets('attaching twice or after dispose is harmless', (WidgetTester tester) async {
    final Rig rig = Rig();
    rig.controller.attach();
    rig.controller.attach();
    rig.controller.dispose();
    rig.controller.dispose();
    rig.controller.attach();
    expect(rig.controller.isAttached, isFalse);
    rig.match.dispose();
  });
}
