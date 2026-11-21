import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/logic/daily_seed.dart';
import 'package:tehillah/core/logic/date_key.dart';
import 'package:tehillah/core/models/daily_challenge.dart';

void main() {
  group('DateKey', () {
    test('formats and parses a day', () {
      expect(DateKey.of(DateTime(2026, 1, 5, 23, 59)), '2026-01-05');
      expect(DateKey.parse('2026-11-19'), DateTime.utc(2026, 11, 19));
    });

    test('rejects malformed and impossible dates', () {
      expect(() => DateKey.parse('2026-1-5'), throwsFormatException);
      expect(() => DateKey.parse('2026-02-30'), throwsFormatException);
      expect(() => DateKey.parse('nope'), throwsFormatException);
    });

    test('counts days across month, year and leap boundaries', () {
      expect(DateKey.daysBetween('2026-11-30', '2026-12-01'), 1);
      expect(DateKey.daysBetween('2026-12-31', '2027-01-01'), 1);
      expect(DateKey.daysBetween('2028-02-28', '2028-03-01'), 2);
      expect(DateKey.daysBetween('2026-11-19', '2026-11-18'), -1);
      expect(DateKey.addDays('2026-03-01', -1), '2026-02-28');
      expect(DateKey.addDays('2026-10-24', 3), '2026-10-27');
    });
  });

  group('DailySeed', () {
    test('the same day gives the same challenge', () {
      final DailyChallenge a = DailySeed.forDate(DateTime(2026, 11, 19, 8));
      final DailyChallenge b = DailySeed.forDate(DateTime(2026, 11, 19, 22));
      expect(a.toJson().toString(), b.toJson().toString());
      expect(a.dateKey, '2026-11-19');
    });

    test('different days give different seeds', () {
      final Set<int> seeds = <int>{
        for (int d = 1; d <= 60; d++) DailySeed.forDate(DateTime(2026, 11, 1).add(Duration(days: d))).seed,
      };
      expect(seeds.length, 60);
    });

    test('difficulty and wind stay in range across a year', () {
      for (int d = 0; d < 365; d++) {
        final DailyChallenge c = DailySeed.forDate(DateTime(2026, 1, 1).add(Duration(days: d)));
        expect(c.difficulty, inInclusiveRange(0.30, 0.85));
        expect(c.wind, inInclusiveRange(-0.4, 0.4));
      }
    });

    test('a bad key is rejected', () {
      expect(() => DailySeed.forKey('2026-13-01'), throwsFormatException);
    });
  });
}
