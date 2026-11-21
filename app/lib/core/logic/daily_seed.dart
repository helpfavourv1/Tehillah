import 'package:tehillah/core/catalog/stage_catalog.dart';
import 'package:tehillah/core/logic/date_key.dart';
import 'package:tehillah/core/logic/seeded_rng.dart';
import 'package:tehillah/core/models/daily_challenge.dart';
import 'package:tehillah/core/models/opponent_def.dart';
import 'package:tehillah/core/models/stage_def.dart';

/// Builds the Daily Bread challenge. It depends only on the calendar day, so
/// every player gets the same opponent, difficulty, wind and seed that day.
abstract final class DailySeed {
  /// The challenge for the calendar day of [date].
  static DailyChallenge forDate(DateTime date) => forKey(DateKey.of(date));

  /// The challenge for a date key such as `2026-11-19`.
  static DailyChallenge forKey(String dateKey) {
    DateKey.parse(dateKey);
    final SeededRng rng = SeededRng(_hash(dateKey)).fork('daily');
    final List<OpponentDef> pool = <OpponentDef>[
      for (final StageDef stage in StageCatalog.stages) ...stage.opponents,
    ];
    final OpponentDef opponent = pool[rng.nextInt(pool.length)];
    final double difficulty = _round2(0.30 + 0.55 * rng.nextDouble());
    final double wind = _round2((rng.nextDouble() - 0.5) * 0.8);
    return DailyChallenge(
      dateKey: dateKey,
      seed: _hash('seed:$dateKey'),
      opponent: opponent,
      difficulty: difficulty,
      wind: wind,
    );
  }

  static double _round2(double v) => (v * 100).round() / 100;

  /// FNV-1a over the text's code units, 32 bits.
  static int _hash(String text) {
    int h = 0x811C9DC5;
    for (final int unit in text.codeUnits) {
      h ^= unit & 0xFF;
      h = ((h & 0xFFFF) * 0x01000193 +
              ((((h >> 16) * 0x01000193) & 0xFFFF) << 16)) &
          0xFFFFFFFF;
    }
    return h;
  }
}
