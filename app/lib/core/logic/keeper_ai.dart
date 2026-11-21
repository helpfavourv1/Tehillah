import 'package:tehillah/core/logic/seeded_rng.dart';
import 'package:tehillah/core/logic/shot_resolver.dart';
import 'package:tehillah/core/models/keeper_profile.dart';
import 'package:tehillah/core/models/shot_outcome.dart';
import 'package:tehillah/core/models/shot_params.dart';

/// Chooses where a computer-controlled keeper dives.
///
/// With nothing to go on the keeper follows the profile's tendency. Keepers
/// that read habits (later stages) blend in where the player has been aiming,
/// counted on the same six-cell grid as the dives. The result depends only on
/// the profile, the earlier kicks and the generator.
abstract final class KeeperAi {
  /// Earlier kicks needed before the keeper starts to read habits.
  static const int minimumKicksToRead = 2;

  static KeeperDive decide({
    required KeeperProfile profile,
    required List<ShotParams> playerShots,
    required SeededRng rng,
  }) {
    final List<double> weights = diveWeights(profile, playerShots);
    double total = 0;
    for (final double w in weights) {
      total += w;
    }
    final double roll = rng.nextDouble() * total;
    double acc = 0;
    for (int i = 0; i < weights.length; i++) {
      acc += weights[i];
      if (roll < acc) {
        return KeeperDive.values[i];
      }
    }
    return KeeperDive.values.last;
  }

  /// The weight of each dive, in [KeeperDive.values] order.
  static List<double> diveWeights(
    KeeperProfile profile,
    List<ShotParams> playerShots,
  ) {
    final List<double> raw = <double>[
      for (final KeeperDive d in KeeperDive.values) profile.tendency[d] ?? 0,
    ];
    final double sum = raw.fold(0.0, (double a, double b) => a + b);
    final List<double> weights = <double>[
      for (final double w in raw) sum > 0 ? w / sum : 1 / raw.length,
    ];
    final double reading = profile.habitReading;
    if (reading <= 0 || playerShots.length < minimumKicksToRead) {
      return weights;
    }
    final List<double> counts = List<double>.filled(KeeperDive.values.length, 0);
    for (final ShotParams shot in playerShots) {
      counts[GoalGrid.diveFor(shot.direction, shot.elevation).index] += 1;
    }
    final double n = playerShots.length.toDouble();
    return <double>[
      for (int i = 0; i < weights.length; i++)
        (1 - reading) * weights[i] + reading * ((counts[i] + 0.5) / (n + 3)),
    ];
  }

  /// The dive the keeper favours when nothing else is known. The Belt of Truth
  /// shows this to the player.
  static KeeperDive mostLikely(KeeperProfile profile) {
    KeeperDive best = KeeperDive.values.first;
    double bestWeight = -1;
    for (final KeeperDive d in KeeperDive.values) {
      final double w = profile.tendency[d] ?? 0;
      if (w > bestWeight) {
        best = d;
        bestWeight = w;
      }
    }
    return best;
  }
}
