import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/logic/match_engine.dart';
import 'package:tehillah/core/logic/progression_rules.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/providers/match_provider.dart';

import '../fakes/fake_storage.dart';
import '../support/match_helpers.dart';

void _playOut(MatchProvider match) {
  int guard = 0;
  while (!match.value.finished && guard++ < 100) {
    switch (match.value.prompt) {
      case KickPrompt.humanShot:
        match.kick(shot: centreShot);
      case KickPrompt.humanDive:
        match.kick(dive: KeeperDive.leftLow);
      case KickPrompt.automatic:
        match.kick();
      case KickPrompt.finished:
        break;
    }
  }
}

void main() {
  late FakeLog log;
  late MatchProvider match;

  setUp(() {
    log = FakeLog();
    match = MatchProvider(log);
  });

  tearDown(() => match.dispose());

  test('before a match nothing is active and a kick is ignored', () {
    expect(match.value.active, isFalse);
    expect(match.kick(shot: centreShot), isNull);
    expect(match.useSelah(), isFalse);
    expect(match.summary, isNull);
    expect(log.lines.any((String l) => l.contains('no match')), isTrue);
  });

  test('starting a match shows a fresh scoreboard and the first prompt', () {
    match.start(configFor());
    expect(match.value.active, isTrue);
    expect(match.value.finished, isFalse);
    expect(match.value.state!.playerScore, 0);
    expect(match.value.history, isEmpty);
    expect(match.value.prompt, anyOf(KickPrompt.humanShot, KickPrompt.automatic));
  });

  test('every kick publishes a new version with the kick that was taken', () {
    match.start(configFor(seed: 3));
    final int before = match.value.version;
    int guard = 0;
    while (match.value.prompt != KickPrompt.humanShot && guard++ < 5) {
      match.kick();
    }
    final int mid = match.value.version;
    expect(mid, greaterThan(before));
    final record = match.kick(shot: centreShot);
    expect(record, isNotNull);
    expect(match.value.lastKick, record);
    expect(match.value.version, greaterThan(mid));
  });

  test('a shot is needed on a human shot and nothing is lost when it is missing', () {
    match.start(configFor(seed: 3));
    int guard = 0;
    while (match.value.prompt != KickPrompt.humanShot && guard++ < 5) {
      match.kick();
    }
    final int kicks = match.value.history.length;
    expect(match.kick(), isNull);
    expect(match.value.history.length, kicks);
  });

  test('a match plays to the end, then gives a summary, a winner and refuses more kicks', () {
    match.start(configFor(seed: 11));
    _playOut(match);
    expect(match.value.finished, isTrue);
    final MatchSummary? summary = match.summary;
    expect(summary, isNotNull);
    expect(summary!.history, isNotEmpty);
    expect(match.winner, anyOf(MatchSide.player, MatchSide.opponent));
    expect(match.kick(shot: centreShot), isNull);
  });

  test('the same seed plays the same match', () {
    match.start(configFor(seed: 21));
    _playOut(match);
    final int a = match.value.state!.playerScore * 100 + match.value.state!.opponentScore;
    match.start(configFor(seed: 21));
    _playOut(match);
    final int b = match.value.state!.playerScore * 100 + match.value.state!.opponentScore;
    expect(b, a);
  });

  test('Watchman asks for a dive on the opponent kicks', () {
    match.start(configFor(mode: MatchMode.watchman, seed: 5));
    int guard = 0;
    while (match.value.prompt != KickPrompt.humanDive && guard++ < 5) {
      match.kick();
    }
    expect(match.value.prompt, KickPrompt.humanDive);
    expect(match.kick(), isNull);
    expect(match.kick(dive: KeeperDive.centerHigh), isNotNull);
  });

  test('Selah can be used on a human shot while charges last', () {
    match.start(configFor(seed: 3));
    int guard = 0;
    while (match.value.prompt != KickPrompt.humanShot && guard++ < 5) {
      match.kick();
    }
    expect(match.value.canUseSelah, isTrue);
    final int charges = match.value.state!.selahCharges;
    expect(match.useSelah(), isTrue);
    expect(match.value.state!.selahCharges, charges - 1);
  });

  test('abandoning clears the match', () {
    match.start(configFor());
    match.abandon();
    expect(match.value.active, isFalse);
    expect(match.summary, isNull);
  });

  test('starting again replaces the match in progress', () {
    match.start(configFor(seed: 1));
    match.kick();
    match.start(configFor(seed: 2));
    expect(match.value.history, isEmpty);
  });
}
