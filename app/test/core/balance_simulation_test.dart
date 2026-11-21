import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/catalog/stage_catalog.dart';
import 'package:tehillah/core/logic/match_engine.dart';
import 'package:tehillah/core/logic/mode_rules.dart';
import 'package:tehillah/core/logic/seeded_rng.dart';
import 'package:tehillah/core/models/loadout.dart';
import 'package:tehillah/core/models/match_config.dart';
import 'package:tehillah/core/models/match_side.dart';
import 'package:tehillah/core/models/shot_params.dart';
import 'package:tehillah/core/models/stage_def.dart';

/// A reference player: aims for a corner, a little off, and uses Selah when
/// the nerve is up. [inputNoise] is the spread of the player's own aim.
ShotParams _botShot(SeededRng rng, double inputNoise) {
  final double side = rng.nextDouble() < 0.5 ? -1 : 1;
  final double magnitude = 0.62 + 0.15 * rng.nextDouble();
  final bool high = rng.nextDouble() < 0.5;
  final double elevation = high ? 0.78 : 0.20;
  double clamp(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);
  return ShotParams(
    direction: clamp(side * magnitude + rng.nextGaussian() * inputNoise, -1, 1),
    elevation: clamp(elevation + rng.nextGaussian() * inputNoise, 0, 1),
    power: clamp(0.78 + rng.nextGaussian() * inputNoise * 0.6, 0, 1),
    curve: 0,
  );
}

bool _botWins(MatchConfig config, bool boss, double inputNoise) {
  final MatchEngine e = MatchEngine(config, isBoss: boss);
  final SeededRng bot = SeededRng(config.seed).fork('bot');
  int guard = 0;
  while (e.prompt != KickPrompt.finished && guard++ < 200) {
    if (e.prompt == KickPrompt.humanShot) {
      if (e.state.nerve > 0.55 && e.canUseSelah) {
        e.useSelah();
      }
      e.kick(shot: _botShot(bot, inputNoise));
    } else {
      e.kick();
    }
  }
  return e.winner == MatchSide.player;
}

List<double> _rates(double inputNoise, int perRound) {
  final List<double> rates = <double>[];
  for (final StageDef stage in StageCatalog.stages) {
    int wins = 0;
    int total = 0;
    for (int round = 1; round <= StageCatalog.roundsPerStage; round++) {
      for (int k = 0; k < perRound; k++) {
        final MatchConfig config = ModeRules.journey(
          stage: stage,
          round: round,
          loadout: Loadout.starter,
          seed: stage.id * 100000 + round * 1000 + k + 1,
        );
        if (_botWins(config, stage.isBoss, inputNoise)) {
          wins++;
        }
        total++;
      }
    }
    rates.add(wins / total);
  }
  return rates;
}

void main() {
  test('win rates fall steadily from the first stage to the last', () {
    final List<double> r = _rates(0.08, 100);
    // Reference player, starter ball, no gear. Bands come from the tuning runs.
    expect(r.first, greaterThanOrEqualTo(0.84), reason: '$r');
    expect(r[5], inInclusiveRange(0.40, 0.72), reason: '$r');
    expect(r.last, inInclusiveRange(0.18, 0.46), reason: '$r');
    for (int i = 1; i < r.length; i++) {
      expect(r[i], lessThanOrEqualTo(r[i - 1] + 0.08), reason: 'stage ${i + 1}: $r');
    }
    expect(r.first - r.last, greaterThan(0.40), reason: '$r');
  });

  test('a sloppy player does worse than a precise one on every late stage', () {
    final List<double> precise = _rates(0.05, 60);
    final List<double> sloppy = _rates(0.25, 60);
    int worse = 0;
    for (int i = 5; i < 12; i++) {
      if (sloppy[i] <= precise[i] + 0.02) {
        worse++;
      }
    }
    expect(worse, greaterThanOrEqualTo(6), reason: '$precise vs $sloppy');
  });

  test('no ball takes the last stage out of reach of the reference player', () {
    final StageDef last = StageCatalog.stages.last;
    for (final String ball in <String>['love', 'joy', 'peace', 'patience', 'kindness',
        'goodness', 'faithfulness', 'gentleness', 'selfControl']) {
      int wins = 0;
      for (int k = 0; k < 200; k++) {
        final MatchConfig config = ModeRules.journey(
          stage: last,
          round: 1 + k % 4,
          loadout: Loadout(ballId: ball),
          seed: 900000 + k,
        );
        if (_botWins(config, true, 0.08)) {
          wins++;
        }
      }
      expect(wins / 200, lessThan(0.62), reason: ball);
    }
  });
}
