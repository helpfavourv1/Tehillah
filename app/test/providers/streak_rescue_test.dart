import 'package:flutter_test/flutter_test.dart';
import 'package:tehillah/core/models/daily_challenge.dart';
import 'package:tehillah/core/models/progress.dart';
import 'package:tehillah/core/storage/progress_store.dart';
import 'package:tehillah/providers/progress_provider.dart';

import '../fakes/fake_storage.dart';

void main() {
  late ProgressProvider progress;

  setUp(() async {
    final FakeLog log = FakeLog();
    progress = ProgressProvider(ProgressStore(FakeStorage(), log), log);
    await progress.load();
  });

  tearDown(() => progress.dispose());

  test('restoreStreak restores the one missed day and says so', () {
    progress.update((Progress p) => p.copyWith(dailyHistory: <String, DailyRecord>{
          '2026-11-21': const DailyRecord(dateKey: '2026-11-21', won: true, goals: 2),
        }));
    expect(progress.restoreStreak('2026-11-23'), isTrue);
    expect(progress.progress.rescuedDays, <String>{'2026-11-22'});
  });

  test('restoreStreak does nothing when there is nothing to restore', () {
    expect(progress.restoreStreak('2026-11-23'), isFalse);
    expect(progress.progress.rescuedDays, isEmpty);
  });

  test('a second restore in the same week is refused', () {
    progress.update((Progress p) => p.copyWith(dailyHistory: <String, DailyRecord>{
          '2026-11-23': const DailyRecord(dateKey: '2026-11-23', won: true, goals: 2),
        }));
    expect(progress.restoreStreak('2026-11-25'), isTrue);
    progress.update((Progress p) => p.copyWith(dailyHistory: <String, DailyRecord>{
          ...p.dailyHistory,
          '2026-11-25': const DailyRecord(dateKey: '2026-11-25', won: true, goals: 2),
        }));
    expect(progress.restoreStreak('2026-11-27'), isFalse);
  });
}
